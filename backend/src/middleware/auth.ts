/**
 * JWT authentication middleware.
 * Validates Bearer tokens and attaches userId to the request context.
 */

import { jwtVerify } from 'jose';

export interface AuthenticatedRequest extends Request {
  userId?: string;
}

/**
 * Verify a JWT token and return the decoded payload.
 */
export async function verifyToken(
  token: string,
  jwtSecret: string
): Promise<{ userId: string }> {
  const secret = new TextEncoder().encode(jwtSecret);
  const { payload } = await jwtVerify(token, secret);

  if (!payload.sub) {
    throw new Error('Token missing subject claim');
  }

  return { userId: payload.sub as string };
}

/**
 * Extract the Bearer token from an Authorization header.
 */
export function extractBearerToken(request: Request): string | null {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.slice(7);
}

/**
 * Create a JWT token for a user.
 */
export async function createToken(userId: string, jwtSecret: string): Promise<string> {
  const { SignJWT } = await import('jose');
  const secret = new TextEncoder().encode(jwtSecret);

  return new SignJWT({ sub: userId })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('30d') // Token valid for 30 days
    .sign(secret);
}
