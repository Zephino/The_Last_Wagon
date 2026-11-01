/**
 * The privacy policy (GET /privacy), linked from Google's sign-in screen
 * (Google Auth Platform → Branding). Plain text about what the game and this
 * Worker keep; update it whenever that changes.
 */

const CONTACT = "thebotcoder@gmail.com";

const SECTIONS = [
  ["What The Last Wagon keeps", [
    "<b>Sign in with Google:</b> Google's account id for you, stored scrambled (hashed). Your Google email is passed straight to your own device so the game can show which account you're signed in with; the server doesn't keep it. The Last Wagon never asks Google for your real name.",
    "<b>Online progress:</b> your awards and running totals (trips, crates, enemies, stashes), stored under your account or your private sync code, so they can follow you between devices. Trips themselves are not saved.",
    "<b>Leaderboard:</b> the name you type (up to 12 characters) and your trip's result, shown publicly. Nothing is sent unless you press Submit.",
    "<b>Suggestions:</b> the text you send, posted anonymously as a GitHub issue on the game's repository, with the game version and broad device type (for example \"Desktop, Windows, Chrome\").",
  ]],
  ["What it doesn't do", [
    "No ads, no tracking, no analytics, and nothing is sold or shared with anyone.",
    "Your progress is also saved on your own device, and the game works without an account.",
  ]],
  ["Deleting your data", [
    `In the game, Settings → Online progress → Stop syncing stops syncing on that device. To have your online progress and account deleted from the server, email ${CONTACT}.`,
  ]],
  ["Where it's stored", [
    "On Cloudflare (Workers and Durable Objects), which runs the game's online features. The leaderboard is also kept on the game's GitHub repository.",
  ]],
];

export function privacyPage() {
  const body = SECTIONS.map(([title, items]) => `<h2>${title}</h2><ul>${items.map((i) => `<li>${i}</li>`).join("")}</ul>`).join("");
  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>The Last Wagon — Privacy policy</title><style>body{font-family:system-ui,sans-serif;background:#1b1622;color:#f2ead8;max-width:720px;
margin:0 auto;padding:16px;line-height:1.5}h1{font-size:1.6em}h2{font-size:1.15em;margin-top:1.5em}a{color:#e7c46a}</style></head>
<body><h1>The Last Wagon — Privacy policy</h1><p>Last updated November 1, 2026. The Last Wagon is a game made by one developer. This page says what it keeps about you.</p>
${body}<p><a href="https://zephino.github.io/The_Last_Wagon/">Play The Last Wagon</a></p></body></html>`;
  return new Response(html, { headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "public, max-age=3600" } });
}
