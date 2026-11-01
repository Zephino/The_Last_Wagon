# Changelog

## Version 00.01.07
Date: 11/01/2026
Time: 1:11 AM

### Changes
- Added `leaderboard-api/`: a Cloudflare Worker (adapted from Mythriven's) for the shared leaderboard and player suggestions, with tests, a setup app and a setup guide. The leaderboard keeps the best 100 trips on the `data` branch; suggestions become GitHub Issues.

### Reason
The owner asked for a leaderboard and in-game suggestions, like their other games.

## Version 00.01.06
Date: 11/01/2026
Time: 12:50 AM

### Changes
- Added a Web export preset (`export_presets.cfg`).
- Added `.github/workflows/web.yml`: on every push to `main` it checks for script errors, runs the smoke test, builds the web version and publishes it to https://zephino.github.io/The_Last_Wagon/. If a check fails, nothing is published.
- The title screen now credits the Godot Engine, as its MIT license asks.
- README explains how to play in the browser. CREDITS mentions the title-screen credit.

### Reason
The owner chose a web build next, so the game can be played and tested in a browser.

## Version 00.01.05
Date: 11/01/2026
Time: 12:43 AM

### Changes
- `CLAUDE.md` pushing rule: push only to `main`, never to session branches.
- Deleted the extra `claude/focused-johnson-n4yc19` branch from GitHub (all its work was already on `main`).

### Reason
The owner wants GitHub to keep only the `main` branch.

## Version 00.01.04
Date: 11/01/2026
Time: 12:42 AM

### Changes
- Added `LICENSE`: Copyright (c) 2026 Zephino, All Rights Reserved, with the same wording as Wave Defence and Mythriven.
- Added `CREDITS.md`, listing the Godot engine (MIT license) as the only outside tool, and stating that all code, art and text were made for this game.
- `README.md` now has "Copyright and credits" and "Version and changes" sections.

### Reason
The owner asked for the same copyright setup as their other games, plus a README and changelog.

## Version 00.01.03
Date: 11/01/2026
Time: 12:38 AM

### Changes
- Started the game in Godot 4.7 (GL Compatibility), with the first playable core loop for one route (Maine to Florida):
  - Title screen with route choice (the other four routes are listed as coming later).
  - Store screen used by the starting town and store towns: buy food, fuel, ammo, medkits and scrap, and rename the party.
  - Pixel-art USA map showing the route, with healing, reviving, car repair, choosing the leader, and travel.
  - Side-view road: the car drives itself until danger is close, then you steer, brake and jump wrecks. On foot you walk, shoot, and can hotwire abandoned cars. Running out of fuel or wrecking the car puts you back on foot.
  - Random side-scrolling scavenging levels with enemies, crates of supplies and an exit.
  - End screen for winning (reaching Miami) or losing (everyone down, no medkits).
- A random apocalypse each run (zombies, fallout, aliens, plague, or a mix of two) that sets the enemies and colors.
- Four survivors with roles (Scout, Gunner, Medic, Mechanic). Switch between them, and revive downed ones with medkits.
- Placeholder pixel art drawn from code (no image files yet).
- Keyboard and gamepad controls.
- A headless smoke test (`scripts/tests/smoke_test.gd`) that plays every screen.
- README with setup, controls and project layout. `CLAUDE.md` now lists the checks to run before pushing.

### Reason
The owner approved building the first playable version of The Last Wagon (single player; co-op comes next) and chose Godot over Unity, because Godot can be tested in these sessions, reuses the existing co-op code, and makes smaller web builds.

## Version 00.01.02
Date: 11/01/2026
Time: 12:06 AM

### Changes
- Added `.cursor/rules/think-before-acting.mdc`: ask questions until 95% sure, give a short summary and a 2-line plan, then wait for the owner's go-ahead before changing anything.

### Reason
The owner asked for this rule. `dependency.mdc` already referred to it by this filename, but the file was missing.

## Version 00.01.01
Date: 10/31/2026
Time: 11:38 PM

### Changes
- Added a "Pushing" owner rule to `CLAUDE.md`: finished work is always pushed to the `main` branch.

### Reason
The owner asked for all work to always be uploaded to `main`.

## Version 00.01.00
Date: 10/31/2026
Time: 11:37 PM

### Changes
- Added the general project rules from Wave Defence to `.cursor/rules/`: bug investigation, changelog, performance, dependencies, documentation, focused functions, data protection, and versioning.
- Added `CLAUDE.md` so Claude Code follows the same rules as Cursor.
- Added `VERSION` (starting at `00.01.00`) and this changelog, as the version and changelog rules require.

### Reason
Reuse Wave Defence's general working rules in The Last Wagon. Wave Defence-specific rules (retro music generation, Godot build and publishing steps) were left out.
