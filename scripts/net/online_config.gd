class_name OnlineConfig
extends RefCounted
## Where the online services live (see leaderboard-api/README.md).
## The Worker updates itself from GitHub, so this address only changes if the
## Worker is renamed. Empty means "not set up": online features say so politely.

## The Cloudflare Worker's address only (no path, no trailing slash).
const API_BASE_URL := "https://the-last-wagon.thebotcoder.workers.dev"

## For testing against a Worker running on this computer (`npx wrangler dev`):
## run the game with `-- --api=http://127.0.0.1:8787`.
static var base_override: String = ""


static func api_base() -> String:
	if base_override == "":
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--api="):
				base_override = arg.trim_prefix("--api=")
	return (base_override if base_override != "" else API_BASE_URL).strip_edges().trim_suffix("/")


static func is_set_up() -> bool:
	return not api_base().is_empty()


static func leaderboard_url() -> String:
	return "" if not is_set_up() else api_base() + "/leaderboard"


static func suggestion_url() -> String:
	return "" if not is_set_up() else api_base() + "/suggestions"


## Online progress by private sync code (leaderboard-api/src/cloud.js).
static func cloud_url() -> String:
	return "" if not is_set_up() else api_base() + "/cloud/save"


## Sign in with Google (leaderboard-api/src/accounts.js), e.g. auth_url("start").
static func auth_url(path: String) -> String:
	return "" if not is_set_up() else api_base() + "/auth/" + path
