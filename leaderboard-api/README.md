# The Last Wagon online services

A tiny free **Cloudflare Worker** (an always-on mini web service) that runs
the game's online features:

- **Leaderboard:** the best 100 trips, shown in the game from the title screen.
- **Suggestions:** players send ideas from the title screen; each becomes a
  GitHub Issue on Zephino/The_Last_Wagon.
- **Online progress:** awards and totals follow the player between devices,
  by private sync code or Sign in with Google (`/cloud/save`, `/auth/*`).
- **Privacy policy:** `/privacy` (needed for Google sign-in).

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

## Online progress (sync codes)

Works as soon as the Worker is deployed, with nothing to set up: each
player's progress sits in its own **Durable Object** (`SaveVault`), named by
a scrambled form of their private sync code. `wrangler.toml` declares the
Durable Objects, so the automatic deploy creates them. They're on
Cloudflare's free plan. If a deploy ever fails with a message about Durable
Objects or migrations, open **Workers & Pages -> the-last-wagon ->
Deployments**, copy the red message, and send it to Claude.

## Sign in with Google (owner setup, about 15 minutes, free)

Settings -> Online progress -> **Sign in with Google** only works after these
steps. The **Client ID** and **Client secret** go into Cloudflare as
secrets, never into the repo or a chat.

1. Go to **https://console.cloud.google.com** and sign in.
2. At the top, click the project picker -> **New project** -> name it
   `The Last Wagon` -> **Create**. Make sure it's selected at the top.
3. Search for **Google Auth Platform** (or menu -> APIs & Services -> OAuth
   consent screen) -> **Get started**:
   - App name: `The Last Wagon`; User support email: your email -> Next.
   - Audience: **External** -> Next. Contact email: your email -> Next.
   - Agree to the policy -> **Create**.
   - Don't upload a logo (that starts a slow review; the game doesn't need one).
4. Google Auth Platform -> **Clients** -> **Create client**:
   - Application type: **Web application**; Name: `The Last Wagon Worker`.
   - **Authorized redirect URIs** -> Add URI:
     `https://the-last-wagon.thebotcoder.workers.dev/auth/callback`
   - **Create**. A box shows the **Client ID** and **Client secret**. Keep
     this tab open for step 6.
5. Google Auth Platform -> **Branding**: Application home page
   `https://zephino.github.io/The_Last_Wagon/`; privacy policy link
   `https://the-last-wagon.thebotcoder.workers.dev/privacy`; authorized
   domains `thebotcoder.workers.dev` and `zephino.github.io` -> Save. Then
   **Audience** -> **Publish app** -> Confirm. (Until you do, only "test users"
   you list there can sign in.) The game only asks for Google's basic sign-in
   (openid and email), so Google doesn't need to review it.
6. Cloudflare dashboard -> **Workers & Pages** -> **the-last-wagon** ->
   **Settings** -> **Variables and Secrets** -> **Add**:
   - Type **Secret**, Name `GOOGLE_CLIENT_ID`, Value: the Client ID -> add.
   - Type **Secret**, Name `GOOGLE_CLIENT_SECRET`, Value: the Client secret -> add.
   - **Deploy** (or Save). Secrets stay when the Worker updates from GitHub.
7. Test: open the game -> Settings -> **Sign in with Google**. A Google page
   opens; sign in; come back to the game. It should say "Signed in as ...".

The privacy page lists `thebotcoder@gmail.com` as the contact for deleting
data (the same as Mythriven's). Change `CONTACT` in `src/privacy.js` if you
want a different one.

## Updating the Worker later

The Worker is connected to GitHub in Cloudflare, so it redeploys itself
whenever `leaderboard-api/` changes on `main`. (Without that connection: run
the setup app again and click **5. Retry deploy only**, or run
`npx wrangler deploy` in this folder.) Your secrets and storage stay as they are.

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

## Security

Every request is checked against a strict shape before it's used: trips
(`board.js`), suggestions (`suggestions.js`), online progress (`cloud.js`,
rebuilt from known fields only) and sign-in (`accounts.js`). There is no SQL:
storage is Workers KV, Durable Objects and the GitHub API. **If a SQL database
is ever added, use bound parameters only.** Hostile-input tests are in
`test/security.test.js`. See also [`../SECURITY.md`](../SECURITY.md).

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
