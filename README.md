# The Last Wagon

An apocalyptic road-trip survival game. Pick a route across the USA, stock
up at the starting store, then travel stop to stop. Drive (or walk, until you
find a car), and stop in ruined cities to scavenge supplies in side-scrolling
shoot-and-loot levels. Every run rolls a random apocalypse: zombies, fallout,
aliens, a plague, or a mix of two.

Made with **Godot 4.7** (GL Compatibility renderer), so it runs on PC and in
web browsers. Phones come later.

## Play it in your browser

**https://zephino.github.io/The_Last_Wagon/**

Every push to `main` rebuilds this automatically (see
`.github/workflows/web.yml`): it runs the smoke test, builds the web version and
publishes it, usually within a few minutes. If the smoke test fails, the old
version stays up. GitHub's Settings → Pages → Source must be **GitHub Actions**.

### Install it like an app, and updates

On the title screen, **Settings** has:
- **Fullscreen** on/off.
- **Install app:** in Chrome or Edge, installs the game with its own icon and
  window. On iPhone/iPad: Share, then Add to Home Screen.
- **Update app:** clears the saved copy and reloads the newest version.

The game also updates itself: for 30 seconds after opening, it checks for a
newer version online and switches to it (`web/update.js`).

## Play it on your computer

1. Install **Godot 4.7** (the standard version, not .NET) from https://godotengine.org/download
2. Open Godot, click **Import**, and pick the `project.godot` file in this folder.
3. Press **F5** (or the ▶ Play button at the top right).

## How a trip works

1. **Title:** choose a route. *Maine to Florida* is open; the other four
   routes unlock with awards.
2. **Prepare:** pick 4 survivors, a starting perk and a car color.
3. **Store (the starting town):** spend your $600 on food, fuel, ammo, medkits
   and scrap. You can rename your survivors here. You start **without a car**
   (unless you chose the Old Beater perk).
4. **Map:** see where you are, heal or revive survivors with medkits, repair
   the car with scrap, pick who leads, then scavenge, shop or travel.
5. **Road:** drive or walk to the next stop. Two or three times per stretch a
   **road event** stops you and asks what to do (help a stranger, trade with a
   convoy, take a detour...). Some choices need a certain survivor.
   - In a car it drives itself until danger is close, then you take the wheel.
   - On foot you are slow, and you have to shoot enemies in your way. The first
     leg always has an abandoned car you can hotwire.
   - Running out of fuel, or wrecking the car, puts you back on foot.
6. **Scavenge:** a side-scrolling level. Open crates for supplies and reach the
   green EXIT sign. If a survivor goes down, the next one takes over.
   About half the levels hide a **secret stash**: faint ledges climbing high
   above the street to a golden crate.
7. You win by reaching the last stop. You lose when everyone is down and no medkits are left.

Each day on the road, every survivor eats 2 lbs of food. No food means everyone gets hurt.

## Roguelike: awards and unlocks

Every trip is a fresh run (no saving in the middle of a trip). What you keep
between trips are **awards**, shown on the title screen's **Awards** page.
Each award unlocks something for future trips:

- **Routes:** finishing a route opens the next one.
- **Survivors:** the Cook (party eats 40% less) and the Thief (extra money).
- **Starting perks:** extra money, fuel, medkits, ammo, or a beat-up car.
- **Car colors.**

Some awards are secrets (hidden stashes and rare road events) and show as
??? until found. Progress is saved on this device for now; online sync comes
next. The leaderboard shows which perk each trip used.

## Leaderboard and suggestions

- **Leaderboard:** when a trip ends, type a name and press **Submit** to send
  it. The title screen's **Leaderboard** button shows the best trips. Ranking:
  reached the end first, then most stops, then fewest days, then most
  survivors standing.
- **Suggest an idea:** on the title screen. Each suggestion becomes a GitHub
  Issue on this repo, without needing a sign-in.

Both run on a small Cloudflare Worker in `leaderboard-api/` (setup steps in
`leaderboard-api/README.md`). The game never holds a GitHub key. Its address
is in `scripts/net/online_config.gd`.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move / steer | A D or ← → | Left stick / D-pad |
| Jump | Space, W or ↑ | A |
| Shoot (melee when out of ammo) | F, J or Ctrl | X |
| Switch survivor | Tab or Q | Y / RB |
| Hotwire a car | E | B |
| Leave a scavenging level | Esc | Start |

## The party

| Role | Perk |
|---|---|
| Scout | Runs faster, jumps higher, finds extra loot |
| Cook (unlockable) | The party eats 40% less food |
| Thief (unlockable) | Finds extra money in crates and events |
| Gunner | Double damage, shoots faster |
| Medic | Medkits heal and revive much more |
| Mechanic | Uses less fuel, better repairs, hotwires cars fast |

A downed survivor stays down until you use a medkit on them from the map.

## Automated check

Plays every screen of the core loop headless and checks the rules:

```bash
godot --headless --path . -s res://scripts/tests/smoke_test.gd
```

It prints `SMOKE TEST PASSED` and exits with code 0 when everything works.
The Worker has its own tests: `cd leaderboard-api && npm test`.

## Project layout

| Folder | What's inside |
|---|---|
| `scenes/` | One small scene per screen (title, town, map, road, scavenge, end) |
| `scripts/core/` | Autoloads (`Trip` run state, `Controls` input), pixel art, UI helpers, backdrop |
| `scripts/trip/` | Survivors, apocalypses, routes, road events, flavor text |
| `scripts/meta/` | Awards and unlocks (`unlocks.gd`), and the `Progress` autoload that saves them |
| `scripts/screens/` | The code for each screen, plus the map painter |
| `scripts/road/` | Enemies on the road |
| `scripts/scavenge/` | Level generator, player and enemies for scavenging levels |
| `scripts/net/` | Talking to the online services (leaderboard, suggestions) |
| `scripts/tests/` | The smoke test |
| `web/` | `update.js`, copied into the web build to keep it up to date |
| `icons/` | The app icon (pixel-art car) at the sizes the installed app needs |
| `leaderboard-api/` | The Cloudflare Worker for the leaderboard and suggestions, with its own tests |

All art is placeholder pixel art drawn from code, so there are no image files yet.

## Coming next

- Online co-op (a friend plays one of your survivors), reusing the 6-digit-code
  lobby from FindGame/Mythriven.
- The other routes.

## Copyright and credits

Copyright (c) 2026 Zephino. All Rights Reserved. See [`LICENSE`](LICENSE): you
may play official builds, but not copy, change, share or sell the game without
permission.

Outside tools (currently just the Godot engine, MIT license) are listed in
[`CREDITS.md`](CREDITS.md). Everything else (code, pixel art, names, events
and text) was made for this game.

## Version and changes

The current version is in [`VERSION`](VERSION) (also shown on the title
screen). Every change is listed in [`CHANGELOG.md`](CHANGELOG.md), newest first.

