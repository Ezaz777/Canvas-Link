/**
 * Main entry point — Cloudflare Workers router.
 * Registers all routes and handles CORS.
 */

import { AutoRouter, cors, error, IRequest } from 'itty-router';
import { registerAuthRoutes } from './routes/auth';
import { registerWallpaperRoutes } from './routes/wallpaper';

/**
 * Environment bindings type definition.
 */
export interface Env {
  // D1 Database
  DB: D1Database;

  // Pinterest OAuth
  PINTEREST_APP_ID: string;
  PINTEREST_APP_SECRET: string;
  PINTEREST_REDIRECT_URI: string;

  // Google Play
  GOOGLE_PLAY_PACKAGE_NAME: string;
  GOOGLE_PLAY_SERVICE_ACCOUNT_JSON?: string;

  // App
  JWT_SECRET: string;
  ENCRYPTION_KEY: string;
  FRONTEND_URL: string;
}

// Set up CORS
const { preflight, corsify } = cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
});

// Create router with AutoRouter for simplified typing
const router = AutoRouter({
  before: [preflight],
  finally: [corsify],
});

// Register route modules
registerAuthRoutes(router);
registerWallpaperRoutes(router);

// Health check
router.get('/', () => {
  return Response.json({
    name: 'WallpaperSync API',
    version: '1.0.0',
    status: 'operational',
    endpoints: {
      auth: 'GET /auth/pinterest',
      callback: 'GET /auth/callback',
      wallpaper: 'GET /api/get-wallpaper',
      setBoard: 'POST /api/set-board',
      verifyPurchase: 'POST /api/verify-purchase',
    },
  });
});

// 404 fallback
router.all('*', () => {
  return Response.json({ error: 'Not found' }, { status: 404 });
});

// Export the Worker
export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    return router
      .fetch(request, env, ctx)
      .catch((err: any) => {
        console.error('Unhandled error:', err);
        return Response.json(
          { error: 'Internal server error' },
          { status: 500 }
        );
      });
  },
};
