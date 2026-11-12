/**
 * Google Play Developer API (Android Publisher v3) verification client.
 * Authenticates via a Google Cloud Service Account (RS256 JWT via jose)
 * and verifies one-time in-app product purchase tokens server-side.
 */

import { importPKCS8, SignJWT } from 'jose';

const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const ANDROID_PUBLISHER_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const ANDROID_PUBLISHER_BASE = 'https://androidpublisher.googleapis.com/androidpublisher/v3';

interface GoogleServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

export interface GooglePlayProductPurchase {
  kind?: string;
  purchaseTimeMillis?: string;
  purchaseState: number; // 0 = Purchased, 1 = Canceled, 2 = Pending
  consumptionState?: number;
  acknowledgementState?: number; // 0 = Yet to be acknowledged, 1 = Acknowledged
  orderId?: string;
  purchaseType?: number;
}

export interface VerifyProductResult {
  valid: boolean;
  purchaseState: number;
  acknowledgementState: number;
  orderId?: string;
  reason?: string;
  statusCode?: number;
}

interface TokenCache {
  accessToken: string;
  expiresAt: number;
}

let cachedGoogleToken: TokenCache | null = null;

/**
 * Obtain a short-lived OAuth2 access token for the Android Publisher API
 * using the configured Google Cloud Service Account JSON credentials.
 */
async function getGoogleAccessToken(serviceAccountJson: string): Promise<string> {
  const now = Date.now();
  if (cachedGoogleToken && cachedGoogleToken.expiresAt > now + 60_000) {
    return cachedGoogleToken.accessToken;
  }

  let credentials: GoogleServiceAccount;
  try {
    credentials = JSON.parse(serviceAccountJson) as GoogleServiceAccount;
  } catch {
    throw new Error('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is not valid JSON');
  }

  if (!credentials.client_email || !credentials.private_key) {
    throw new Error('Service account JSON is missing client_email or private_key');
  }

  // Handle escaped newlines if the secret was pasted as a single line
  const normalizedPrivateKey = credentials.private_key.replace(/\\n/g, '\n');
  const tokenUri = credentials.token_uri || GOOGLE_TOKEN_URL;

  const key = await importPKCS8(normalizedPrivateKey, 'RS256');
  const assertion = await new SignJWT({ scope: ANDROID_PUBLISHER_SCOPE })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(credentials.client_email)
    .setSubject(credentials.client_email)
    .setAudience(tokenUri)
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(key);

  const tokenRes = await fetch(tokenUri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!tokenRes.ok) {
    const errText = await tokenRes.text();
    throw new Error(`Google OAuth token exchange failed (${tokenRes.status}): ${errText}`);
  }

  const tokenData = (await tokenRes.json()) as { access_token: string; expires_in?: number };
  const expiresInMs = (tokenData.expires_in ?? 3600) * 1000;
  cachedGoogleToken = {
    accessToken: tokenData.access_token,
    expiresAt: now + expiresInMs,
  };

  return tokenData.access_token;
}

/**
 * Acknowledge a verified one-time Google Play purchase server-side if not yet acknowledged.
 */
async function acknowledgeProductPurchase(
  accessToken: string,
  packageName: string,
  productId: string,
  purchaseToken: string
): Promise<void> {
  const url =
    `${ANDROID_PUBLISHER_BASE}/applications/${encodeURIComponent(packageName)}` +
    `/purchases/products/${encodeURIComponent(productId)}` +
    `/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({}),
  });

  if (!res.ok) {
    const errText = await res.text();
    console.warn(`Google Play server-side acknowledge failed (${res.status}): ${errText}`);
  }
}

/**
 * Verify a Google Play non-consumable / one-time product purchase token
 * with Google's Android Publisher v3 API.
 */
export async function verifyGooglePlayProductPurchase(params: {
  serviceAccountJson: string;
  packageName: string;
  productId: string;
  purchaseToken: string;
}): Promise<VerifyProductResult> {
  const { serviceAccountJson, packageName, productId, purchaseToken } = params;

  const accessToken = await getGoogleAccessToken(serviceAccountJson);
  const url =
    `${ANDROID_PUBLISHER_BASE}/applications/${encodeURIComponent(packageName)}` +
    `/purchases/products/${encodeURIComponent(productId)}` +
    `/tokens/${encodeURIComponent(purchaseToken)}`;

  const res = await fetch(url, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error(`Google Play verify failed (${res.status}): ${errText}`);
    return {
      valid: false,
      purchaseState: -1,
      acknowledgementState: 0,
      reason: 'Could not verify purchase receipt with Google Play.',
      statusCode: res.status >= 500 ? 502 : 400,
    };
  }

  const purchase = (await res.json()) as GooglePlayProductPurchase;
  const acknowledgementState = purchase.acknowledgementState ?? 0;

  if (purchase.purchaseState === 2) {
    return {
      valid: false,
      purchaseState: purchase.purchaseState,
      acknowledgementState,
      orderId: purchase.orderId,
      reason: 'Payment is pending confirmation from Google Play.',
      statusCode: 402,
    };
  }

  if (purchase.purchaseState !== 0) {
    return {
      valid: false,
      purchaseState: purchase.purchaseState,
      acknowledgementState,
      orderId: purchase.orderId,
      reason: 'This Google Play purchase is canceled or refunded.',
      statusCode: 403,
    };
  }

  if (acknowledgementState === 0) {
    await acknowledgeProductPurchase(accessToken, packageName, productId, purchaseToken);
  }

  return {
    valid: true,
    purchaseState: purchase.purchaseState,
    acknowledgementState,
    orderId: purchase.orderId,
  };
}

