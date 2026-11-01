import { test } from "node:test";
import assert from "node:assert/strict";
import {
  addEntry, compareEntries, emptyBoard, isDuplicate, MAX_ENTRIES, normalizeBoard,
  qualifies, sanitizeName, validateScore,
} from "../src/board.js";
import worker from "../src/index.js";

const trip = {
  name: "Priya",
  route: "maine_to_florida",
  finished: true,
  stops: 10,
  total_stops: 10,
  days: 14,
  survivors: 3,
  miles: 1720,
  apocalypse: "zombies",
  version: "00.01.07",
};

test("accepts a normal finished trip and a normal lost trip", () => {
  assert.deepEqual(validateScore(trip).entry, trip);
  const lost = { ...trip, finished: false, stops: 4, survivors: 0, miles: 560, days: 9 };
  assert.equal(validateScore(lost).error, undefined);
});

test("refuses bad names, routes and apocalypses", () => {
  assert.equal(validateScore({ ...trip, name: "<script>" }).error, "invalid name");
  assert.equal(validateScore({ ...trip, name: "   " }).error, "invalid name");
  assert.equal(validateScore({ ...trip, route: "Maine to Florida" }).error, "invalid route");
  assert.equal(validateScore({ ...trip, apocalypse: "dragons" }).error, "invalid apocalypse");
  assert.equal(validateScore({ ...trip, apocalypse: "zombies+zombies" }).error, "invalid apocalypse");
  assert.equal(validateScore({ ...trip, apocalypse: "fallout+aliens" }).error, undefined);
  assert.equal(validateScore({ ...trip, version: "1.0" }).error, "invalid version");
});

test("refuses impossible trips", () => {
  assert.equal(validateScore({ ...trip, stops: 11 }).error, "invalid stops");
  assert.equal(validateScore({ ...trip, finished: false }).error, "invalid finished");
  assert.equal(validateScore({ ...trip, finished: "yes" }).error, "invalid finished");
  assert.equal(validateScore({ ...trip, survivors: 5 }).error, "invalid survivors");
  assert.equal(validateScore({ ...trip, survivors: 0 }).error, "invalid survivors");
  assert.equal(validateScore({ ...trip, days: 0 }).error, "invalid days");
  assert.equal(validateScore({ ...trip, days: 1 }).error, "invalid miles");
  assert.equal(validateScore({ ...trip, miles: 0 }).error, "invalid miles");
});

test("names are cleaned to letters, numbers, space, _ and -", () => {
  assert.equal(sanitizeName("  Big   Carl!! "), "Big Carl");
  assert.equal(sanitizeName("abcdefghijklmnop"), "abcdefghijkl");
});

test("ranks finished first, then stops, then fewest days, then survivors", () => {
  const finishedSlow = { ...trip, days: 30 };
  const finishedFast = { ...trip, days: 12 };
  const finishedFastMore = { ...trip, days: 12, survivors: 4 };
  const farLost = { ...trip, finished: false, stops: 9, survivors: 0 };
  const nearLost = { ...trip, finished: false, stops: 2, survivors: 0, miles: 300 };
  const sorted = [nearLost, finishedSlow, farLost, finishedFast, finishedFastMore].sort(compareEntries);
  assert.deepEqual(sorted, [finishedFastMore, finishedFast, finishedSlow, farLost, nearLost]);
});

test("spots the same trip sent twice", () => {
  assert.equal(isDuplicate([trip], { ...trip }), true);
  assert.equal(isDuplicate([trip], { ...trip, days: 15 }), false);
});

test("keeps only the best 100 trips", () => {
  let board = emptyBoard();
  for (let i = 0; i < MAX_ENTRIES; i++) {
    board = addEntry(board, { ...trip, name: "P" + i, days: 20 + i }, "2026-11-01T00:00:00.000Z");
  }
  assert.equal(board.entries.length, MAX_ENTRIES);
  assert.equal(qualifies(board, { ...trip, days: 500 }), false);
  assert.equal(qualifies(board, { ...trip, days: 5 }), true);
  const normalized = normalizeBoard({ entries: [...board.entries, { name: "<bad>" }] });
  assert.equal(normalized.entries.length, MAX_ENTRIES);
});

function kv() {
  const data = new Map();
  return {
    async get(key, options) {
      const value = data.get(key);
      if (value === undefined) return null;
      return options?.type === "json" ? JSON.parse(value) : value;
    },
    async put(key, value) { data.set(key, value); },
  };
}

test("the Worker saves a valid trip and serves it back", async () => {
  const env = { LEADERBOARD_KV: kv() };
  const post = await worker.fetch(new Request("https://w.example/leaderboard", {
    method: "POST",
    headers: { "Content-Type": "application/json", "CF-Connecting-IP": "1.2.3.4" },
    body: JSON.stringify(trip),
  }), env);
  assert.equal(post.status, 200);
  assert.equal((await post.json()).accepted, true);
  const get = await worker.fetch(new Request("https://w.example/leaderboard"), env);
  const board = await get.json();
  assert.equal(board.entries.length, 1);
  assert.equal(board.entries[0].name, "Priya");
  assert.match(board.entries[0].date, /^\d{4}-/);
});

test("the Worker refuses a bad trip and unknown paths", async () => {
  const env = { LEADERBOARD_KV: kv() };
  const bad = await worker.fetch(new Request("https://w.example/leaderboard", {
    method: "POST",
    body: JSON.stringify({ ...trip, survivors: 9 }),
  }), env);
  assert.equal(bad.status, 400);
  const missing = await worker.fetch(new Request("https://w.example/admin"), env);
  assert.equal(missing.status, 404);
});
