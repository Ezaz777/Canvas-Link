/**
 * Wallpaper Engine route.
 *
 * GET /api/get-wallpaper — The core endpoint. Validates subscription,
 *     fetches board pins, selects one deterministically based on date + userId,
 *     and returns the original-resolution image URL.
 */

import { IRequest } from 'itty-router';
import { extractBearerToken, verifyToken } from '../middleware/auth';
import { decrypt, encrypt } from '../utils/crypto';
import { getSeededIndex, getTodayDateString } from '../utils/sync';
import { refreshAccessToken, getBoardPins, deletePin } from '../services/pinterest';
import { Env } from '../index';

interface UserRow {
  id: string;
  encrypted_refresh_token: string;
  board_id: string | null;
  mobile_board_id: string | null;
  desktop_board_id: string | null;
  subscription_status: string;
  skip_offset: number;
}

interface TokenCacheEntry {
  accessToken: string;
  expiresAt: number;
}

interface PinsCacheEntry {
  pins: any[];
  expiresAt: number;
}

// In-memory cache across Cloudflare Worker warm invocations
const tokenCache = new Map<string, TokenCacheEntry>();
const pinsCache = new Map<string, PinsCacheEntry>();

async function getValidAccessToken(
  userId: string,
  encryptedRefreshToken: string,
  env: Env,
  forceRefresh: boolean = false
): Promise<string> {
  const now = Date.now();
  const cached = tokenCache.get(userId);
  if (!forceRefresh && cached && cached.expiresAt > now) {
    return cached.accessToken;
  }

  const refreshToken = await decrypt(encryptedRefreshToken, env.ENCRYPTION_KEY);
  const tokenData = await refreshAccessToken(
    refreshToken,
    env.PINTEREST_APP_ID,
    env.PINTEREST_APP_SECRET
  );

  tokenCache.set(userId, {
    accessToken: tokenData.access_token,
    expiresAt: now + 50 * 60 * 1000, // Cache for 50 minutes (valid for 30 days)
  });

  if (tokenData.refresh_token && tokenData.refresh_token !== refreshToken) {
    const newEncryptedToken = await encrypt(tokenData.refresh_token, env.ENCRYPTION_KEY);
    await env.DB.prepare(
      'UPDATE users SET encrypted_refresh_token = ?, updated_at = datetime(\'now\') WHERE id = ?'
    ).bind(newEncryptedToken, userId).run();
  }

  return tokenData.access_token;
}

async function getCachedBoardPins(
  userId: string,
  encryptedRefreshToken: string,
  boardId: string,
  env: Env
): Promise<any[]> {
  const now = Date.now();
  const cached = pinsCache.get(boardId);
  if (cached && cached.expiresAt > now && cached.pins.length > 0) {
    return cached.pins;
  }

  let accessToken = await getValidAccessToken(userId, encryptedRefreshToken, env);
  try {
    const pins = await getBoardPins(accessToken, boardId);
    pinsCache.set(boardId, {
      pins,
      expiresAt: now + 5 * 60 * 1000, // Cache board pins for 5 minutes
    });
    return pins;
  } catch (err: any) {
    // If Pinterest token expired or returned 401, refresh once
    accessToken = await getValidAccessToken(userId, encryptedRefreshToken, env, true);
    const pins = await getBoardPins(accessToken, boardId);
    pinsCache.set(boardId, {
      pins,
      expiresAt: Date.now() + 5 * 60 * 1000,
    });
    return pins;
  }
}

export function registerWallpaperRoutes(router: any) {
  /**
   * GET /api/get-wallpaper
   * Returns the wallpaper URL. Supports frequency (1, 6, 12, 24 hours) and local hour cycling.
   */
  router.get('/api/get-wallpaper', async (request: IRequest, env: Env) => {
    // 1. Authenticate
    const token = extractBearerToken(request as unknown as Request);
    if (!token) {
      return Response.json(
        { error: 'Missing authorization token' },
        { status: 401 }
      );
    }

    let userId: string;
    try {
      const auth = await verifyToken(token, env.JWT_SECRET);
      userId = auth.userId;
    } catch {
      return Response.json(
        { error: 'Invalid or expired token' },
        { status: 401 }
      );
    }

    // 2. Fetch user
    const user = await env.DB.prepare(
      'SELECT id, encrypted_refresh_token, board_id, mobile_board_id, desktop_board_id, subscription_status, skip_offset FROM users WHERE id = ?'
    ).bind(userId).first<UserRow>();

    if (!user) {
      return Response.json({ error: 'User not found' }, { status: 404 });
    }

    const url = new URL(request.url);
    const deviceType = url.searchParams.get('device_type');
    const frequencyParam = parseInt(url.searchParams.get('frequency') || '24', 10);
    const hourParam = parseInt(url.searchParams.get('hour') || '-1', 10);
    const currentHour = (hourParam >= 0 && hourParam <= 23) ? hourParam : new Date().getUTCHours();

    let targetBoardId: string | null = null;
    if (deviceType === 'mobile') {
      targetBoardId = user.mobile_board_id || (user.desktop_board_id ? null : user.board_id);
    } else if (deviceType === 'desktop') {
      targetBoardId = user.desktop_board_id || (user.mobile_board_id ? null : user.board_id);
    } else {
      targetBoardId = user.board_id || user.mobile_board_id || user.desktop_board_id;
    }

    if (!targetBoardId) {
      return Response.json(
        {
          error: 'No board selected',
          code: 'no_board_selected',
          message: deviceType === 'desktop'
            ? 'No Pinterest board is selected for PC. Please select a board in the Canvas Link settings.'
            : 'No Pinterest board is selected for Mobile. Please open Your Boards in the app to pick a board.',
        },
        { status: 400 }
      );
    }

    try {
      // 3. Fetch board pins with in-memory caching and token reuse (blazing fast, no rate-limits)
      const pins = await getCachedBoardPins(userId, user.encrypted_refresh_token, targetBoardId, env);

      if (pins.length === 0) {
        return Response.json(
          {
            error: 'No image pins found',
            code: 'no_pins_found',
            message: 'Your selected Pinterest board has no saved wallpapers or images. Please open Pinterest and save some image pins to this board!',
          },
          { status: 404 }
        );
      }

      // 4. Deterministic selection: date + userId + interval = consistent wallpaper for the active interval
      const today = getTodayDateString();
      const selectedIndex = getSeededIndex(
        today,
        userId,
        pins.length,
        user.skip_offset || 0,
        frequencyParam,
        currentHour
      );
      const selectedPin = pins[selectedIndex];

      // 6. Extract the best resolution URL (prioritize fast CDN-optimized 1200x, then orig)
      const images = selectedPin.media?.images || {};
      const originalUrl = (
        images['1200x']?.url ||
        images.orig?.url ||
        images['736x']?.url ||
        images['600x']?.url ||
        images['400x300']?.url ||
        (Object.values(images)[0] as any)?.url
      );

      if (!originalUrl) {
        return Response.json(
          { error: 'Selected pin has no original image URL' },
          { status: 500 }
        );
      }

      return Response.json({
        image_url: originalUrl,
        pin_id: selectedPin.id,
        title: selectedPin.title || null,
        date: today,
        total_pins: pins.length,
        selected_index: selectedIndex,
      });
    } catch (err: any) {
      console.error('Wallpaper engine error:', err);
      return Response.json(
        { error: 'Failed to fetch wallpaper', details: err.message },
        { status: 500 }
      );
    }
  });

  /**
   * POST /api/set-board
   * Allows the user to set which Pinterest board to sync wallpapers from.
   */
  router.post('/api/set-board', async (request: IRequest, env: Env) => {
    const token = extractBearerToken(request as unknown as Request);
    if (!token) {
      return Response.json({ error: 'Missing authorization token' }, { status: 401 });
    }

    let userId: string;
    try {
      const auth = await verifyToken(token, env.JWT_SECRET);
      userId = auth.userId;
    } catch {
      return Response.json({ error: 'Invalid or expired token' }, { status: 401 });
    }

    const body = await (request as unknown as Request).json() as { board_id?: string | null, device_type?: string };
    const boardId = (body.board_id && body.board_id.trim() !== '' && body.board_id !== 'null') ? body.board_id.trim() : null;
    const deviceType = body.device_type || 'all';

    if (deviceType === 'mobile') {
      await env.DB.prepare(
        `UPDATE users SET 
          mobile_board_id = ?, 
          board_id = NULL,
          updated_at = datetime('now') 
         WHERE id = ?`
      ).bind(boardId, userId).run();
    } else if (deviceType === 'desktop') {
      await env.DB.prepare(
        `UPDATE users SET 
          desktop_board_id = ?, 
          board_id = NULL,
          updated_at = datetime('now') 
         WHERE id = ?`
      ).bind(boardId, userId).run();
    } else {
      await env.DB.prepare(
        `UPDATE users SET 
          board_id = NULL, 
          mobile_board_id = ?, 
          desktop_board_id = ?, 
          updated_at = datetime('now') 
         WHERE id = ?`
      ).bind(boardId, boardId, userId).run();
    }

    pinsCache.clear();
    return Response.json({ success: true, board_id: boardId, device_type: deviceType });
  });

  /**
   * POST /api/skip-wallpaper
   * Increments the user's skip_offset by 1 to manually cycle to the next wallpaper.
   */
  router.post('/api/skip-wallpaper', async (request: IRequest, env: Env) => {
    const token = extractBearerToken(request as unknown as Request);
    if (!token) {
      return Response.json({ error: 'Missing authorization token' }, { status: 401 });
    }

    let userId: string;
    try {
      const auth = await verifyToken(token, env.JWT_SECRET);
      userId = auth.userId;
    } catch {
      return Response.json({ error: 'Invalid or expired token' }, { status: 401 });
    }

    try {
      await env.DB.prepare(
        'UPDATE users SET skip_offset = skip_offset + 1, updated_at = datetime(\'now\') WHERE id = ?'
      ).bind(userId).run();

      return Response.json({ success: true, message: 'Wallpaper skipped' });
    } catch (err: any) {
      console.error('Failed to skip wallpaper:', err);
      return Response.json({ error: 'Failed to skip wallpaper', details: err.message }, { status: 500 });
    }
  });

  /**
   * GET /api/boards
   * Returns a list of the user's Pinterest boards.
   */
  router.get('/api/boards', async (request: IRequest, env: Env) => {
    const token = extractBearerToken(request as unknown as Request);
    if (!token) {
      return Response.json({ error: 'Missing authorization token' }, { status: 401 });
    }

    let userId: string;
    try {
      const auth = await verifyToken(token, env.JWT_SECRET);
      userId = auth.userId;
    } catch {
      return Response.json({ error: 'Invalid or expired token' }, { status: 401 });
    }

    const user = await env.DB.prepare(
      'SELECT encrypted_refresh_token, board_id, mobile_board_id, desktop_board_id FROM users WHERE id = ?'
    ).bind(userId).first<{ encrypted_refresh_token: string, board_id: string, mobile_board_id: string, desktop_board_id: string }>();

    if (!user) {
      return Response.json({ error: 'User not found' }, { status: 404 });
    }

    try {
      const refreshToken = await decrypt(user.encrypted_refresh_token, env.ENCRYPTION_KEY);
      const tokenData = await refreshAccessToken(refreshToken, env.PINTEREST_APP_ID, env.PINTEREST_APP_SECRET);

      const response = await fetch('https://api.pinterest.com/v5/boards', {
        headers: { Authorization: `Bearer ${tokenData.access_token}` },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch boards: ${await response.text()}`);
      }

      const data = await response.json();
      
      // Inject user's selected boards into the response cleanly
      data.selected_boards = {
        mobile: user.mobile_board_id || null,
        desktop: user.desktop_board_id || null,
        fallback: (user.mobile_board_id == null && user.desktop_board_id == null) ? user.board_id : null
      };
      
      return Response.json(data);
    } catch (err: any) {
      console.error('Failed to get boards:', err);
      return Response.json({ error: 'Failed to fetch boards', details: err.message }, { status: 500 });
    }
  });

  /**
   * GET /api/board-pins
   * Returns all image pins from the user's selected board.
   */
  router.get('/api/board-pins', async (request: IRequest, env: Env) => {
    const token = extractBearerToken(request as unknown as Request);
    if (!token) {
      return Response.json({ error: 'Missing authorization token' }, { status: 401 });
    }

    let userId: string;
    try {
      const auth = await verifyToken(token, env.JWT_SECRET);
      userId = auth.userId;
    } catch {
      return Response.json({ error: 'Invalid or expired token' }, { status: 401 });
    }

    const user = await env.DB.prepare(
      'SELECT encrypted_refresh_token, board_id, mobile_board_id, desktop_board_id FROM users WHERE id = ?'
    ).bind(userId).first<UserRow>();

    if (!user) {
      return Response.json({ error: 'User not found' }, { status: 404 });
    }

    const deviceType = new URL(request.url).searchParams.get('device_type');
    let targetBoardId: string | null = null;
    if (deviceType === 'mobile') {
      targetBoardId = user.mobile_board_id || (user.desktop_board_id ? null : user.board_id);
    } else if (deviceType === 'desktop') {
      targetBoardId = user.desktop_board_id || (user.mobile_board_id ? null : user.board_id);
    } else {
      targetBoardId = user.board_id || user.mobile_board_id || user.desktop_board_id;
    }

    if (!targetBoardId) {
      return Response.json(
        {
          error: 'No board selected',
          code: 'no_board_selected',
          message: 'No Pinterest board is selected. Please pick a board in your dashboard.',
        },
        { status: 400 }
      );
    }

    try {
      const pins = await getCachedBoardPins(userId, user.encrypted_refresh_token, targetBoardId, env);

      // Map pins to simpler format and extract highest available resolution safely
      const formattedPins = pins.map(pin => {
        const images = pin.media?.images || {};
        const primaryUrl = (
          images['1200x']?.url ||
          images['736x']?.url ||
          images.orig?.url ||
          images['600x']?.url ||
          images['400x300']?.url ||
          (Object.values(images)[0] as any)?.url
        );
        const fallbackUrl = images['600x']?.url || images['400x300']?.url || primaryUrl;
        return {
          id: pin.id,
          title: pin.title,
          image_url: primaryUrl,
          fallback_url: fallbackUrl,
        };
      }).filter(pin => pin.image_url);

      return Response.json({ pins: formattedPins });
    } catch (err: any) {
      console.error('Failed to get board pins:', err);
      return Response.json({ error: 'Failed to fetch board pins', details: err.message }, { status: 500 });
    }
  });

  /**
   * DELETE /api/delete-pin/:pin_id
   * Deletes a pin from the user's Pinterest board.
   */
  router.delete('/api/delete-pin/:pin_id', async (request: IRequest, env: Env) => {
    const token = extractBearerToken(request as unknown as Request);
    if (!token) {
      return Response.json({ error: 'Missing authorization token' }, { status: 401 });
    }

    const pinId = request.params.pin_id;
    if (!pinId) {
      return Response.json({ error: 'Missing pin_id' }, { status: 400 });
    }

    let userId: string;
    try {
      const auth = await verifyToken(token, env.JWT_SECRET);
      userId = auth.userId;
    } catch {
      return Response.json({ error: 'Invalid or expired token' }, { status: 401 });
    }

    const user = await env.DB.prepare(
      'SELECT encrypted_refresh_token FROM users WHERE id = ?'
    ).bind(userId).first<UserRow>();

    if (!user) {
      return Response.json({ error: 'User not found' }, { status: 404 });
    }

    try {
      const refreshToken = await decrypt(user.encrypted_refresh_token, env.ENCRYPTION_KEY);
      const tokenData = await refreshAccessToken(refreshToken, env.PINTEREST_APP_ID, env.PINTEREST_APP_SECRET);

      await deletePin(tokenData.access_token, pinId);
      pinsCache.clear();

      return Response.json({ success: true, message: 'Pin deleted successfully' });
    } catch (err: any) {
      console.error('Failed to delete pin:', err);
      // If the error is related to scope, we should tell the client
      if (err.message.includes('403') || err.message.includes('scope')) {
        return Response.json(
          { error: 'Permission denied', details: 'You need to re-authenticate to grant the app permission to delete pins.' },
          { status: 403 }
        );
      }
      return Response.json({ error: 'Failed to delete pin', details: err.message }, { status: 500 });
    }
  });
}
