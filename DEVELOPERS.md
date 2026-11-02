# The Last Wagon: developer notes

How the project is built, tested and published. For how to **play** the game,
see [`README.md`](README.md). Project rules for AI helpers are in
[`CLAUDE.md`](CLAUDE.md) and `.cursor/rules/`.

## Open and run it in Godot

1. Install **Godot 4.7** (the standard version, not .NET) from https://godotengine.org/download
2. Open Godot, click **Import**, and pick the `project.godot` file in this folder.
3. Press **F5** (or the ▶ Play button at the top right).

## The web build

The game is published at **https://zephino.github.io/The_Last_Wagon/**.

Every push to `main` rebuilds this automatically (see
`.github/workflows/web.yml`): it runs the smoke test, builds the web version and
publishes it, usually within a few minutes. If the smoke test fails, the old
version stays up. GitHub's Settings → Pages → Source must be **GitHub Actions**.

### Installable app and updates

The web export is an installable app (progressive web app, see
`export_presets.cfg`). For 30 seconds after opening, the game checks for a
newer version online and switches to it (`web/update.js`, copied into the
build by the web workflow, which also writes the version into the page).

## Automated checks

Plays every screen of the core loop headless and checks the rules:

```bash
godot --headless --path . -s res://scripts/tests/smoke_test.gd
```

It prints `SMOKE TEST PASSED` and exits with code 0 when everything works.
The Worker has its own tests: `cd leaderboard-api && npm test`.

Before pushing, run the Godot import (`godot --headless --import --path .`,
no script errors) and the smoke test. The web workflow runs both, plus the
Worker tests, before publishing.

## Project layout

| Folder | What's inside |
|---|---|
| `scenes/` | One small scene per screen (title, town, map, road, scavenge, end) |
| `scripts/core/` | Autoloads (`Trip` run state, `Controls` input, `Mobile` phone support), touch controls, pause menu, phone typing, input safety, pixel art, UI helpers, backdrop |
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

## Online services

The leaderboard, suggestions, online progress and Google sign-in run on a
Cloudflare Worker in `leaderboard-api/`. Setup, updating and secrets are in
[`leaderboard-api/README.md`](leaderboard-api/README.md). The game's Worker
address is in `scripts/net/online_config.gd`.

## Security

Every input, and what checks it, is listed in [`SECURITY.md`](SECURITY.md).
There's no SQL database anywhere; if one is ever added, use parameterized
queries only.

## Phone support

`scripts/core/mobile.gd` (autoload `Mobile`) detects phones, decides when touch
controls show, keeps screens clear of notches and shows the turn-sideways
message. Touch controls are `scripts/core/touch_controls.gd`, phone typing is
`scripts/core/web_text_input.gd`, and the pause menu is
`scripts/core/pause_menu.gd`. The smoke test drives them with simulated touches.

## Coming next

- Online co-op (a friend plays one of your survivors), reusing the 6-digit-code
  lobby from FindGame/Mythriven.
- Sound and music, real (hand-made) pixel art and animations, a PC download.

## Versions and changes

The version lives in [`VERSION`](VERSION) and `config/version` in
`project.godot` (the smoke test checks they match). Every change gets one
entry at the top of [`CHANGELOG.md`](CHANGELOG.md).
