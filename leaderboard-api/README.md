# The Last Wagon online services

A tiny free **Cloudflare Worker** (an always-on mini web service) that runs
the game's online features:

- **Leaderboard:** the best 100 trips, shown in the game from the title screen.
- **Suggestions:** players send ideas from the title screen; each becomes a
  GitHub Issue on Zephino/The_Last_Wagon.

```
Game --POST trip--> Worker (checks it) --> Workers KV (fast copy)
                                       \-> GitHub: leaderboard.json on the `data` branch
Game <--GET board-- Worker
Game --POST suggestion--> Worker (checks it) --> GitHub Issue
```

- The game **never holds a GitHub key**. The key lives only on Cloudflare as a
  secret, so players can't edit anything; they can only send a trip or a
  suggestion through the Worker, which refuses anything malformed or impossible.
- Each trip keeps: name, route, whether it reached the end, stops reached,
  days, survivors standing, miles, the apocalypse, the game version, and the
  date (set by the Worker). Ranking: reached the end first, then most stops,
  then fewest days, then most survivors.
- The board on GitHub (after the first score):
  https://github.com/Zephino/The_Last_Wagon/blob/data/leaderboard.json

## One-time setup (owner only, on your PC)

You need: [Node.js LTS](https://nodejs.org/), your Cloudflare account, and a
GitHub token. **Never paste the token into a chat**; only into the setup app.

The storage (KV namespace `6ef4a5a8a8234494b84742cd4b044a0e`) is already in
`wrangler.toml`, so the setup app skips creating it.

1. **GitHub token.** Open https://github.com/settings/personal-access-tokens/new
   - Token name: `the-last-wagon-online`; Expiration: 1 year (set a reminder).
   - Repository access: **Only select repositories** -> `Zephino/The_Last_Wagon`.
   - Repository permissions -> **Contents: Read and write** and
     **Issues: Read and write**. Nothing else.
   - Generate, and copy it.
2. **Run the setup app.** Pull the latest `main` first, then double-click
   `leaderboard-api/Setup-Leaderboard.bat` (Windows) or run
   `bash setup-leaderboard.sh` (Mac/Linux). It installs the tools, logs you
   into Cloudflare in your browser, stores the token as a Cloudflare secret,
   deploys the Worker, and writes the Worker's address into
   `scripts/net/online_config.gd`.
   - If it says you need a **workers.dev subdomain**: pick any name on the
     page that opens, then click **5. Retry deploy only**.
3. **Push** the changed `scripts/net/online_config.gd` to `main` (or tell
   Claude the Worker address and it will). The web game rebuilds itself.
4. Check it: open `<your worker address>/leaderboard` in a browser; you
   should see `{"_about": ..., "entries": []}`. Open
   `<your worker address>/suggestions`; you should see `{"accepting":true}`.

## Updating the Worker later

When Claude changes files in `leaderboard-api/src/`, run the setup app again
and click **5. Retry deploy only** (or run `npx wrangler deploy` in this
folder). Your token and storage stay as they are.

## Protecting the `data` branch (recommended)

GitHub -> The_Last_Wagon -> **Settings -> Rules -> Rulesets -> New ruleset ->
New branch ruleset**
- Name: `data branch`; Enforcement: **Active**
- Target branches -> **Add target -> Include by pattern** -> `data`
- Tick **Restrict deletions** and **Block force pushes**. Leave the rest off
  (turning on "Restrict updates" would also block the Worker).
- **Create**.

## If the token expires

Make a new one (step 1), then in this folder run
`npx wrangler secret put GITHUB_TOKEN` and paste it there. No game change needed.

## Honest limits

Scores come from players' browsers, so a determined cheater could fake one.
The Worker refuses impossible trips (more miles than possible in the days,
more survivors than the party, "finished" without reaching the end), double
submissions, and more than 3 scores a minute from one address. Suggestions are
limited to 3 per player and 40 in total per day. To remove a bad score, ask
Claude.

## Tests

```bash
npm test
```
