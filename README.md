# The Last Wagon

An apocalyptic road-trip survival game. Pick a route across the USA, stock
up at the starting store, then travel stop to stop. Drive (or walk, until you
find a car), and stop in ruined cities to scavenge supplies in side-scrolling
shoot-and-loot levels. Every run rolls a random apocalypse: zombies, fallout,
aliens, a plague, or a mix of two.

Made with **Godot 4.7** (GL Compatibility renderer), so it runs on PC and in
web browsers. Phones come later.

## Play it on your computer

1. Install **Godot 4.7** (the standard version, not .NET) from https://godotengine.org/download
2. Open Godot, click **Import**, and pick the `project.godot` file in this folder.
3. Press **F5** (or the ▶ Play button at the top right).

## How a trip works

1. **Title:** choose a route. Only *Maine to Florida* is playable so far.
2. **Store (Portland, ME):** spend your $600 on food, fuel, ammo, medkits and scrap.
   You can rename your four survivors here. You start **without a car**.
3. **Map:** see where you are, heal or revive survivors with medkits, repair
   the car with scrap, pick who leads, then scavenge, shop or travel.
4. **Road:** drive or walk to the next stop.
   - In a car it drives itself until danger is close, then you take the wheel.
   - On foot you are slow, and you have to shoot enemies in your way. The first
     leg always has an abandoned car you can hotwire.
   - Running out of fuel, or wrecking the car, puts you back on foot.
5. **Scavenge:** a side-scrolling level. Open crates for supplies and reach the
   green EXIT sign. If a survivor goes down, the next one takes over.
6. You win by reaching Miami. You lose when everyone is down and no medkits are left.

Each day on the road, every survivor eats 2 lbs of food. No food means everyone gets hurt.

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

## Project layout

| Folder | What's inside |
|---|---|
| `scenes/` | One small scene per screen (title, town, map, road, scavenge, end) |
| `scripts/core/` | Autoloads (`Trip` run state, `Controls` input), pixel art, UI helpers, backdrop |
| `scripts/trip/` | Survivors, apocalypses, routes, flavor text |
| `scripts/screens/` | The code for each screen, plus the map painter |
| `scripts/road/` | Enemies on the road |
| `scripts/scavenge/` | Level generator, player and enemies for scavenging levels |
| `scripts/tests/` | The smoke test |

All art is placeholder pixel art drawn from code, so there are no image files yet.

## Coming next

- Online co-op (a friend plays one of your survivors), reusing the 6-digit-code
  lobby from FindGame/Mythriven.
- The other routes.
- A web build you can play in the browser.
