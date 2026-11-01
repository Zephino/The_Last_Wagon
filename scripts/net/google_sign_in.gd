class_name GoogleSignIn
extends Node
## Sign in with Google (adapted from Mythriven; leaderboard-api/src/accounts.js).
## The game asks the Worker for a sign-in page, opens it in the browser, and
## asks every few seconds until the player has signed in there. The Worker
## then hands over the account's sync code, and CloudSync links to it (this
## device's progress is combined with the account's, so nothing is lost).
## A device that already had a code brings it to a brand-new account.
## Google's email is kept only on this device, to show which account is used.

signal changed

const POLL_S := 2.0
const TIMEOUT_S := 600.0

## "idle", "starting", "waiting" (the browser page is open) or "done".
var state := "idle"
## Something to tell the player ("" when all is well).
var message := ""
## The sign-in page, kept so Settings can offer to open it again (pop-up blockers).
var page_url := ""

var _http: HTTPRequest
var _login := ""
var _poll_in := -1.0
var _left := 0.0


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	_http.request_completed.connect(_on_reply)
	add_child(_http)


func start() -> void:
	if OnlineConfig.auth_url("start").is_empty() or state == "starting" or state == "waiting":
		return
	message = ""
	state = "starting"
	changed.emit()
	var body := JSON.stringify({"code": CloudSync.code()})
	if _http.request(OnlineConfig.auth_url("start"), PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, body) != OK:
		_stop("Couldn't connect. Try again later.")


func cancel() -> void:
	_stop("")


func _process(delta: float) -> void:
	if state != "waiting":
		return
	_left -= delta
	if _left <= 0.0:
		_stop("Sign-in took too long. Try again.")
		return
	if _poll_in < 0.0:
		return
	_poll_in -= delta
	if _poll_in <= 0.0:
		_poll_in = -1.0
		if _http.request(OnlineConfig.auth_url("poll") + "?login=" + _login) != OK:
			_poll_in = POLL_S


func _on_reply(result: int, http_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json := JSON.new()
	var reply: Dictionary = {}
	if result == HTTPRequest.RESULT_SUCCESS and json.parse(body.get_string_from_utf8()) == OK and json.data is Dictionary:
		reply = json.data
	if state == "starting":
		if http_code == 503:
			_stop("Sign in with Google isn't set up yet. You can use a sync code instead.")
		elif http_code != 200 or str(reply.get("login", "")) == "":
			_stop("Couldn't connect. Try again later.")
		else:
			_login = str(reply["login"])
			page_url = str(reply.get("url", ""))
			state = "waiting"
			_left = TIMEOUT_S
			_poll_in = POLL_S
			changed.emit()
			open_page()
		return
	if state != "waiting":
		return
	_poll_in = POLL_S
	if http_code != 200:
		return
	match str(reply.get("state", "")):
		"done":
			_finish(str(reply.get("code", "")), str(reply.get("email", "")))
		"cancelled":
			_stop("Sign-in was cancelled.")
		"expired":
			_stop("Sign-in took too long. Try again.")


## Opens the sign-in page (a new tab on the web). Settings can call it again
## if the browser blocked the first try.
func open_page() -> void:
	if page_url.is_empty():
		return
	if OS.has_feature("web"):
		var opened: Variant = JavaScriptBridge.eval("!!window.open(%s, '_blank')" % JSON.stringify(page_url), true)
		if not bool(opened):
			message = "Your browser blocked the sign-in page. Press Open sign-in page."
			changed.emit()
		return
	OS.shell_open(page_url)


func _finish(account_code: String, account_email: String) -> void:
	if CloudSync.normalize(account_code).is_empty():
		_stop("Something went wrong. Try again.")
		return
	CloudSync.link(CloudSync.normalize(account_code), account_email)
	state = "done"
	message = ""
	page_url = ""
	changed.emit()


func _stop(reason: String) -> void:
	_http.cancel_request()
	state = "idle"
	message = reason
	_login = ""
	_poll_in = -1.0
	page_url = ""
	changed.emit()
