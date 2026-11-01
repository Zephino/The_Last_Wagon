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

1. **Title:** choose a route. *New York to Washington* (short) and *Maine to
   Florida* (medium) are open; the other seven routes unlock with awards.
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

## Routes and regions

Nine routes in three lengths (short ~6-10 stops, medium ~15, long ~18-20),
all through real cities:

| Route | Length | How to unlock |
|---|---|---|
| New York to Washington | short | open |
| Maine to Florida | medium | open |
| Chicago to New Orleans | short | finish New York to Washington |
| Texas to Washington | medium | finish Chicago to New Orleans |
| Maine to California | long | finish any route |
| Maine to Oregon | long | finish Maine to California |
| Oregon to Florida | long | finish Maine to Oregon |
| Florida to California | medium | finish Oregon to Florida |
| Seattle to Boston | long | finish Florida to California |

Every stop belongs to one of five regions, worked out from where it is on the
map (`scripts/trip/regions.gd`). Each region has its own scenery, land
colors, road events and dangers:

| Region | Scenery | On the road |
|---|---|---|
| Northeast cities | ruined skylines | more enemies; pricier stores |
| Midwest plains | farms, silos, fences | fewer wrecks; cheaper stores |
| Mountains and Northwest | snowy peaks, pines | more wrecks; a little more fuel |
| Desert Southwest | mesas, cacti | fuel runs out faster; pricier stores |
| South: swamps and coast | cypress trees, stilt shacks | storms, gators, crawfish |

Store prices also climb the further along a route you are.

## Weapons, enemies and bosses

**Weapons** are found in crates, hidden stashes and from bosses. The party
shares them for the whole trip; they're lost when the trip ends.

| Weapon | Uses | Notes |
|---|---|---|
| Crowbar | nothing | melee; you always have it |
| Pistol | 1 ammo | you always start with it |
| Shotgun | 2 ammo | 5 pellets, short range |
| Rifle | 1 ammo | long range, goes through 3 enemies |
| Flamethrower | fuel | short-range flames (fuel for the car vs. your gun!) |
| Nail Gun | scrap (1 per 4 nails) | very fast |

When a weapon runs dry you switch to the crowbar automatically.

**Enemies** take their look from the apocalypse, and tougher kinds appear as
the trip goes on: walkers, Sprinters (fast, in pairs), Spitters (keep their
distance and spit), Leapers (jump onto platforms) and Brutes (slow and tough).

**Bosses** guard the last scavenging stop of medium and long routes, one per
apocalypse: The Big Rotten (zombies), the Glowmother (fallout), The Overseer
(aliens) and Patient Zero (plague). The exit stays shut until it's beaten.
Each boss gives a big haul, a weapon, and an award (the zombie and fallout
bosses unlock the Sawed-Off and Hunting Rifle perks).

## Level pieces

Scavenging levels are built from random pieces:
- **Hazards:** fire, spikes, toxic puddles (slow you), live wires (spark on and
  off), quicksand and swamp water (slow you down).
- **Moving platforms:** elevators up tall buildings, platforms that slide
  across wide pits, and platforms that drop soon after you land on them.
- **Ladders** up tall buildings and cliffs (hold up or down to climb; hold up
  at the top to hop onto the roof).
- **Indoor rooms** you walk into through doors, with loot inside and a roof
  to climb onto.
- **Region pieces:** subway trenches with live rails (Northeast), hay bales
  and barns (Midwest), cliffs with ladders (Mountains), dunes with quicksand
  (Desert), and swamp water with boardwalks (South).

## Roguelike: awards and unlocks

Every trip is a fresh run (no saving in the middle of a trip). What you keep
between trips are **awards**, shown on the title screen's **Awards** page.
Each award unlocks something for future trips:

- **Routes:** finishing a route opens the next one.
- **Survivors:** the Cook (party eats 40% less) and the Thief (extra money).
- **Starting perks:** extra money, fuel, medkits, ammo, or a beat-up car.
- **Car colors.**

Some awards are secrets (hidden stashes and rare road events) and show as
??? until found. The leaderboard shows which perk each trip used.

### Online progress

Progress is saved on your device, and can also follow you to other devices
(Settings -> **Online progress**):
- **Create sync code:** a private 12-letter code. On another device, type it
  under "Already have a code" and press **Use code**.
- **Sign in with Google:** every device signed in to the same Google account
  shares progress (needs the owner's one-time Google setup, see
  `leaderboard-api/README.md`).

When two devices both have progress, they're combined: every award from both
is kept, and each total keeps the higher number. It syncs when the game
opens, after each award, at the end of each trip, and with **Sync now**.

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
| Shoot / swing the held weapon | F, J or Ctrl | X |
| Switch weapon | Q / E, or 1-6 | LB / RB |
| Switch survivor | Tab | Y |
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
| `scripts/trip/` | Survivors, apocalypses, routes, regions, road events, flavor text |
| `scripts/meta/` | Awards and unlocks (`unlocks.gd`), and the `Progress` autoload that saves them |
| `scripts/screens/` | The code for each screen, plus the map painter |
| `scripts/road/` | Enemies on the road |
| `scripts/scavenge/` | Level generator, player, enemies, bosses, weapons and shots for scavenging levels |
| `scripts/net/` | Talking to the online services (leaderboard, suggestions, online progress, Google sign-in) |
| `scripts/tests/` | The smoke test |
| `web/` | `update.js`, copied into the web build to keep it up to date |
| `icons/` | The app icon (pixel-art car) at the sizes the installed app needs |
| `leaderboard-api/` | The Cloudflare Worker for the leaderboard and suggestions, with its own tests |

All art is placeholder pixel art drawn from code, so there are no image files yet.

## Coming next

- Online co-op (a friend plays one of your survivors), reusing the 6-digit-code
  lobby from FindGame/Mythriven.
- The other routes.

## Security

Everything players type, and everything the game receives from the internet,
is cleaned and checked on both the game side and the Worker side. There's no
SQL database anywhere, and if one is ever added it must use parameterized
queries. Details, and the tests that prove it, are in [`SECURITY.md`](SECURITY.md).

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

