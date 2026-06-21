/**
 * Razorpay Webhook handler.
 *
 * POST /webhook/razorpay — Receives Razorpay events, verifies HMAC signature,
 *                           updates user subscription status in D1.
 */

import { IRequest } from 'itty-router';
import { verifyWebhookSignature } from '../services/razorpay';
import { Env } from '../index';

export function registerWebhookRoutes(router: any) {
  /**
   * POST /webhook/razorpay
   * Razorpay sends webhook events here.
   * Docs: https://razorpay.com/docs/webhooks/
   */
  router.post('/webhook/razorpay', async (request: IRequest, env: Env) => {
    const signature = request.headers.get('x-razorpay-signature');
    if (!signature) {
      return Response.json({ error: 'Missing Razorpay signature' }, { status: 400 });
    }

    const body = await (request as unknown as Request).text();

    // Verify HMAC SHA256 signature
    const isValid = await verifyWebhookSignature(body, signature, env.RAZORPAY_WEBHOOK_SECRET);
    if (!isValid) {
      console.error('Razorpay webhook signature verification failed');
      return Response.json({ error: 'Invalid signature' }, { status: 400 });
    }

    let event: {
      event: string;
      payload: {
        subscription?: { entity: { id: string; status: string; notes: { user_id?: string } } };
        payment?: { entity: { id: string; subscription_id?: string; status: string; notes: { user_id?: string } } };
      };
    };

    try {
      event = JSON.parse(body);
    } catch {
      return Response.json({ error: 'Invalid JSON body' }, { status: 400 });
    }

    // Handle relevant events
    try {
      switch (event.event) {
        case 'subscription.activated': {
          const sub = event.payload.subscription?.entity;
          const userId = sub?.notes?.user_id;

          if (userId && sub) {
            await env.DB.prepare(`
              UPDATE users
              SET subscription_status = 'active',
                  stripe_customer_id = ?,
                  updated_at = datetime('now')
              WHERE id = ?
            `).bind(sub.id, userId).run();
            // Note: reusing stripe_customer_id column to store razorpay subscription_id

            console.log(`Subscription activated for user ${userId}`);
          }
          break;
        }

        case 'subscription.charged': {
          // Recurring payment successful — ensure status stays active
          const sub = event.payload.subscription?.entity;
          const userId = sub?.notes?.user_id;

          if (userId) {
            await env.DB.prepare(`
              UPDATE users
              SET subscription_status = 'active',
                  updated_at = datetime('now')
              WHERE id = ?
            `).bind(userId).run();

            console.log(`Subscription charged for user ${userId}`);
          }
          break;
        }

        case 'subscription.halted':
        case 'subscription.cancelled': {
          const sub = event.payload.subscription?.entity;
          const userId = sub?.notes?.user_id;

          if (userId) {
            await env.DB.prepare(`
              UPDATE users
              SET subscription_status = 'inactive',
                  updated_at = datetime('now')
              WHERE id = ?
            `).bind(userId).run();

            console.log(`Subscription ${event.event} for user ${userId}`);
          }
          break;
        }

        case 'subscription.pending': {
          const sub = event.payload.subscription?.entity;
          const userId = sub?.notes?.user_id;

          if (userId) {
            await env.DB.prepare(`
              UPDATE users
              SET subscription_status = 'past_due',
                  updated_at = datetime('now')
              WHERE id = ?
            `).bind(userId).run();

            console.log(`Subscription pending for user ${userId}`);
          }
          break;
        }

        case 'payment.failed': {
          const payment = event.payload.payment?.entity;
          const userId = payment?.notes?.user_id;

          if (userId) {
            await env.DB.prepare(`
              UPDATE users
              SET subscription_status = 'past_due',
                  updated_at = datetime('now')
              WHERE id = ?
            `).bind(userId).run();

            console.log(`Payment failed for user ${userId}`);
          }
          break;
        }

        default:
          console.log(`Unhandled Razorpay event: ${event.event}`);
      }
    } catch (err: any) {
      console.error(`Error processing webhook event ${event.event}:`, err);
      // Still return 200 to prevent Razorpay from retrying
    }

    return Response.json({ received: true }, { status: 200 });
  });
}
