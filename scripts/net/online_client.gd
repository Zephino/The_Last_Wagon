class_name OnlineClient
extends Node
## Sends one JSON request to the Worker and reports back with `finished`.
## Add it to a screen, call get_json() or post_json(), and wait for the signal.
## Never holds any key: the Worker does all the checking and saving.

signal finished(ok: bool, reply: Dictionary, error: String)

const TIMEOUT_S := 12.0

var _request: HTTPRequest


func _ready() -> void:
	_request = HTTPRequest.new()
	_request.timeout = TIMEOUT_S
	_request.request_completed.connect(_on_done)
	add_child(_request)


func get_json(url: String) -> void:
	_send(url, HTTPClient.METHOD_GET, "")


func post_json(url: String, body: Dictionary) -> void:
	_send(url, HTTPClient.METHOD_POST, JSON.stringify(body))


func _send(url: String, method: HTTPClient.Method, body: String) -> void:
	if url.is_empty():
		finished.emit.call_deferred(false, {}, "Online features aren't set up yet.")
		return
	_request.cancel_request()
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	var err := _request.request(url, headers, method, body)
	if err != OK:
		finished.emit(false, {}, "Couldn't connect (%s)." % error_string(err))


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json := JSON.new()
	var reply: Dictionary = {}
	if json.parse(body.get_string_from_utf8()) == OK and json.data is Dictionary:
		reply = json.data
	if result != HTTPRequest.RESULT_SUCCESS:
		finished.emit(false, reply, "No connection to the online service. Try again later.")
	elif code == 503:
		finished.emit(false, reply, "This online feature isn't switched on yet. Please try again later.")
	elif code < 200 or code >= 300:
		finished.emit(false, reply, str(reply.get("error", "The online service said no (HTTP %d)." % code)))
	else:
		finished.emit(true, reply, "")
