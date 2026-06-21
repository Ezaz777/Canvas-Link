/**
 * Pinterest OAuth2 routes.
 *
 * GET /auth/pinterest  — Redirects user to Pinterest OAuth consent screen
 * GET /auth/callback   — Handles Pinterest callback, exchanges code for tokens,
 *                         upserts user in D1, returns JWT
 */

import { IRequest } from 'itty-router';
import { buildAuthorizationUrl, exchangeCodeForToken, getUserProfile } from '../services/pinterest';
import { encrypt } from '../utils/crypto';
import { createToken } from '../middleware/auth';
import { Env } from '../index';

export function registerAuthRoutes(router: any) {
  /**
   * GET /auth/pinterest
   * Initiates Pinterest OAuth2 flow by redirecting to Pinterest's consent screen.
   */
  router.get('/auth/pinterest', async (request: IRequest, env: Env) => {
    // Generate a random state parameter for CSRF protection
    const state = crypto.randomUUID();

    const authUrl = buildAuthorizationUrl(
      env.PINTEREST_APP_ID,
      env.PINTEREST_REDIRECT_URI,
      state
    );

    return Response.redirect(authUrl, 302);
  });

  /**
   * GET /auth/callback
   * Pinterest redirects here after user consent.
   * Exchanges the authorization code for tokens, stores user, returns JWT.
   */
  router.get('/auth/callback', async (request: IRequest, env: Env) => {
    const url = new URL(request.url);
    const code = url.searchParams.get('code');
    const error = url.searchParams.get('error');

    if (error) {
      return new Response(
        renderCallbackPage(false, `Pinterest authorization failed: ${error}`),
        { status: 400, headers: { 'Content-Type': 'text/html' } }
      );
    }

    if (!code) {
      return new Response(
        renderCallbackPage(false, 'Missing authorization code.'),
        { status: 400, headers: { 'Content-Type': 'text/html' } }
      );
    }

    try {
      // Exchange code for tokens
      const tokenData = await exchangeCodeForToken(
        code,
        env.PINTEREST_REDIRECT_URI,
        env.PINTEREST_APP_ID,
        env.PINTEREST_APP_SECRET
      );

      // Get user profile
      const profile = await getUserProfile(tokenData.access_token);

      // Encrypt the refresh token for storage
      const encryptedRefreshToken = await encrypt(tokenData.refresh_token, env.ENCRYPTION_KEY);

      // Generate internal user ID
      const userId = crypto.randomUUID();

      // Upsert user in D1
      await env.DB.prepare(`
        INSERT INTO users (id, pinterest_user_id, pinterest_username, encrypted_refresh_token, updated_at)
        VALUES (?, ?, ?, ?, datetime('now'))
        ON CONFLICT(pinterest_user_id) DO UPDATE SET
          encrypted_refresh_token = excluded.encrypted_refresh_token,
          pinterest_username = excluded.pinterest_username,
          updated_at = datetime('now')
      `).bind(userId, profile.id, profile.username, encryptedRefreshToken).run();

      // Fetch the actual user ID (may differ on conflict/update)
      const user = await env.DB.prepare(
        'SELECT id FROM users WHERE pinterest_user_id = ?'
      ).bind(profile.id).first<{ id: string }>();

      const actualUserId = user?.id || userId;

      // Create JWT
      const jwt = await createToken(actualUserId, env.JWT_SECRET);

      // Return a pretty HTML page that passes the token to the opener (PC/mobile client)
      return new Response(
        renderCallbackPage(true, jwt),
        { status: 200, headers: { 'Content-Type': 'text/html' } }
      );
    } catch (err: any) {
      console.error('Auth callback error:', err);
      return new Response(
        renderCallbackPage(false, `Authentication failed: ${err.message}`),
        { status: 500, headers: { 'Content-Type': 'text/html' } }
      );
    }
  });
}

/**
 * Renders a styled HTML callback page.
 * On success, displays the JWT token and attempts to communicate it to the opener window.
 */
function renderCallbackPage(success: boolean, data: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>WallpaperSync — ${success ? 'Success' : 'Error'}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
      color: #fff;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .card {
      background: rgba(255,255,255,0.08);
      backdrop-filter: blur(20px);
      border-radius: 20px;
      padding: 40px;
      max-width: 480px;
      text-align: center;
      border: 1px solid rgba(255,255,255,0.15);
      box-shadow: 0 25px 50px rgba(0,0,0,0.4);
    }
    .icon { font-size: 48px; margin-bottom: 16px; }
    h1 { font-size: 24px; margin-bottom: 12px; }
    p { color: rgba(255,255,255,0.7); line-height: 1.6; margin-bottom: 20px; }
    .token-box {
      background: rgba(0,0,0,0.3);
      border-radius: 12px;
      padding: 16px;
      word-break: break-all;
      font-family: monospace;
      font-size: 12px;
      color: #a78bfa;
      margin-bottom: 16px;
      max-height: 120px;
      overflow-y: auto;
    }
    .btn {
      display: inline-block;
      padding: 12px 32px;
      background: linear-gradient(135deg, #7c3aed, #a78bfa);
      border: none;
      border-radius: 12px;
      color: #fff;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      transition: transform 0.2s;
    }
    .btn:hover { transform: scale(1.05); }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${success ? '✅' : '❌'}</div>
    <h1>${success ? 'Authentication Successful!' : 'Authentication Failed'}</h1>
    ${
      success
        ? `<p>Your account is connected. Copy the token below and paste it into your WallpaperSync app.</p>
           <div class="token-box" id="token">${data}</div>
           <button class="btn" onclick="navigator.clipboard.writeText(document.getElementById('token').textContent)">Copy Token</button>`
        : `<p>${data}</p>`
    }
  </div>
  <script>
    ${
      success
        ? `
    // Attempt to pass the token to the PC client's local callback server
    try {
      if (window.opener) {
        window.opener.postMessage({ type: 'wallpaper_sync_token', token: '${data}' }, '*');
      }
      // Also try redirecting to local client callback
      const localCallback = 'http://localhost:9437/callback?token=${data}';
      fetch(localCallback, { mode: 'no-cors' }).catch(() => {});
    } catch(e) {}
    `
        : ''
    }
  </script>
</body>
</html>`;
}
