/**
 * The Last Wagon online services Worker (Cloudflare).
 *   GET  /leaderboard   the board, best first
 *   POST /leaderboard   send one finished trip; it is checked, then saved
 *   GET  /suggestions   whether suggestions are being accepted
 *   POST /suggestions   send one anonymous suggestion (becomes a GitHub Issue)
 *   GET/PUT /cloud/save online progress, by private sync code (see cloud.js)
 *   /auth/*             Sign in with Google (see accounts.js)
 *   GET  /privacy       the privacy policy (see privacy.js)
 *
 * The Worker is the only thing that can write the board. It keeps the board in
 * Workers KV (fast) and commits leaderboard.json to the repo's `data` branch so
 * anyone can see it on GitHub. The game never holds a GitHub key.
 *
 * Secret:   GITHUB_TOKEN (fine-grained token: Contents + Issues read/write on Zephino/The_Last_Wagon only)
 * Binding:  LEADERBOARD_KV
 * Vars:     GITHUB_OWNER, GITHUB_REPO, GITHUB_PATH, GITHUB_BRANCH (see wrangler.toml)
 */

import { addEntry, emptyBoard, isDuplicate, normalizeBoard, qualifies, validateScore } from "./board.js";
import { handleSuggestionPost, suggestionStatus } from "./suggestions.js";
import { handleCloud } from "./cloud.js";
import { handleAuth } from "./accounts.js";
import { privacyPage } from "./privacy.js";

export { SaveVault } from "./cloud.js";
export { AccountVault } from "./accounts.js";

const MAX_BODY_BYTES = 8000;
const RATE_LIMIT_WINDOW_MS = 60_000;
/** Requests of any kind per IP per minute. */
const RATE_LIMIT_MAX = 30;
/** Scores sent per IP per minute (a trip takes far longer than this). */
const SUBMIT_LIMIT_MAX = 3;

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Accept",
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  };
}

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders() });
}

function settings(env) {
  return {
    owner: env.GITHUB_OWNER || "Zephino",
    repo: env.GITHUB_REPO || "The_Last_Wagon",
    path: env.GITHUB_PATH || "leaderboard.json",
    branch: env.GITHUB_BRANCH || "data",
  };
}

/**
 * True while `ip` is under `max` requests this minute for this `kind`.
 * Each check writes to KV, and Cloudflare's free plan allows about 1,000 KV
 * writes a day, so only sending (POST) is counted, never reading the board.
 * If KV can't be used (for example the daily write limit is reached), the
 * check lets the request through rather than breaking score submission.
 */
async function underLimit(env, kind, ip, max) {
  if (!env.LEADERBOARD_KV) return true;
  const key = `rl:${kind}:${ip}`;
  const now = Date.now();
  let data = { t: now, n: 0 };
  try {
    const existing = await env.LEADERBOARD_KV.get(key, { type: "json" });
    if (existing && typeof existing === "object") data = existing;
  } catch (_) {}
  if (now - (data.t || 0) > RATE_LIMIT_WINDOW_MS) data = { t: now, n: 0 };
  data.n = (data.n || 0) + 1;
  try {
    await env.LEADERBOARD_KV.put(key, JSON.stringify(data), { expirationTtl: 120 });
  } catch (err) {
    console.log("rate limit write failed:", String(err));
  }
  return data.n <= max;
}

async function loadBoard(env) {
  if (env.LEADERBOARD_KV) {
    const cached = await env.LEADERBOARD_KV.get("board", { type: "json" });
    if (cached) return normalizeBoard(cached);
  }
  const s = settings(env);
  const url = `https://raw.githubusercontent.com/${s.owner}/${s.repo}/${s.branch}/${s.path}`;
  const res = await fetch(url, { headers: { Accept: "application/json" } });
  if (!res.ok) return emptyBoard();
  try {
    return normalizeBoard(await res.json());
  } catch (err) {
    console.log("loadBoard: bad JSON on GitHub:", String(err));
    return emptyBoard();
  }
}

async function saveBoard(env, board) {
  if (env.LEADERBOARD_KV) {
    try {
      await env.LEADERBOARD_KV.put("board", JSON.stringify(board));
    } catch (err) {
      // Still saved on GitHub below; the next read falls back to it.
      console.log("board KV write failed:", String(err));
    }
  }
  await commitToGitHub(env, board);
}

/** Writes leaderboard.json on the data branch (never any other branch). */
async function commitToGitHub(env, board) {
  if (!env.GITHUB_TOKEN) {
    console.log("GITHUB_TOKEN missing; skipped the GitHub commit");
    return;
  }
  const s = settings(env);
  const api = `https://api.github.com/repos/${s.owner}/${s.repo}/contents/${s.path}`;
  const headers = {
    Authorization: `Bearer ${env.GITHUB_TOKEN}`,
    Accept: "application/vnd.github+json",
    "User-Agent": "the-last-wagon-leaderboard-worker",
    "Content-Type": "application/json",
  };
  let sha;
  const getRes = await fetch(`${api}?ref=${encodeURIComponent(s.branch)}`, { headers });
  if (getRes.ok) sha = (await getRes.json()).sha;
  const text = JSON.stringify(board, null, "\t") + "\n";
  const content = btoa(unescape(encodeURIComponent(text)));
  const top = board.entries[0];
  const putRes = await fetch(api, {
    method: "PUT",
    headers,
    body: JSON.stringify({
      message: top ? `Leaderboard: ${board.entries.length} trips` : "Leaderboard update",
      content,
      branch: s.branch,
      sha,
    }),
  });
  if (!putRes.ok) {
    console.log("GitHub commit failed:", putRes.status, await putRes.text());
  }
}

async function handlePost(request, env, ip) {
  const declared = parseInt(request.headers.get("content-length") || "0", 10);
  if (Number.isFinite(declared) && declared > MAX_BODY_BYTES) {
    return jsonResponse({ error: "payload too large" }, 413);
  }
  const text = await request.text();
  if (text.length > MAX_BODY_BYTES) return jsonResponse({ error: "payload too large" }, 413);
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    return jsonResponse({ error: "invalid json" }, 400);
  }
  const checked = validateScore(body);
  if (checked.error) return jsonResponse({ error: checked.error }, 400);
  if (!(await underLimit(env, "post", ip, SUBMIT_LIMIT_MAX))) {
    return jsonResponse({ error: "rate limited" }, 429);
  }
  const board = await loadBoard(env);
  if (isDuplicate(board.entries, checked.entry) || !qualifies(board, checked.entry)) {
    return jsonResponse({ ...board, accepted: false });
  }
  const updated = addEntry(board, checked.entry, new Date().toISOString());
  await saveBoard(env, updated);
  return jsonResponse({ ...updated, accepted: true });
}

export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);
      // Cloud progress and sign-in answer their own preflight and checks (no KV use).
      if (url.pathname === "/cloud/save") return await handleCloud(request, env);
      if (url.pathname.startsWith("/auth/")) return await handleAuth(request, env);
      if (url.pathname === "/privacy") return privacyPage();
      if (request.method === "OPTIONS") {
        return new Response(null, { status: 204, headers: corsHeaders() });
      }
      if (url.pathname !== "/leaderboard" && url.pathname !== "/" && url.pathname !== "/suggestions") {
        return jsonResponse({ error: "not found" }, 404);
      }
      const ip = request.headers.get("CF-Connecting-IP") || "unknown";
      // Only sending is rate limited: reading the board writes nothing to KV.
      if (request.method === "POST") {
        try {
          if (!(await underLimit(env, "any", ip, RATE_LIMIT_MAX))) {
            return jsonResponse({ error: "rate limited" }, 429);
          }
        } catch (err) {
          console.log("rate limit check failed:", String(err));
        }
      }
      if (url.pathname === "/suggestions") {
        if (request.method === "GET") return suggestionStatus(env);
        if (request.method === "POST") return await handleSuggestionPost(request, env, ip);
        return jsonResponse({ error: "method not allowed" }, 405);
      }
      if (request.method === "GET") return jsonResponse(await loadBoard(env));
      if (request.method === "POST") return await handlePost(request, env, ip);
      return jsonResponse({ error: "method not allowed" }, 405);
    } catch (err) {
      console.log("worker error:", String(err && err.stack ? err.stack : err));
      return jsonResponse({ error: "server error" }, 500);
    }
  },
};
