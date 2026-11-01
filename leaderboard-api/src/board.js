/**
 * The Last Wagon leaderboard rules: what a score must look like, how the
 * board is sorted, and how many rows it keeps. No network code here, so it
 * can be tested with `npm test`.
 *
 * A score (one trip):
 *   name        player-chosen, letters/numbers/space/_/- only, up to 12
 *   route       route id, e.g. "maine_to_florida"
 *   finished    true when the trip reached the final stop
 *   stops       stops reached after the start (0 = never left)
 *   total_stops stops on the route after the start
 *   days        days on the road (1 or more)
 *   survivors   survivors still standing at the end (0-4)
 *   miles       miles traveled
 *   apocalypse  what ended the world, e.g. "zombies" or "fallout+aliens"
 *   perk        starting perk id, "none" if no perk (older games don't send it)
 *   version     game version, "XX.XX.XX"
 *   date        set by the Worker, never by the game
 *
 * Ranking: finished trips first, then most stops reached, then fewest days,
 * then most survivors standing, then whoever got there first.
 */

export const MAX_ENTRIES = 100;
export const MAX_NAME_LENGTH = 12;
export const MAX_STOPS = 40;
export const MAX_DAYS = 2000;
export const MAX_SURVIVORS = 4;
export const MAX_MILES = 10000;
/** Nobody covers more miles than this per day, even driving flat out. */
export const MAX_MILES_PER_DAY = 400;
export const THREATS = Object.freeze(["zombies", "fallout", "aliens", "plague"]);
export const ABOUT =
  "The Last Wagon shared leaderboard. Written only by the leaderboard Worker; edits by hand are overwritten.";

const ROUTE_PATTERN = /^[a-z0-9_]{1,40}$/;
const PERK_PATTERN = /^[a-z_]{1,24}$/;
const VERSION_PATTERN = /^\d{2}\.\d{2}\.\d{2}$/;
/** Script / markup characters: a name containing any of these is refused outright. */
const INJECTION_MARKERS = ["'", '"', ";", "--", "/*", "*/", "\\", "`", "<", ">"];

export function looksLikeInjection(raw) {
  const s = String(raw ?? "");
  for (const marker of INJECTION_MARKERS) {
    if (s.includes(marker)) return true;
  }
  for (let i = 0; i < s.length; i++) {
    const code = s.charCodeAt(i);
    // Control characters, and invisible or right-to-left trick characters.
    if (code < 32 || (code >= 127 && code <= 159)) return true;
    if ((code >= 0x200b && code <= 0x200f) || (code >= 0x202a && code <= 0x202e)) return true;
    if ((code >= 0x2066 && code <= 0x2069) || code === 0xfeff) return true;
  }
  return false;
}

/** Keeps A-Z, a-z, 0-9, space, _ and -; trims; cuts to 12. */
export function sanitizeName(raw) {
  let cleaned = "";
  for (const ch of String(raw ?? "")) {
    if (/[A-Za-z0-9 _-]/.test(ch)) cleaned += ch;
  }
  cleaned = cleaned.replace(/ {2,}/g, " ").trim();
  return cleaned.slice(0, MAX_NAME_LENGTH).trim();
}

function wholeNumber(raw, min, max) {
  const n = Number(raw);
  if (!Number.isFinite(n) || !Number.isInteger(n) || n < min || n > max) return null;
  return n;
}

/** "zombies" or "fallout+aliens": one or two different known threats. */
function normalizeApocalypse(raw) {
  const parts = String(raw ?? "").split("+");
  if (parts.length < 1 || parts.length > 2) return null;
  if (!parts.every((p) => THREATS.includes(p))) return null;
  if (parts.length === 2 && parts[0] === parts[1]) return null;
  return parts.join("+");
}

/**
 * Checks one score. Returns { entry } when it's acceptable, or { error } with
 * a short reason. `date` is added by the caller.
 */
export function validateScore(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) return { error: "invalid json" };
  if (looksLikeInjection(body.name)) return { error: "invalid name" };
  const name = sanitizeName(body.name);
  if (!name) return { error: "invalid name" };
  const route = String(body.route ?? "");
  if (!ROUTE_PATTERN.test(route)) return { error: "invalid route" };
  if (typeof body.finished !== "boolean") return { error: "invalid finished" };
  const finished = body.finished;
  const total_stops = wholeNumber(body.total_stops, 1, MAX_STOPS);
  if (total_stops === null) return { error: "invalid total_stops" };
  const stops = wholeNumber(body.stops, 0, total_stops);
  if (stops === null) return { error: "invalid stops" };
  if (finished !== (stops === total_stops)) return { error: "invalid finished" };
  const days = wholeNumber(body.days, 1, MAX_DAYS);
  if (days === null) return { error: "invalid days" };
  const survivors = wholeNumber(body.survivors, 0, MAX_SURVIVORS);
  if (survivors === null || (finished && survivors === 0)) return { error: "invalid survivors" };
  const miles = wholeNumber(body.miles, 0, MAX_MILES);
  if (miles === null || miles > days * MAX_MILES_PER_DAY) return { error: "invalid miles" };
  if (stops > 0 && miles === 0) return { error: "invalid miles" };
  const apocalypse = normalizeApocalypse(body.apocalypse);
  if (apocalypse === null) return { error: "invalid apocalypse" };
  const version = String(body.version ?? "");
  if (!VERSION_PATTERN.test(version)) return { error: "invalid version" };
  const perk = body.perk === undefined ? "none" : String(body.perk);
  if (!PERK_PATTERN.test(perk)) return { error: "invalid perk" };
  return {
    entry: { name, route, finished, stops, total_stops, days, survivors, miles, apocalypse, perk, version },
  };
}

/** Finished first, then most stops, then fewest days, then most survivors, then earliest. */
export function compareEntries(a, b) {
  return (
    Number(b.finished) - Number(a.finished) ||
    b.stops - a.stops ||
    a.days - b.days ||
    b.survivors - a.survivors ||
    String(a.date ?? "").localeCompare(String(b.date ?? ""))
  );
}

/** The same trip sent twice (for example a double tap on Submit). */
export function isDuplicate(entries, entry) {
  return entries.some(
    (e) =>
      e.name === entry.name &&
      e.route === entry.route &&
      e.stops === entry.stops &&
      e.days === entry.days &&
      e.survivors === entry.survivors &&
      e.miles === entry.miles &&
      e.apocalypse === entry.apocalypse &&
      (e.perk ?? "none") === (entry.perk ?? "none"),
  );
}

/** Rebuilds a board from stored data, dropping anything malformed. */
export function normalizeBoard(raw) {
  const entries = [];
  for (const item of Array.isArray(raw?.entries) ? raw.entries : []) {
    const checked = validateScore(item);
    if (!checked.entry) continue;
    const date = String(item.date ?? "");
    checked.entry.date = /^\d{4}-\d{2}-\d{2}T[\d:.]+Z$/.test(date) ? date : "";
    entries.push(checked.entry);
  }
  entries.sort(compareEntries);
  return {
    _about: ABOUT,
    updated: typeof raw?.updated === "string" ? raw.updated : "",
    entries: entries.slice(0, MAX_ENTRIES),
  };
}

/** True when `entry` would make the board (it isn't full, or beats the last row). */
export function qualifies(board, entry) {
  if (board.entries.length < MAX_ENTRIES) return true;
  return compareEntries(entry, board.entries[board.entries.length - 1]) < 0;
}

/** Adds `entry` (with its date) and returns the new board. */
export function addEntry(board, entry, nowIso) {
  const entries = [...board.entries, { ...entry, date: nowIso }];
  entries.sort(compareEntries);
  return { _about: ABOUT, updated: nowIso, entries: entries.slice(0, MAX_ENTRIES) };
}

export function emptyBoard() {
  return { _about: ABOUT, updated: "", entries: [] };
}
