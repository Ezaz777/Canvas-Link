/**
 * Pinterest API v5 client.
 * Handles OAuth token refresh and board pin retrieval.
 */

const PINTEREST_API_BASE = 'https://api.pinterest.com/v5';
const PINTEREST_OAUTH_BASE = 'https://api.pinterest.com/v5/oauth';

export interface PinterestToken {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
  scope: string;
}

export interface PinterestPin {
  id: string;
  title: string | null;
  description: string | null;
  media_type: string;
  media: {
    media_type: string;
    images?: {
      [key: string]: {
        url: string;
        width: number;
        height: number;
      };
    };
  };
}

export interface PinterestPinsResponse {
  items: PinterestPin[];
  bookmark: string | null;
}

/**
 * Exchange an authorization code for access + refresh tokens.
 */
export async function exchangeCodeForToken(
  code: string,
  redirectUri: string,
  appId: string,
  appSecret: string
): Promise<PinterestToken> {
  const credentials = btoa(`${appId}:${appSecret}`);

  const response = await fetch(`${PINTEREST_OAUTH_BASE}/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${credentials}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri,
      continuous_refresh: 'true',
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Pinterest token exchange failed: ${response.status} - ${error}`);
  }

  return response.json();
}

/**
 * Refresh an access token using a refresh token.
 */
export async function refreshAccessToken(
  refreshToken: string,
  appId: string,
  appSecret: string
): Promise<PinterestToken> {
  const credentials = btoa(`${appId}:${appSecret}`);

  const response = await fetch(`${PINTEREST_OAUTH_BASE}/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${credentials}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      continuous_refresh: 'true',
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Pinterest token refresh failed: ${response.status} - ${error}`);
  }

  return response.json();
}

/**
 * Get the authenticated user's profile info.
 */
export async function getUserProfile(accessToken: string): Promise<{ id: string; username: string }> {
  const response = await fetch(`${PINTEREST_API_BASE}/user_account`, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Pinterest user profile fetch failed: ${response.status}`);
  }

  const data: any = await response.json();
  return { id: data.id, username: data.username };
}

/**
 * Fetch ALL pins from a board, handling pagination.
 * Returns only image-type pins.
 */
export async function getBoardPins(
  accessToken: string,
  boardId: string
): Promise<PinterestPin[]> {
  const allPins: PinterestPin[] = [];
  let bookmark: string | null = null;

  do {
    const url = new URL(`${PINTEREST_API_BASE}/boards/${boardId}/pins`);
    url.searchParams.set('page_size', '100');
    if (bookmark) {
      url.searchParams.set('bookmark', bookmark);
    }

    const response = await fetch(url.toString(), {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Pinterest board pins fetch failed: ${response.status} - ${error}`);
    }

    const data: PinterestPinsResponse = await response.json();

    // Filter for image pins only (exclude videos, etc.)
    const imagePins = data.items.filter(
      (pin) => pin.media?.media_type === 'image' && pin.media?.images?.orig
    );
    allPins.push(...imagePins);

    bookmark = data.bookmark;
  } while (bookmark);

  return allPins;
}

/**
 * Build the Pinterest OAuth2 authorization URL.
 */
export function buildAuthorizationUrl(appId: string, redirectUri: string, state: string): string {
  const params = new URLSearchParams({
    client_id: appId,
    redirect_uri: redirectUri,
    response_type: 'code',
    scope: 'pins:read,boards:read',
    state,
  });
  return `https://www.pinterest.com/oauth/?${params.toString()}`;
}
