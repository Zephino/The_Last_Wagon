# Changelog

## Version 00.01.15
Date: 11/01/2026
Time: 1:28 PM

### Changes
- Phones and tablets are now fully playable:
  - Touch controls on the road and in levels: a floating joystick (touch and drag anywhere on the left half: move, speed up / brake when driving, climb ladders) and buttons on the right that show only when they do something (JUMP, SHOOT, WEAPON, SWAP, USE).
  - Touch controls appear automatically on phones and tablets, and on computers once the screen is touched (they hide again when the keyboard or a controller is used). Settings and the pause menu have Touch controls: Auto / On / Off.
  - Pause menu (II button, Esc or Start) on the road and in levels: Resume, Leave level, Touch controls, Fullscreen, and Quit to title (asks first). Esc in a level now pauses instead of leaving straight away.
  - Typing on phones: tapping a text box opens the phone's keyboard (party names, leaderboard name, suggestions, sync code). What's typed is cleaned like normal typing.
  - Bigger text and buttons on phones, and screens kept clear of notches and rounded corners.
  - An upright phone shows "Turn your phone sideways" and the game waits; the installed app opens sideways.
  - The web page no longer zooms, scrolls or selects text when you touch the game.
  - The map's side panel and the Prepare screen scroll when they don't fit, perks are in two columns and car colors in rows.
- Smoke test now drives the game with simulated finger touches (joystick walking, JUMP, SHOOT, WEAPON, the II pause button, Leave level, USE to hotwire, the right buttons per mode), checks phone typing, the turn-sideways message, and that touch controls hide and show with keyboard and touch. Screens were checked at a phone size (844x390).

### Reason
The owner asked to make everything work on phones.

## Version 00.01.14
Date: 11/01/2026
Time: 7:02 AM

### Changes
- Input safety audit and fixes:
  - New shared cleaner `scripts/core/input_safety.gd`: removes control characters and invisible / right-to-left trick characters, keeps lengths in bounds, and checks ids, dates, numbers, email addresses and web addresses.
  - Party names typed in the store are cleaned (no markup or code punctuation, up to 14).
  - Suggestions are cleaned in the game before sending (the Worker already cleaned and escaped them).
  - Online progress: the Worker now accepts only the exact progress shape (known fields, id patterns, real dates, whole non-negative capped numbers, no `__proto__`-style keys) and stores a rebuilt copy, never the raw upload. The game also checks downloaded and saved progress: only known awards with real dates, and known totals within range.
  - Google sign-in: the game only opens our own Worker's sign-in page, and only plain email addresses are passed on and shown.
  - Leaderboard: names with invisible or right-to-left trick characters are now refused outright, and names are cleaned again before they're shown.
- SQL injection: there is no SQL database anywhere, so it isn't possible today. Added the rule "parameterized queries only, if SQL is ever added" to the code, both READMEs and a new `SECURITY.md`, which lists every input and what checks it.
- Tests: new Worker security tests (SQL text, script tags, control characters, huge/negative numbers, unknown fields, object-tampering keys, bad emails), and a smoke-test section that sends hostile input to every game-side input. They found and fixed two bugs: the "broken character" symbol slipped through the cleaner, and huge numbers wrapped around instead of being capped.

### Reason
The owner asked to make sure all user input is sanitized and protected from SQL injection.

## Version 00.01.13
Date: 11/01/2026
Time: 3:02 AM

### Changes
- Fixed: a road choice event could pop up in the middle of a jump over a flipped car. Continuing then dropped the car straight onto the wreck and hurt everyone. Events now wait until the car is on the ground with no wreck or enemy close by (in front or just behind), and the car keeps its speed after an event. The smoke test now checks this.

- Better levels, round A:
  - New enemy kinds next to the walker: Sprinter (fast, in pairs), Brute (slow, very tough), Spitter (keeps its distance and spits) and Leaper (jumps onto platforms and roofs). Tougher kinds appear as a trip goes on.
  - Weapons, found in crates (10%), hidden stashes and from bosses, shared by the party for the trip: Crowbar, Pistol, Shotgun, Rifle (goes through enemies), Flamethrower (burns fuel) and Nail Gun (uses scrap). Q/E or 1-6 switch weapons; Tab now switches survivors. An empty weapon falls back to the crowbar.
  - Bosses at the last scavenging stop of medium and long routes, one per apocalypse: The Big Rotten, the Glowmother, The Overseer and Patient Zero, each with its own attacks and a health bar. The exit opens once it's beaten, with a big haul and a weapon.
  - 4 boss awards, unlocking the Sawed-Off and Hunting Rifle perks (start with a shotgun or rifle) and the Chrome and Hazmat Yellow car colors.
  - Smoke test checks weapons and their supplies, every enemy kind (shooters spit, jumpers leap), and every boss (appears at the right stop, attacks, can be hit, opens the exit, earns its award). It found and fixed two bugs: picking up a weapon changed the one in hand, and The Overseer hovered out of reach.

- Better levels, round B:
  - Hazards: fire, spikes, toxic puddles (slow you), live wires that spark on and off, quicksand and swamp water (slow you).
  - Moving platforms: elevators beside tall buildings, sliders across wide pits, and platforms that shake and drop after you land on them (they come back).
  - Ladders up tall buildings and cliffs: hold up or down to climb, and you hop onto the roof at the top.
  - Indoor rooms with doors, loot and an enemy inside, and a roof you can climb onto.
  - Region pieces: subway trenches with live rails (Northeast), hay bales and barns (Midwest), cliffs with ladders (Mountains), dunes with quicksand (Desert), swamp water and boardwalks (South).
  - Smoke test now checks 120 random levels (every region, plus boss levels) can be crossed: every wide pit has jumpable stepping platforms or a mover, and every tall climb has a ladder. A physics test rides each piece for real: climbs a ladder onto a roof, rides an elevator and a slider, triggers a falling platform, walks through a room, and checks fire hurts and water slows. It found and fixed one bug: reaching the top of a ladder didn't let you step onto the roof.

### Reason
The owner reported the bug, and approved the fix together with the "Better levels" rounds A and B.

## Version 00.01.12
Date: 11/01/2026
Time: 2:16 AM

### Changes
- Nine routes in mixed lengths, all through real cities:
  - New: New York to Washington (short starter, open from the start), Chicago to New Orleans (short), Texas to Washington (medium), Seattle to Boston (long, across the cold north).
  - Longer: Maine to Florida (15 stops, was 11), Maine to California and Maine to Oregon (20, were 10), Oregon to Florida (18, was 10), Florida to California (15, was 9).
- Five regions (Northeast cities, Midwest plains, Mountains and Northwest, Desert Southwest, South), worked out from each city's map position. Each has its own scenery on the road, in stores and in scavenging levels (skylines, farms, snowy peaks and pines, mesas and cacti, cypress swamps), land colors, and dangers (more enemies, fewer or more wrecks, faster fuel use, store prices).
- 15 region-only road events (3 per region), such as a subway entrance, a tornado, a rockslide, a sandstorm and a gator on the road. About 60% of stretches include one.
- New awards: finishing the new routes unlocks the next route in the chain, plus two new car colors (Desert Tan, Frost Blue).
- Store prices now rise with progress along the route (up to +80%) instead of +8% per stop, so long routes stay affordable.
- The title screen lists routes in two columns with their length. The map shows the region and stop number. The leaderboard's route buttons wrap onto more lines.
- Smoke test checks every route (6-20 stops, believable distances, every city on the map), that each region is used, sample cities' regions, region events, and the new unlock chain.

### Reason
The owner asked to build out all the routes: make each feel different, make them longer (mixed lengths), and add more routes.

## Version 00.01.11
Date: 11/01/2026
Time: 1:54 AM

### Changes
- Online progress: awards and totals can follow you between devices. In Settings -> Online progress:
  - Create sync code (a private 12-letter code), Copy code, and Use code (type a code from another device).
  - Sign in with Google: devices signed in to the same Google account share progress. This needs the owner's one-time Google setup (steps in `leaderboard-api/README.md`).
  - Sync now and Stop syncing.
- Progress from two devices is combined: every award from both is kept and each total keeps the higher number. Syncs happen when the game opens, after each award, at the end of each trip, and on Sync now.
- Worker: added online progress (`/cloud/save`, one private store per scrambled code), Sign in with Google (`/auth/*`) and a privacy page (`/privacy`), adapted from Mythriven. These use free Cloudflare Durable Objects, declared in `wrangler.toml`. The Worker has 35 tests.
- Settings now has two columns: Game, and Online progress.
- Smoke test checks codes, merging and the new Settings section. An end-to-end test with the Worker's code showed two devices sharing progress both ways.

### Reason
Round 2 of the roguelike update: the owner asked for progress to be saved online too, with both a sync code and Google sign-in.

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
