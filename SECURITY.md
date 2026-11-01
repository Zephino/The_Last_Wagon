# Security

How The Last Wagon handles anything a player types or the internet sends.
Keep this up to date when adding new input (see `.cursor/rules/protect-data.mdc`).

## No SQL, and how to keep it safe

There is **no SQL database** in the game or its Worker. Storage is Workers KV,
Durable Objects (`get`/`put` only) and the GitHub API, which never run text as
a query, so SQL injection isn't possible today.

**If a SQL database is ever added, use bound (parameterized) queries only.**
Filtering or escaping text is not SQL injection prevention on its own.

## Every input, and what checks it

| Input | Game side | Worker side |
|---|---|---|
| Leaderboard name | letters, numbers, space, `-`, `_`, up to 12 (`end_screen.gd`) | the same, and names with code characters (`'` `;` `--` `<` `>` ...), control characters or invisible/right-to-left trick characters are refused (`board.js`) |
| Leaderboard trip | built by the game | every field checked: ids by pattern, numbers whole and in range, impossible trips refused, unknown fields dropped (`board.js`) |
| Suggestion | hidden characters removed, lengths checked (`suggestion_form.gd`) | hidden characters removed, category from a fixed list, lengths, link limit, spam trap, daily limits, HTML/Markdown escaped and `@` mentions disabled before posting to GitHub, IP addresses never stored (`suggestions.js`) |
| Party names (store) | hidden characters, markup and code punctuation removed, up to 14 (`InputSafety.clean_name`) | never sent |
| Sync code | 12 characters from a fixed alphabet | the same; stored only as a scrambled hash (`cloud.js`) |
| Online progress upload | only known awards and totals are sent | rebuilt from a strict shape: known fields only, ids by pattern, real dates, whole non-negative capped numbers, size limits, object-tampering keys (`__proto__` ...) refused (`cloud.js`) |
| Progress downloaded or loaded from disk | only known awards with real dates, only known totals, kept in range (`Progress.merge`) | - |
| Sign-in page address | only opened if it's our own Worker's page with a plain login id (`google_sign_in.gd`) | login ids by pattern (`accounts.js`) |
| Google email | only a plain email address is shown | only a plain email address is passed on, never stored (`accounts.js`) |
| Leaderboard rows shown in game | names cleaned again before display | - |

The shared game-side cleaner is `scripts/core/input_safety.gd`. Godot `Label`s
show text as plain text (no markup), and player text is never used as a
format string or run as code.

## Tests

- Worker: `cd leaderboard-api && npm test` (`test/security.test.js` sends SQL,
  script tags, control characters, huge/negative numbers, unknown fields and
  object-tampering keys).
- Game: `godot --headless --path . -s res://scripts/tests/smoke_test.gd`
  (`_check_input_safety` does the same for every game-side input).

## Reporting a problem

Use the game's Suggest an idea form, or contact the owner via the GitHub
profile for Zephino/The_Last_Wagon.
