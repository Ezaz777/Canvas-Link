/**
 * Razorpay Checkout route.
 *
 * POST /api/checkout — Creates a Razorpay Subscription and returns the hosted checkout URL.
 */

import { IRequest } from 'itty-router';
import { extractBearerToken, verifyToken } from '../middleware/auth';
import { createSubscription } from '../services/razorpay';
import { Env } from '../index';

export function registerCheckoutRoutes(router: any) {
  /**
   * POST /api/checkout
   * Requires a valid JWT. Creates a Razorpay Subscription and returns the payment URL.
   */
  router.post('/api/checkout', async (request: IRequest, env: Env) => {
    // Authenticate
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

    // Fetch user to check if already subscribed
    const user = await env.DB.prepare(
      'SELECT subscription_status FROM users WHERE id = ?'
    ).bind(userId).first<{ subscription_status: string }>();

    if (!user) {
      return Response.json({ error: 'User not found' }, { status: 404 });
    }

    if (user.subscription_status === 'active') {
      return Response.json({ error: 'Already subscribed', status: 'active' }, { status: 400 });
    }

    try {
      const subscription = await createSubscription(
        env.RAZORPAY_KEY_ID,
        env.RAZORPAY_KEY_SECRET,
        env.RAZORPAY_PLAN_ID,
        userId
      );

      return Response.json({
        checkout_url: subscription.short_url,
        subscription_id: subscription.id,
      });
    } catch (err: any) {
      console.error('Razorpay subscription creation failed:', err);
      return Response.json(
        { error: 'Failed to create checkout session' },
        { status: 500 }
      );
    }
  });
}
