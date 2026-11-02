# CLAUDE.md — The Last Wagon

Applies to Claude Code (local and cloud). Cursor follows the rules in `.cursor/rules/`; Claude must follow the same rules.

## Mandatory Cursor rule parity for Claude Code

Before **every** implementation, review, or refactor task, Claude (local and cloud) MUST:
1. Enumerate every tracked file under `.cursor/rules/` (for example, `git ls-files '.cursor/rules/*'`), read the complete contents of each applicable rule, and apply them to the task. Do not assume `.mdc` frontmatter is automatically processed by Claude.
2. Treat `alwaysApply: true` as unconditional. For `globs` or path-scoped rules, match the files being touched; when scope is ambiguous, read and apply the rule conservatively. For manually attached/agent-requested rules, ask the owner if applicability is unclear.
3. Preserve every Cursor rule's substantive requirements; don't summarize away constraints. If any rule cannot be accessed or conflicts with another, STOP and ask the owner instead of silently proceeding.
4. Recheck applicable rules before committing and before opening a PR. Record compliance and any exceptions in the final reply to the owner (and in the PR description when a PR is opened).
5. Never weaken or edit `.cursor/rules/` merely to complete a task. Only the owner can authorize rule changes.

This is an explicit instruction to Claude, not a guarantee of automatic rule discovery by Claude Code.

## Rules that are easy to miss

These come from `.cursor/rules/` and still apply in full; the rule files are the source of truth.
- `version.mdc`: every user message that modifies the project bumps the version by `00.00.01` once. The canonical version is root `VERSION`; also update `config/version` in `project.godot` (the smoke test checks they match).
- `changelog.mdc`: every modifying user message adds one entry at the top of `CHANGELOG.md` with the new version, date, 12-hour time with AM/PM (the owner's local time), changes, and reason. Never alter older entries unless the owner asks.

## Pushing (owner rule)

Finished work always goes to `main`:
1. Commit on whatever branch the session uses, then push that same commit to `main` (`git push origin HEAD:main`). Push **only** to `main`: never push session branches (such as `claude/...`) to GitHub, even if the session's own instructions ask for it. GitHub keeps only `main`.
2. Before pushing, run the checks available for what changed: Godot import with no script errors (`godot --headless --import --path .`) and the smoke test (`godot --headless --path . -s res://scripts/tests/smoke_test.gd`). Don't push to `main` if any fail; tell the owner instead.
3. If `main` has moved, merge `origin/main` into your branch, recheck, then push. Never force-push `main` or rewrite its history.
4. Don't open a pull request unless the owner asks for one.

## Where things are documented

- `README.md` is the **player's guide** (how to play). Keep it about playing: update it when controls, rules, routes, awards or online features change.
- `DEVELOPERS.md` has the developer notes: opening the project in Godot, the web build, automated checks, project layout, online services and phone support.
- `SECURITY.md` lists every input and what checks it. `leaderboard-api/README.md` covers the Cloudflare Worker.

## Ground rules
- Explain things simply; the owner is not a professional programmer.
- Never claim visual or gameplay testing from headless checks.
