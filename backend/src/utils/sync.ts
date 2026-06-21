/**
 * Date-seeded deterministic random selection.
 * Ensures all devices for the same user see the same wallpaper on the same day.
 */

/**
 * Mulberry32 — A simple, fast 32-bit seeded PRNG.
 * Produces deterministic output for a given seed.
 */
function mulberry32(seed: number): () => number {
  return function () {
    let t = (seed += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * Simple string hash (djb2 algorithm).
 * Produces a 32-bit integer from an arbitrary string.
 */
function hashString(str: string): number {
  let hash = 5381;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) + hash + str.charCodeAt(i)) | 0; // Force 32-bit integer
  }
  return hash >>> 0; // Ensure unsigned
}

/**
 * Returns a deterministic index [0, totalPins) for a given date + userId.
 *
 * @param dateStr - Current date as "YYYY-MM-DD"
 * @param userId  - The user's unique ID
 * @param totalPins - Total number of pins available
 * @returns A deterministic index into the pin array
 */
export function getSeededIndex(dateStr: string, userId: string, totalPins: number): number {
  if (totalPins <= 0) return 0;
  const seed = hashString(`${dateStr}:${userId}`);
  const rng = mulberry32(seed);
  // Call once to get our deterministic value
  const value = rng();
  return Math.floor(value * totalPins);
}

/**
 * Returns today's date string in YYYY-MM-DD format (UTC).
 */
export function getTodayDateString(): string {
  const now = new Date();
  return now.toISOString().split('T')[0];
}
