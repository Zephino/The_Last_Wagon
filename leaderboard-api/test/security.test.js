import { test } from "node:test";
import assert from "node:assert/strict";
import { validateSave, MAX_STAT_VALUE } from "../src/cloud.js";
import { cleanEmail } from "../src/accounts.js";
import { validateScore } from "../src/board.js";
import { validateSuggestion } from "../src/suggestions.js";

const SQL = "'; DROP TABLE saves; --";
const SCRIPT = "<script>alert(1)</script>";
const good = { save_version: 1, awards: { first_steps: "2026-11-01T01:53:00" }, stats: { crates: 7 } };

test("a normal save is accepted and rebuilt", () => {
  const checked = validateSave(JSON.stringify(good));
  assert.deepEqual(checked.save, good);
  assert.equal(checked.text, JSON.stringify(good));
});

test("saves with unknown fields, odd ids or bad values are refused", () => {
  const bad = [
    { ...good, extra: "hi" },
    { ...good, save_version: "1" },
    { ...good, save_version: 1.5 },
    { ...good, awards: { [SQL]: "2026-11-01T01:53:00" } },
    { ...good, awards: { first_steps: SCRIPT } },
    { ...good, awards: { first_steps: 5 } },
    { ...good, awards: ["first_steps"] },
    { ...good, stats: { crates: -1 } },
    { ...good, stats: { crates: MAX_STAT_VALUE + 1 } },
    { ...good, stats: { crates: 1.5 } },
    { ...good, stats: { crates: "7" } },
    { ...good, stats: { "crates; DROP": 1 } },
  ];
  for (const save of bad) {
    assert.ok(validateSave(JSON.stringify(save)).error, JSON.stringify(save));
  }
});

test("object-tampering keys are refused", () => {
  for (const key of ["__proto__", "constructor", "prototype"]) {
    const text = `{"save_version":1,"awards":{},"stats":{"${key}":1}}`;
    assert.ok(validateSave(text).error, key);
  }
  const awardText = '{"save_version":1,"awards":{"__proto__":"2026-11-01T01:53:00"},"stats":{}}';
  assert.ok(validateSave(awardText).error);
});

test("too many entries are refused", () => {
  const stats = {};
  for (let i = 0; i < 40; i++) stats["s" + "a".repeat(i % 20) + "_" + String.fromCharCode(97 + (i % 26))] = 1;
  assert.ok(validateSave(JSON.stringify({ save_version: 1, awards: {}, stats })).error);
});

test("only plain email addresses are passed to the game", () => {
  assert.equal(cleanEmail("player@example.com"), "player@example.com");
  for (const bad of ["player@example.com<script>", "a b@c.com", "x\n@y.com", `"a"@b.com`, SQL, 42, "a@b", "x".repeat(130) + "@b.com"]) {
    assert.equal(cleanEmail(bad), "", String(bad));
  }
});

test("SQL-looking and script text never gets into a leaderboard name", () => {
  const trip = { name: "Priya", route: "maine_to_florida", finished: false, stops: 1, total_stops: 14,
    days: 2, survivors: 4, miles: 50, apocalypse: "zombies", version: "00.01.14" };
  for (const name of [SQL, SCRIPT, "Robert'); --", "a\u0000b", "x‮evil"]) {
    assert.equal(validateScore({ ...trip, name }).error, "invalid name", name);
  }
  assert.equal(validateScore({ ...trip, route: SQL }).error, "invalid route");
  assert.equal(validateScore({ ...trip, perk: SQL }).error, "invalid perk");
});

test("suggestion text keeps SQL-looking text as plain words and strips hidden characters", () => {
  const checked = validateSuggestion({ category: "gameplay", title: "Bad ‮idea\u0000 " + SQL,
    description: "Please add more trucks to the game.​ " + SQL, website: "" });
  assert.equal(checked.error, undefined);
  assert.ok(!checked.title.includes("‮") && !checked.title.includes("\u0000"));
  assert.ok(checked.title.includes("DROP TABLE"), "kept as harmless text");
});
