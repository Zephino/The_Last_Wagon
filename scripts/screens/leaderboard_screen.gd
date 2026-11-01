extends Node2D
## The shared leaderboard: the best trips on a route, loaded from the Worker.
## Ranking: reached the end first, then most stops, then fewest days, then
## most survivors standing.

const SHOWN_ROWS := 15

var _route_id := ""
var _rows: VBoxContainer
var _status: Label
var _client: OnlineClient
var _entries: Array[Dictionary] = []


func _ready() -> void:
	_route_id = str(Trip.route.get("id", Routes.first_playable()["id"]))
	var root := UiKit.make_layer(self)
	var background := ColorRect.new()
	background.color = Color("0c0a10")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var column := UiKit.vbox(6)
	UiKit.pin(column, root, Vector2(0.5, 0), Vector2(-300, 16), Vector2(600, 0))
	var title := UiKit.label("LEADERBOARD", 26, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	column.add_child(_route_picker())
	_status = UiKit.label("Loading...", 11, UiKit.DIM)
	column.add_child(_status)
	_rows = UiKit.vbox(2)
	column.add_child(_rows)
	var back := UiKit.button("Back", Trip.go.bind("title"), 13)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size = Vector2(120, 0)
	column.add_child(back)
	_client = OnlineClient.new()
	_client.finished.connect(_on_loaded)
	add_child(_client)
	_client.get_json(OnlineConfig.leaderboard_url())


func _route_picker() -> HBoxContainer:
	var row := UiKit.hbox(6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for route: Dictionary in Routes.all():
		if not route["playable"]:
			continue
		var pick := UiKit.button(route["name"], _on_route.bind(str(route["id"])), 11)
		pick.toggle_mode = true
		pick.button_pressed = route["id"] == _route_id
		row.add_child(pick)
	return row


func _on_route(route_id: String) -> void:
	_route_id = route_id
	_show_rows()


func _on_loaded(ok: bool, reply: Dictionary, error: String) -> void:
	if not ok:
		_status.text = error
		return
	_entries.clear()
	var raw: Variant = reply.get("entries", [])
	if raw is Array:
		for row: Variant in raw:
			if row is Dictionary:
				_entries.append(row)
	_show_rows()


func _show_rows() -> void:
	UiKit.clear(_rows)
	var shown := 0
	for entry: Dictionary in _entries:
		if str(entry.get("route", "")) != _route_id:
			continue
		shown += 1
		_rows.add_child(_row(shown, entry))
		if shown >= SHOWN_ROWS:
			break
	_status.text = "No trips yet. Be the first!" if shown == 0 else "Top %d trips" % shown


func _row(rank: int, entry: Dictionary) -> HBoxContainer:
	var row := UiKit.hbox(8)
	var finished := bool(entry.get("finished", false))
	var color := UiKit.GOOD if finished else UiKit.TEXT
	row.add_child(_cell("%d." % rank, 30, UiKit.DIM))
	row.add_child(_cell(str(entry.get("name", "?")), 110, UiKit.ACCENT if rank <= 3 else UiKit.TEXT))
	var result := "Made it!" if finished else "Reached stop %d of %d" % [int(entry.get("stops", 0)), int(entry.get("total_stops", 0))]
	row.add_child(_cell(result, 140, color))
	row.add_child(_cell("%d days" % int(entry.get("days", 0)), 70, UiKit.TEXT))
	row.add_child(_cell("%d survivors" % int(entry.get("survivors", 0)), 90, UiKit.TEXT))
	row.add_child(_cell(str(entry.get("apocalypse", "")).replace("+", " + "), 120, UiKit.DIM))
	return row


func _cell(text: String, width: float, color: Color) -> Label:
	var cell := UiKit.label(text, 10, color)
	cell.custom_minimum_size = Vector2(width, 0)
	cell.clip_text = true
	return cell
