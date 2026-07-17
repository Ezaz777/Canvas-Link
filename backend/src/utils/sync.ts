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
 * Generates a deterministically shuffled array of indices [0, ..., length - 1].
 */
function getDeterministicShuffle(seed: number, length: number): number[] {
  const rng = mulberry32(seed);
  rng(); rng(); rng(); // warm up
  
  const arr = Array.from({ length }, (_, i) => i);
  
  // Fisher-Yates shuffle using deterministic RNG
  for (let i = length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    const temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
  }
  
  return arr;
}

/**
 * Returns a deterministic index [0, totalPins) for a given date + userId.
 * Uses a cycle-based shuffle to ensure no repeats until all pins are used.
 *
 * @param dateStr - Current date as "YYYY-MM-DD"
 * @param userId  - The user's unique ID
 * @param totalPins - Total number of pins available
 * @param skipOffset - Number of times the user has skipped a wallpaper
 * @returns A deterministic index into the pin array
 */
export function getSeededIndex(dateStr: string, userId: string, totalPins: number, skipOffset: number = 0): number {
  if (totalPins <= 0) return 0;
  
  // Calculate days since a fixed epoch (Jan 1, 2026)
  const epoch = new Date('2026-01-01T00:00:00Z').getTime();
  const current = new Date(`${dateStr}T00:00:00Z`).getTime();
  const baseDaysSinceEpoch = Math.floor((current - epoch) / 86400000);
  const daysSinceEpoch = baseDaysSinceEpoch + skipOffset;
  
  // If date is before epoch (fallback to old method)
  if (daysSinceEpoch < 0) {
    const seed = hashString(`${dateStr}:${userId}:${skipOffset}`);
    const rng = mulberry32(seed);
    rng(); rng(); rng();
    return Math.floor(rng() * totalPins);
  }
  
  // Calculate current cycle and position within the cycle
  const cycleIndex = Math.floor(daysSinceEpoch / totalPins);
  const positionInCycle = daysSinceEpoch % totalPins;
  
  // The seed remains constant for the entire duration of the cycle!
  const seed = hashString(`${userId}:cycle:${cycleIndex}:pins:${totalPins}`);
  
  // Get the fully shuffled array for this specific cycle
  const shuffledIndices = getDeterministicShuffle(seed, totalPins);
  
  // Pick the pin for today's position
  return shuffledIndices[positionInCycle];
}

/**
 * Returns today's date string in YYYY-MM-DD format (UTC).
 */
export function getTodayDateString(): string {
  const now = new Date();
  return now.toISOString().split('T')[0];
}
