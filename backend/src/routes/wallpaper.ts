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
import { refreshAccessToken, getBoardPins } from '../services/pinterest';
import { Env } from '../index';

interface UserRow {
  id: string;
  encrypted_refresh_token: string;
  board_id: string | null;
  subscription_status: string;
}

export function registerWallpaperRoutes(router: any) {
  /**
   * GET /api/get-wallpaper
   * Returns the daily wallpaper URL. Same URL for same user on same day across all devices.
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

    // 2. Fetch user and validate subscription
    const user = await env.DB.prepare(
      'SELECT id, encrypted_refresh_token, board_id, subscription_status FROM users WHERE id = ?'
    ).bind(userId).first<UserRow>();

    if (!user) {
      return Response.json({ error: 'User not found' }, { status: 404 });
    }

    if (user.subscription_status !== 'active') {
      return Response.json(
        {
          error: 'Premium subscription required',
          message: 'Your subscription is not active. Please subscribe to access daily wallpapers.',
          subscription_status: user.subscription_status,
        },
        { status: 402 }
      );
    }

    if (!user.board_id) {
      return Response.json(
        {
          error: 'No board selected',
          message: 'Please configure a Pinterest board to sync wallpapers from.',
        },
        { status: 400 }
      );
    }

    try {
      // 3. Decrypt refresh token and get a fresh access token
      const refreshToken = await decrypt(user.encrypted_refresh_token, env.ENCRYPTION_KEY);

      const tokenData = await refreshAccessToken(
        refreshToken,
        env.PINTEREST_APP_ID,
        env.PINTEREST_APP_SECRET
      );

      // Store the new refresh token (continuous refresh)
      if (tokenData.refresh_token && tokenData.refresh_token !== refreshToken) {
        const newEncryptedToken = await encrypt(tokenData.refresh_token, env.ENCRYPTION_KEY);
        await env.DB.prepare(
          'UPDATE users SET encrypted_refresh_token = ?, updated_at = datetime(\'now\') WHERE id = ?'
        ).bind(newEncryptedToken, userId).run();
      }

      // 4. Fetch all image pins from the user's board
      const pins = await getBoardPins(tokenData.access_token, user.board_id);

      if (pins.length === 0) {
        return Response.json(
          {
            error: 'No image pins found',
            message: 'Your selected Pinterest board has no image pins.',
          },
          { status: 404 }
        );
      }

      // 5. Deterministic selection: same date + same user = same wallpaper
      const today = getTodayDateString();
      const selectedIndex = getSeededIndex(today, userId, pins.length);
      const selectedPin = pins[selectedIndex];

      // 6. Extract the best resolution URL
      const images = selectedPin.media?.images || {};
      const originalUrl = (images.orig || images['1200x'] || images['600x'])?.url;

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

    const body = await (request as unknown as Request).json() as { board_id?: string };
    if (!body.board_id) {
      return Response.json({ error: 'board_id is required' }, { status: 400 });
    }

    await env.DB.prepare(
      'UPDATE users SET board_id = ?, updated_at = datetime(\'now\') WHERE id = ?'
    ).bind(body.board_id, userId).run();

    return Response.json({ success: true, board_id: body.board_id });
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
      'SELECT encrypted_refresh_token FROM users WHERE id = ?'
    ).bind(userId).first<{ encrypted_refresh_token: string }>();

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
      return Response.json(data);
    } catch (err: any) {
      console.error('Failed to get boards:', err);
      return Response.json({ error: 'Failed to fetch boards', details: err.message }, { status: 500 });
    }
  });

  router.get('/api/debug-pins', async (request: IRequest, env: Env) => {
    const token = extractBearerToken(request as unknown as Request);
    const auth = await verifyToken(token!, env.JWT_SECRET);
    const user = await env.DB.prepare('SELECT encrypted_refresh_token, board_id FROM users WHERE id = ?').bind(auth.userId).first<UserRow>();
    const refreshToken = await decrypt(user!.encrypted_refresh_token, env.ENCRYPTION_KEY);
    const tokenData = await refreshAccessToken(refreshToken, env.PINTEREST_APP_ID, env.PINTEREST_APP_SECRET);
    const response = await fetch(`https://api.pinterest.com/v5/boards/${user!.board_id}/pins`, { headers: { Authorization: `Bearer ${tokenData.access_token}` } });
    return Response.json(await response.json());
  });
}
