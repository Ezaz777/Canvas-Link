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
    const url = new URL(request.url);
    const client = url.searchParams.get('client') || 'mobile';
    // Prefix state with client type (e.g. mobile_... or pc_...)
    const state = `${client}_${crypto.randomUUID()}`;

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
    const state = url.searchParams.get('state') || '';
    const error = url.searchParams.get('error');

    if (error) {
      return new Response(
        renderCallbackPage(false, `Pinterest authorization failed: ${error}`, false),
        { status: 400, headers: { 'Content-Type': 'text/html' } }
      );
    }

    if (!code) {
      return new Response(
        renderCallbackPage(false, 'Missing authorization code.', false),
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

      const isMobile = state.startsWith('mobile_');

      if (isMobile) {
        // Return 200 HTML page with instant clipboard copy, auto-redirect script, and direct tap button
        // Returning 302 is blocked by Android Chrome Custom Tabs for custom schemes.
        return new Response(
          renderCallbackPage(true, jwt, true),
          {
            status: 200,
            headers: {
              'Content-Type': 'text/html',
            }
          }
        );
      }

      // Return a pretty HTML page that passes the token to the opener (PC/web client)
      return new Response(
        renderCallbackPage(true, jwt, false),
        { status: 200, headers: { 'Content-Type': 'text/html' } }
      );
    } catch (err: any) {
      console.error('Auth callback error:', err);
      return new Response(
        renderCallbackPage(false, `Authentication failed: ${err.message}`, false),
        { status: 500, headers: { 'Content-Type': 'text/html' } }
      );
    }
  });
}

/**
 * Renders a styled HTML callback page.
 * On success, displays the JWT token and attempts to communicate it to the opener window.
 */
function renderCallbackPage(success: boolean, data: string, isMobile = false): string {
  const deepLink = `canvaslink://auth?token=${encodeURIComponent(data)}`;
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  ${success && isMobile ? `<meta http-equiv="refresh" content="0;url=${deepLink}">` : ''}
  <title>Canvas Link — ${success ? 'Connected' : 'Error'}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #0f172a, #1e1b4b, #0f172a);
      color: #fff;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: rgba(30, 41, 59, 0.7);
      backdrop-filter: blur(24px);
      border-radius: 24px;
      padding: 36px 28px;
      max-width: 440px;
      width: 100%;
      text-align: center;
      border: 1px solid rgba(255,255,255,0.12);
      box-shadow: 0 25px 50px rgba(0,0,0,0.5);
    }
    .icon { font-size: 52px; margin-bottom: 16px; }
    h1 { font-size: 22px; font-weight: 700; margin-bottom: 10px; }
    p { color: #94a3b8; line-height: 1.6; font-size: 14px; margin-bottom: 24px; }
    .btn {
      display: block;
      width: 100%;
      text-decoration: none;
      padding: 16px 24px;
      background: linear-gradient(135deg, #8b5cf6, #3b82f6);
      border: none;
      border-radius: 14px;
      color: #fff;
      font-size: 16px;
      font-weight: 700;
      cursor: pointer;
      margin-bottom: 12px;
      box-shadow: 0 10px 25px rgba(139, 92, 246, 0.35);
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .btn:active { transform: scale(0.98); }
    .btn-secondary {
      background: rgba(255,255,255,0.06);
      border: 1px solid rgba(255,255,255,0.15);
      color: #cbd5e1;
      font-size: 14px;
      padding: 12px 20px;
      box-shadow: none;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${success ? '✨' : '❌'}</div>
    <h1>${success ? 'Connected Successfully!' : 'Authentication Failed'}</h1>
    ${
      success
        ? (isMobile
            ? `<p>Returning to Canvas Link app...</p>
               <a href="${deepLink}" id="openBtn" class="btn">🚀 Open Canvas Link App</a>
               <p style="font-size: 12px; color: #64748b; margin-top: 14px;">Tap the button above if the app does not open automatically.</p>`
            : `<p>Your Pinterest account is now connected.</p>
               <button class="btn btn-secondary" onclick="navigator.clipboard.writeText('${data}');alert('Token copied!');">Copy Token Manually</button>`)
        : `<p>${data}</p>`
    }
  </div>
  <script>
    ${
      success
        ? `
    // Auto-copy token to clipboard so app detects it immediately on resume
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText('${data}').catch(function(){});
      }
    } catch(e) {}

    // Auto-return for mobile client
    try {
      window.location.replace("${deepLink}");
    } catch(e) {}
    setTimeout(function() {
      try { window.location.href = "${deepLink}"; } catch(e) {}
    }, 200);

    // Pass token to PC client local server or popup opener
    try {
      if (window.opener) {
        window.opener.postMessage({ type: 'wallpaper_sync_token', token: '${data}' }, '*');
      }
      fetch('http://127.0.0.1:9437/callback?token=${data}', { mode: 'no-cors' }).catch(() => {});
      fetch('http://localhost:9437/callback?token=${data}', { mode: 'no-cors' }).catch(() => {});
    } catch(e) {}
    `
        : ''
    }
  </script>
</body>
</html>`;
}
