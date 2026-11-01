/**
 * Cloud progress for The Last Wagon (adapted from Mythriven's cloud saves).
 *
 *   GET /cloud/save   the player's saved progress ({ save, updated } or { save: null })
 *   PUT /cloud/save   store the player's (already merged) progress
 *
 * Only progress between trips is kept (awards and running totals); trips
 * themselves are never saved (the game is a roguelike).
 *
 * A player is known only by their private sync code, sent as
 * `Authorization: Bearer <code>`. The Worker never stores the code itself:
 * each save lives in its own Durable Object named by the code's SHA-256 hash,
 * so nobody can list saves or read one without the code. No names, emails,
 * or other personal data are kept.
 *
 * Security: no SQL anywhere (Durable Object storage get/put only). If a SQL
 * store is ever added, use bound parameters; string filtering is NOT SQL
 * injection prevention. Uploads are rebuilt from a strict shape (validateSave).
 *
 * The game merges its progress with the cloud copy before sending (awards
 * are combined, each total keeps the higher number), so the Worker just
 * keeps what it is given.
 *
 * Binding: SAVE_VAULT (Durable Object class SaveVault, see wrangler.toml)
 */

export const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
export const CODE_LENGTH = 12;
export const MAX_SAVE_BYTES = 64_000;
/** A device may write at most once every this many ms (the game waits longer). */
export const MIN_WRITE_GAP_MS = 5_000;

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, PUT, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Accept, Authorization",
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  };
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders() });
}

/** The code without dashes or spaces, upper-case; "" if it isn't a valid code. */
export function normalizeCode(raw) {
  if (typeof raw !== "string") return "";
  const code = raw.replace(/[\s-]/g, "").toUpperCase();
  if (code.length !== CODE_LENGTH) return "";
  for (const ch of code) {
    if (!CODE_ALPHABET.includes(ch)) return "";
  }
  return code;
}

export async function hashCode(code) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode("the-last-wagon-save:" + code));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** Most awards and totals a save may hold (the game has far fewer). */
export const MAX_AWARDS = 100;
export const MAX_STATS = 32;
export const MAX_STAT_VALUE = 1_000_000_000;
const ID_PATTERN = /^[a-z0-9_]{1,40}$/;
const STAT_PATTERN = /^[a-z_]{1,24}$/;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,3})?Z?$/;
/** Names that could tamper with JavaScript objects; never accepted as keys. */
const FORBIDDEN_KEYS = new Set(["__proto__", "constructor", "prototype"]);

function plainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

/**
 * A save the Worker will keep. Only the exact shape the game sends is
 * accepted: { save_version, awards: {id: date}, stats: {id: whole number} }.
 * Anything else (unknown fields, odd ids, text where numbers belong, huge or
 * negative numbers, too many entries) is refused. Returns { save, text }
 * with a freshly built copy, so nothing unexpected is ever stored.
 */
export function validateSave(text) {
  if (typeof text !== "string" || text.length === 0) return { error: "empty save" };
  if (text.length > MAX_SAVE_BYTES) return { error: "save too large" };
  let raw;
  try {
    raw = JSON.parse(text);
  } catch {
    return { error: "invalid json" };
  }
  if (!plainObject(raw)) return { error: "invalid save" };
  for (const key of Object.keys(raw)) {
    if (!["save_version", "awards", "stats"].includes(key)) return { error: "invalid save" };
  }
  const version = raw.save_version;
  if (!Number.isInteger(version) || version < 1 || version > 100) return { error: "invalid save" };
  const awards = raw.awards ?? {};
  const stats = raw.stats ?? {};
  if (!plainObject(awards) || !plainObject(stats)) return { error: "invalid save" };
  const awardEntries = Object.entries(awards);
  const statEntries = Object.entries(stats);
  if (awardEntries.length > MAX_AWARDS || statEntries.length > MAX_STATS) return { error: "invalid save" };
  const save = { save_version: version, awards: {}, stats: {} };
  for (const [id, when] of awardEntries) {
    if (FORBIDDEN_KEYS.has(id) || !ID_PATTERN.test(id)) return { error: "invalid award" };
    if (typeof when !== "string" || !DATE_PATTERN.test(when)) return { error: "invalid award" };
    save.awards[id] = when;
  }
  for (const [id, value] of statEntries) {
    if (FORBIDDEN_KEYS.has(id) || !STAT_PATTERN.test(id)) return { error: "invalid stat" };
    if (!Number.isInteger(value) || value < 0 || value > MAX_STAT_VALUE) return { error: "invalid stat" };
    save.stats[id] = value;
  }
  return { save, text: JSON.stringify(save) };
}

/** Routes /cloud/save to the player's own SaveVault. */
export async function handleCloud(request, env) {
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders() });
  if (!env.SAVE_VAULT) return json({ error: "cloud saves are not set up" }, 503);
  const auth = request.headers.get("Authorization") || "";
  const code = normalizeCode(auth.replace(/^Bearer\s+/i, ""));
  if (!code) return json({ error: "invalid code" }, 401);
  if (request.method !== "GET" && request.method !== "PUT") return json({ error: "method not allowed" }, 405);
  let body = "";
  if (request.method === "PUT") {
    const declared = parseInt(request.headers.get("content-length") || "0", 10);
    if (Number.isFinite(declared) && declared > MAX_SAVE_BYTES) return json({ error: "save too large" }, 413);
    const checked = validateSave(await request.text());
    if (checked.error) return json({ error: checked.error }, checked.error === "save too large" ? 413 : 400);
    // Store the rebuilt copy, never the raw text that was sent.
    body = checked.text;
  }
  const stub = env.SAVE_VAULT.get(env.SAVE_VAULT.idFromName(await hashCode(code)));
  return stub.fetch("https://vault/save", { method: request.method, body: request.method === "PUT" ? body : undefined });
}

/** One player's cloud progress. */
export class SaveVault {
  constructor(state) {
    this.storage = state.storage;
  }

  async fetch(request) {
    if (request.method === "GET") {
      const save = (await this.storage.get("save")) ?? null;
      const updated = (await this.storage.get("updated")) ?? 0;
      return json({ save: save ? JSON.parse(save) : null, updated });
    }
    const now = Date.now();
    const last = (await this.storage.get("updated")) ?? 0;
    if (now - last < MIN_WRITE_GAP_MS) return json({ error: "too soon", updated: last }, 429);
    const text = await request.text();
    await this.storage.put({ save: text, updated: now });
    return json({ ok: true, updated: now });
  }
}
