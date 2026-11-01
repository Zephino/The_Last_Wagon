# Changelog

## Version 00.01.10
Date: 11/01/2026
Time: 1:45 AM

### Changes
- Road choice events: 2-3 times per stretch the trip stops for an event with 2-3 choices (15 events, such as a stranger, a trading convoy, a detour sign, a toll booth or a storm). Outcomes are random; some choices need a certain survivor or supply.
- Secrets: 3 rare road events (a radio signal, a bunker hatch, an ice cream truck), and hidden stashes in about half the scavenging levels (faint ledges up to a golden crate with a big haul).
- Awards (17): achievements and secrets, kept between trips (the game is a roguelike: no saving mid-trip). Each award unlocks something: a route, a survivor, a starting perk or a car color. A pop-up shows when you earn one.
- The other four routes are now playable (Maine to California, Maine to Oregon, Oregon to Florida, Florida to California), each locked until you finish the one before.
- New survivors: Cook (party eats 40% less) and Thief (extra money), unlocked by awards.
- New Prepare screen: pick 4 survivors, a starting perk and a car color before each trip. Choices are remembered.
- New Awards screen (title and end screens) with totals across all trips.
- The leaderboard records and shows the perk used. The Worker accepts it (older games still work).
- Progress is saved on this device (`user://progress.json`).
- Smoke test checks routes, awards, unlocks, perks, the Cook, every road event and outcome, the event pop-up, hidden stashes and the new screens. A physics test confirmed survivors can climb the stash ledges.

### Reason
The owner chose "deeper trip" with road choice events (often), and asked for a roguelike with awards for secrets that unlock survivors, perks, car colors and routes. Online sync of progress comes in the next round.

## Version 00.01.09
Date: 11/01/2026
Time: 1:25 AM

### Changes
- New Settings screen (Settings button on the title screen) with:
  - Fullscreen on/off.
  - Install app: installs the web game like an app (Chrome/Edge show their install box; iPhone/iPad get Add to Home Screen steps). Shows "Installed" once it is.
  - Update app: clears the saved copy of the game and reloads the newest version.
  - On PC, Install and Update stay visible and say they're only needed in the web version.
- The web game is now an installable app (export preset), with a pixel-art car icon (`icons/`, also the project icon).
- Added `web/update.js` (from Mythriven/Wave Defence): for 30 seconds after opening, the game checks for a newer version and switches to it, and every game file is loaded for the matching version.
- The web build writes the version into the page and checks the app files are there. The smoke test checks the Settings screen.
- README explains installing and updating.

### Reason
The owner asked for a way in Settings to install the game and to update it.

## Version 00.01.08
Date: 11/01/2026
Time: 1:19 AM

### Changes
- Added a Quit button to the title screen, next to Leaderboard and Suggest an idea. On PC it closes the game. In a web browser, which can't close its own tab, it shows "To quit, just close this browser tab."
- The smoke test checks the Quit button is there.

### Reason
The owner asked for a Quit button on the main menu, visible in the browser too.

## Version 00.01.07
Date: 11/01/2026
Time: 1:11 AM

### Changes
- Added `leaderboard-api/`: a Cloudflare Worker (adapted from Mythriven's) for the shared leaderboard and player suggestions, with tests, a setup app and a setup guide. The leaderboard keeps the best 100 trips on the `data` branch; suggestions become GitHub Issues.
- End screen: type a name (remembered for next time) and press Submit to send the trip to the leaderboard.
- New Leaderboard screen (from the title and end screens) showing the top 15 trips per route.
- New "Suggest an idea" form on the title screen.
- The game talks to the Worker at `https://the-last-wagon.thebotcoder.workers.dev` (`scripts/net/online_config.gd`) and explains politely when it can't reach it.
- The GitHub web build now also runs the Worker's tests. The smoke test checks the leaderboard entry, the new screens and the suggestion form.
- README explains the leaderboard and suggestions. Windows setup scripts keep Windows line endings.

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
