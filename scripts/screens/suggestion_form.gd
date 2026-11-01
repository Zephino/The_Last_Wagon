class_name SuggestionForm
extends CanvasLayer
## Anonymous player suggestions, opened from the title screen. Sent to the
## Worker, which turns each one into a GitHub Issue. No sign-in or email.
## Limits match the Worker (leaderboard-api/src/suggestions.js).

signal closed

const CATEGORIES: Array[String] = ["route", "survivor", "enemy", "vehicle", "event", "gameplay", "ui", "other"]
const CATEGORY_NAMES: Array[String] = ["A route", "Survivors", "Enemies", "Vehicles", "Road events", "Gameplay", "Menus and screens", "Something else"]
const MIN_TITLE := 5
const MAX_TITLE := 100
const MIN_DESCRIPTION := 20
const MAX_DESCRIPTION := 2000

var _category: OptionButton
var _title_edit: LineEdit
var _description: TextEdit
var _send: Button
var _status: Label
var _client: OnlineClient


func _ready() -> void:
	layer = 50
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.9)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := UiKit.panel(Vector2(440, 0))
	UiKit.pin(panel, root, Vector2(0.5, 0), Vector2(-220, 8))
	var column := UiKit.vbox(5)
	panel.add_child(column)
	column.add_child(UiKit.label("Suggest an idea", 18, UiKit.ACCENT))
	column.add_child(UiKit.wrapped("Ideas go straight to the developer. Don't include personal information.", 10, UiKit.DIM, 420))
	_build_fields(column)
	_status = UiKit.wrapped("", 10, UiKit.DIM, 420)
	column.add_child(_status)
	var buttons := UiKit.hbox(8)
	_send = UiKit.button("Send", _on_send, 13)
	buttons.add_child(_send)
	buttons.add_child(UiKit.button("Close", _close, 13))
	column.add_child(buttons)
	_client = OnlineClient.new()
	_client.finished.connect(_on_sent)
	add_child(_client)
	if not OnlineConfig.is_set_up():
		_status.text = "Online features aren't set up yet, so suggestions can't be sent."


func _build_fields(column: VBoxContainer) -> void:
	column.add_child(UiKit.label("What is it about?", 11))
	_category = OptionButton.new()
	for index: int in CATEGORIES.size():
		_category.add_item(CATEGORY_NAMES[index], index)
	_category.select(CATEGORIES.find("gameplay"))
	_category.add_theme_font_size_override("font_size", 11)
	column.add_child(_category)
	column.add_child(UiKit.label("Short title (%d-%d letters)" % [MIN_TITLE, MAX_TITLE], 11))
	_title_edit = LineEdit.new()
	_title_edit.max_length = MAX_TITLE
	_title_edit.placeholder_text = "Add a motorcycle"
	_title_edit.add_theme_font_size_override("font_size", 11)
	column.add_child(_title_edit)
	column.add_child(UiKit.label("Your idea (%d-%d letters)" % [MIN_DESCRIPTION, MAX_DESCRIPTION], 11))
	_description = TextEdit.new()
	_description.custom_minimum_size = Vector2(420, 80)
	_description.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_description.placeholder_text = "What would you like, and why would it make the game better?"
	_description.add_theme_font_size_override("font_size", 11)
	column.add_child(_description)


## The suggestion to send, or an empty dictionary (with the reason shown) if it isn't ready.
func build_payload() -> Dictionary:
	# Cleaned here as well as on the Worker: hidden characters removed, sizes kept in bounds.
	var title := InputSafety.clean_text(_title_edit.text, MAX_TITLE)
	var description := InputSafety.clean_text(_description.text, MAX_DESCRIPTION + 1, true)
	if title.length() < MIN_TITLE:
		_status.text = "The title needs at least %d letters." % MIN_TITLE
		return {}
	if description.length() < MIN_DESCRIPTION:
		_status.text = "Please describe your idea in at least %d letters." % MIN_DESCRIPTION
		return {}
	if description.length() > MAX_DESCRIPTION:
		_status.text = "That's a bit long. Please keep it under %d letters." % MAX_DESCRIPTION
		return {}
	return {
		"category": CATEGORIES[_category.get_selected_id()],
		"title": title,
		"description": description,
		"website": "",
		"client": SuggestionEnvironment.collect(),
	}


func _on_send() -> void:
	var payload := build_payload()
	if payload.is_empty():
		return
	_send.disabled = true
	_status.text = "Sending..."
	_client.post_json(OnlineConfig.suggestion_url(), payload)


func _on_sent(ok: bool, _reply: Dictionary, error: String) -> void:
	if not ok:
		_send.disabled = false
		_status.text = error
		return
	_status.text = "Thank you! Your idea was sent."
	_title_edit.text = ""
	_description.text = ""
	_send.disabled = false


func _close() -> void:
	closed.emit()
	queue_free()
