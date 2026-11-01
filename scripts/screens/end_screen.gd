extends Node2D
## End of a trip: you reached the finish, or everyone is down for good.
## The player can send the trip to the shared leaderboard under a name.

const MAX_NAME_LENGTH := 12

var _name_edit: LineEdit
var _submit: Button
var _status: Label
var _client: OnlineClient
var _sent := false


func _ready() -> void:
	var root := UiKit.make_layer(self)
	var background := ColorRect.new()
	background.color = Color("0c0a10")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var column := UiKit.vbox(6)
	UiKit.pin(column, root, Vector2(0.5, 0), Vector2(-200, 30), Vector2(400, 0))
	_add_summary(column)
	_add_submit_row(column)
	var buttons := UiKit.hbox(8)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_child(UiKit.button("Leaderboard", Trip.go.bind("leaderboard"), 13))
	buttons.add_child(UiKit.button("New trip", Trip.go.bind("title"), 13))
	column.add_child(buttons)
	_client = OnlineClient.new()
	_client.finished.connect(_on_sent)
	add_child(_client)


func _add_summary(column: VBoxContainer) -> void:
	var won := Trip.won
	var title := UiKit.label("YOU MADE IT" if won else "THE ROAD WINS", 30, UiKit.GOOD if won else UiKit.DANGER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var line := Flavor.pick(Flavor.WIN_LINES if won else Flavor.LOSE_LINES, Trip.rng)
	var flavor := UiKit.wrapped(line, 12, UiKit.TEXT, 400)
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(flavor)
	column.add_child(UiKit.label("Apocalypse: %s" % Trip.apocalypse.title(), 11, UiKit.DIM))
	column.add_child(UiKit.label("Stops reached: %d of %d    Days on the road: %d" % [
		Trip.stop_index, Trip.total_stops(), int(Trip.days) + 1], 11))
	column.add_child(UiKit.label("Miles traveled: %d    Survivors standing: %d of %d" % [
		Trip.miles_traveled, Trip.standing_count(), Trip.party.size()], 11))


func _add_submit_row(column: VBoxContainer) -> void:
	column.add_child(UiKit.label("Send this trip to the leaderboard:", 11, UiKit.ACCENT))
	var row := UiKit.hbox(6)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Your name"
	_name_edit.max_length = MAX_NAME_LENGTH
	_name_edit.text = str(PlayerPrefs.get_value("leaderboard_name", ""))
	_name_edit.custom_minimum_size = Vector2(200, 0)
	_name_edit.add_theme_font_size_override("font_size", 12)
	row.add_child(_name_edit)
	_submit = UiKit.button("Submit", _on_submit, 12)
	row.add_child(_submit)
	column.add_child(row)
	_status = UiKit.wrapped("Letters, numbers, spaces, - and _ only. Nothing is sent unless you press Submit.", 9, UiKit.DIM, 400)
	column.add_child(_status)


## Same rule as the Worker: letters, numbers, space, _ and -, up to 12.
static func clean_name(raw: String) -> String:
	var allowed := RegEx.new()
	allowed.compile("[A-Za-z0-9 _-]")
	var cleaned := ""
	for match_result: RegExMatch in allowed.search_all(raw):
		cleaned += match_result.get_string()
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	return cleaned.strip_edges().left(MAX_NAME_LENGTH).strip_edges()


func _on_submit() -> void:
	if _sent:
		return
	var player_name := clean_name(_name_edit.text)
	if player_name.is_empty():
		_status.text = "Type a name first."
		return
	_name_edit.text = player_name
	PlayerPrefs.set_value("leaderboard_name", player_name)
	_submit.disabled = true
	_status.text = "Sending..."
	_client.post_json(OnlineConfig.leaderboard_url(), Trip.score_entry(player_name))


func _on_sent(ok: bool, reply: Dictionary, error: String) -> void:
	if not ok:
		_submit.disabled = false
		_status.text = error
		return
	_sent = true
	if bool(reply.get("accepted", false)):
		_status.text = "Sent! Your trip is on the leaderboard."
	else:
		_status.text = "Sent, but it didn't make the top 100 (or it was already there)."
