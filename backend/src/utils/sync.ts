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
 * Returns a deterministic index [0, totalPins) for a given date + userId + interval.
 * Uses a cycle-based shuffle to ensure no repeats until all pins are used.
 *
 * @param dateStr - Current date as "YYYY-MM-DD"
 * @param userId  - The user's unique ID
 * @param totalPins - Total number of pins available
 * @param skipOffset - Number of times the user has skipped a wallpaper
 * @param frequencyHours - How often the wallpaper changes (e.g. 1, 6, 12, 24)
 * @param currentHour - Current hour (0-23)
 * @returns A deterministic index into the pin array
 */
export function getSeededIndex(
  dateStr: string,
  userId: string,
  totalPins: number,
  skipOffset: number = 0,
  frequencyHours: number = 24,
  currentHour: number = 0
): number {
  if (totalPins <= 0) return 0;
  
  const freq = (frequencyHours > 0 && frequencyHours <= 24) ? frequencyHours : 24;
  const hour = (currentHour >= 0 && currentHour <= 23) ? currentHour : 0;
  
  const intervalsPerDay = Math.floor(24 / freq);
  const currentIntervalInDay = Math.floor(hour / freq);

  // Calculate days since fixed epoch (Jan 1, 2026)
  const epoch = new Date('2026-01-01T00:00:00Z').getTime();
  const current = new Date(`${dateStr}T00:00:00Z`).getTime();
  const baseDaysSinceEpoch = Math.floor((current - epoch) / 86400000);
  
  // Total intervals since epoch steps forward with each frequency interval (e.g. every 1 hour)
  const totalIntervalsSinceEpoch = (baseDaysSinceEpoch * intervalsPerDay) + currentIntervalInDay + skipOffset;

  if (totalIntervalsSinceEpoch < 0) {
    const seed = hashString(`${dateStr}:${hour}:${userId}:${skipOffset}`);
    const rng = mulberry32(seed);
    rng(); rng(); rng();
    return Math.floor(rng() * totalPins);
  }

  // Calculate current cycle and position within the cycle
  const cycleIndex = Math.floor(totalIntervalsSinceEpoch / totalPins);
  const positionInCycle = totalIntervalsSinceEpoch % totalPins;

  // The seed remains constant for the entire duration of the cycle
  const seed = hashString(`${userId}:cycle:${cycleIndex}:pins:${totalPins}`);
  const shuffledIndices = getDeterministicShuffle(seed, totalPins);

  return shuffledIndices[positionInCycle];
}

/**
 * Returns today's date string in YYYY-MM-DD format (UTC).
 */
export function getTodayDateString(): string {
  const now = new Date();
  return now.toISOString().split('T')[0];
}

/**
 * Result of the smart image flagging and selection algorithm.
 */
export interface PinSelectionResult {
  selectedPin: any;
  flaggedPinIds: string[];
  isUnflaggedCycle: boolean;
  unflaggedPinId: string | null;
  totalPins: number;
  flaggedCount: number;
  unflaggedCount: number;
}

/**
 * Smart Priority Flagging Algorithm:
 * 1. Flags images that have been selected before and NEVER re-selects a flagged image
 *    before all images on the board have been shown.
 * 2. If the user later adds new images to the board, the new (unflagged) images get immediate priority.
 * 3. When all images on the board have been flagged (no unflagged images remaining):
 *    Unflags images ONE BY ONE, starting with the very first image that was flagged among them (FIFO),
 *    shows it, and continues the cycle. If new images are added at any point during this,
 *    they immediately jump ahead in priority.
 *
 * @param allPins - All pins currently existing in the Pinterest board
 * @param currentFlaggedIds - List of pin IDs currently flagged, in chronological order [oldest, ..., newest]
 * @param seedOrOffset - Number for deterministic tie-breaking among multiple unflagged candidates
 */
export function selectNextPin(
  allPins: any[],
  currentFlaggedIds: string[],
  seedOrOffset: number = 0
): PinSelectionResult {
  if (!allPins || allPins.length === 0) {
    throw new Error('No pins available for selection');
  }

  // 1. Build a map of valid pins currently on the board
  const validPinMap = new Map<string, any>();
  for (const pin of allPins) {
    if (pin && pin.id) {
      validPinMap.set(String(pin.id), pin);
    }
  }

  // 2. Prune any flagged IDs that no longer exist on the board (e.g. deleted by user on Pinterest)
  let activeFlagged = currentFlaggedIds
    .map(id => String(id))
    .filter(id => validPinMap.has(id));

  // 3. Find unflagged pins (never shown, or newly added by user to board)
  const flaggedSet = new Set(activeFlagged);
  const unflaggedPins = allPins.filter(pin => !flaggedSet.has(String(pin.id)));

  // Priority check: Newly added or unflagged pins get absolute priority
  if (unflaggedPins.length > 0) {
    const pickIndex = Math.abs(seedOrOffset) % unflaggedPins.length;
    const selected = unflaggedPins[pickIndex];
    const selectedId = String(selected.id);

    // Flag this pin: append to the end of the flagged queue
    activeFlagged.push(selectedId);

    return {
      selectedPin: selected,
      flaggedPinIds: activeFlagged,
      isUnflaggedCycle: false,
      unflaggedPinId: null,
      totalPins: allPins.length,
      flaggedCount: activeFlagged.length,
      unflaggedCount: unflaggedPins.length - 1,
    };
  }

  // 4. All pins on the board are currently flagged!
  // Unflag images ONE BY ONE: unflag the first (oldest) flagged image of the board
  const unflaggedId = activeFlagged.shift()!;
  const selected = validPinMap.get(unflaggedId) || allPins[0];

  // Re-flag it at the end of the queue so it won't be picked again until all others cycle through
  activeFlagged.push(String(selected.id));

  return {
    selectedPin: selected,
    flaggedPinIds: activeFlagged,
    isUnflaggedCycle: true,
    unflaggedPinId: unflaggedId,
    totalPins: allPins.length,
    flaggedCount: activeFlagged.length,
    unflaggedCount: 0,
  };
}
