/**
 * Razorpay helpers for Cloudflare Workers.
 * Uses Razorpay REST API via fetch (no SDK needed — Workers-compatible).
 */

const RAZORPAY_API_BASE = 'https://api.razorpay.com/v1';

/**
 * Build Basic Auth header from Razorpay key_id and key_secret.
 */
function authHeader(keyId: string, keySecret: string): string {
  return `Basic ${btoa(`${keyId}:${keySecret}`)}`;
}

/**
 * Create a Razorpay Subscription for a user.
 * Returns the subscription object with `short_url` for hosted checkout.
 */
export async function createSubscription(
  keyId: string,
  keySecret: string,
  planId: string,
  userId: string,
  customerEmail?: string
): Promise<{ id: string; short_url: string; status: string }> {
  const body: Record<string, any> = {
    plan_id: planId,
    total_count: 12, // 12 billing cycles
    quantity: 1,
    notes: {
      user_id: userId,
    },
  };

  if (customerEmail) {
    body.customer_notify = 1;
  }

  const response = await fetch(`${RAZORPAY_API_BASE}/subscriptions`, {
    method: 'POST',
    headers: {
      Authorization: authHeader(keyId, keySecret),
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Razorpay subscription creation failed: ${response.status} - ${error}`);
  }

  return response.json();
}

/**
 * Fetch a Razorpay Subscription by ID to check its status.
 */
export async function getSubscription(
  keyId: string,
  keySecret: string,
  subscriptionId: string
): Promise<{ id: string; status: string; plan_id: string }> {
  const response = await fetch(`${RAZORPAY_API_BASE}/subscriptions/${subscriptionId}`, {
    headers: {
      Authorization: authHeader(keyId, keySecret),
    },
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Razorpay subscription fetch failed: ${response.status} - ${error}`);
  }

  return response.json();
}

/**
 * Verify Razorpay webhook signature using HMAC SHA256 (WebCrypto).
 * Razorpay signs the raw request body with the webhook secret.
 */
export async function verifyWebhookSignature(
  body: string,
  signature: string,
  webhookSecret: string
): Promise<boolean> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(webhookSecret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signatureBuffer = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(body)
  );

  const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  return expectedSignature === signature;
}
