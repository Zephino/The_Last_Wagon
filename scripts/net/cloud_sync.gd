extends Node
## Autoload "CloudSync". Keeps your progress (awards and totals) online so it
## follows you between devices (adapted from Mythriven's cloud saves).
## You're known only by a private 12-letter sync code: make one here, or type
## one from another device, or Sign in with Google (GoogleSignIn), which hands
## this device your account's code. Each sync downloads the online copy,
## combines it with this device's progress (Progress.merge: nothing is lost),
## and uploads the result. Syncs happen when the game opens, after an award,
## at the end of a trip, and from Settings.

signal status_changed

const CODE_ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LENGTH := 12
## The Worker refuses writes closer together than 5 s; automatic syncs wait longer.
const MIN_GAP_S := 30.0
const TIMEOUT_S := 15.0

## A short line for Settings ("" until something happens).
var status := ""
var google: GoogleSignIn

var _http: HTTPRequest
var _step := ""
var _wanted := false
var _since_push := MIN_GAP_S


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_S
	_http.request_completed.connect(_on_reply)
	add_child(_http)
	google = GoogleSignIn.new()
	add_child(google)
	Progress.award_earned.connect(func(_award: Dictionary) -> void: request_sync())
	if is_linked():
		request_sync(true)


func _process(delta: float) -> void:
	_since_push += delta
	if _wanted and _step == "" and _since_push >= MIN_GAP_S:
		_start_sync()


## The code without dashes or spaces, upper-case; "" if it isn't a valid code.
static func normalize(raw: String) -> String:
	var code := raw.replace("-", "").replace(" ", "").strip_edges().to_upper()
	if code.length() != CODE_LENGTH:
		return ""
	for letter: String in code:
		if not CODE_ALPHABET.contains(letter):
			return ""
	return code


## "ABCDEFGHJKLM" -> "ABCD-EFGH-JKLM", easier to read and type.
static func pretty(code: String) -> String:
	return "%s-%s-%s" % [code.substr(0, 4), code.substr(4, 4), code.substr(8, 4)]


static func new_code() -> String:
	var bytes := Crypto.new().generate_random_bytes(CODE_LENGTH)
	var code := ""
	for value: int in bytes:
		code += CODE_ALPHABET[value % CODE_ALPHABET.length()]
	return code


func code() -> String:
	return normalize(str(PlayerPrefs.get_value("sync_code", "")))


func email() -> String:
	return InputSafety.clean_email(PlayerPrefs.get_value("google_email", ""))


func is_linked() -> bool:
	return code() != ""


func create_code() -> void:
	link(new_code(), "")


## Uses a code from another device. Returns false if it isn't a valid code.
func use_code(raw: String) -> bool:
	var cleaned := normalize(raw)
	if cleaned.is_empty():
		return false
	link(cleaned, "")
	return true


## Links this device to a code (and, after Google sign-in, shows the email).
func link(new_code_value: String, account_email: String) -> void:
	PlayerPrefs.set_value("sync_code", new_code_value)
	PlayerPrefs.set_value("google_email", account_email)
	status = "Linked. Syncing..."
	status_changed.emit()
	request_sync(true)


## Stops syncing on this device. Progress stays here and online.
func stop_syncing() -> void:
	_http.cancel_request()
	_step = ""
	_wanted = false
	PlayerPrefs.set_value("sync_code", "")
	PlayerPrefs.set_value("google_email", "")
	status = "Stopped syncing on this device. Your progress is still saved here."
	status_changed.emit()


## Asks for a sync soon (now = as soon as possible, for button presses).
func request_sync(now := false) -> void:
	if not is_linked() or not OnlineConfig.is_set_up():
		return
	_wanted = true
	if now:
		_since_push = MIN_GAP_S


func _start_sync() -> void:
	_wanted = false
	_step = "download"
	status = "Syncing..."
	status_changed.emit()
	if _http.request(OnlineConfig.cloud_url(), _headers(), HTTPClient.METHOD_GET) != OK:
		_fail("Couldn't connect. Will try again later.")


func _upload() -> void:
	_step = "upload"
	_since_push = 0.0
	var body := JSON.stringify(Progress.to_save())
	if _http.request(OnlineConfig.cloud_url(), _headers(), HTTPClient.METHOD_PUT, body) != OK:
		_fail("Couldn't connect. Will try again later.")


func _headers() -> PackedStringArray:
	return PackedStringArray(["Content-Type: application/json", "Accept: application/json", "Authorization: Bearer " + code()])


func _on_reply(result: int, http_code: int, _headers_in: PackedStringArray, body: PackedByteArray) -> void:
	var json := JSON.new()
	var reply: Dictionary = {}
	if json.parse(body.get_string_from_utf8()) == OK and json.data is Dictionary:
		reply = json.data
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail("No connection. Will try again later.")
		return
	if http_code == 503:
		_fail("Online progress isn't switched on yet.")
		return
	if _step == "download":
		if http_code != 200:
			_fail("Sync failed (%d)." % http_code)
			return
		if reply.get("save") is Dictionary:
			Progress.merge(reply["save"])
		_upload()
		return
	if http_code == 429:
		# Too soon after the last upload: try again shortly.
		_step = ""
		_wanted = true
		status = "Waiting a moment to sync..."
		status_changed.emit()
		return
	if http_code != 200:
		_fail("Sync failed (%d)." % http_code)
		return
	_step = ""
	var time := Time.get_time_dict_from_system()
	status = "Synced at %02d:%02d." % [time["hour"], time["minute"]]
	status_changed.emit()


func _fail(message: String) -> void:
	_step = ""
	status = message
	status_changed.emit()
