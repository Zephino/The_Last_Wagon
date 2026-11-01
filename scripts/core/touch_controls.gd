class_name TouchControls
extends CanvasLayer
## On-screen controls for touch screens, used on the road and in levels.
## - A floating joystick: touch anywhere on the left half of the screen and
##   drag. Left/right move (or speed up / brake when driving), up/down climb.
## - Action buttons on the right; each screen shows only the ones it uses.
## - A pause button at the top.
## They press the same input actions as the keyboard, so the game works the
## same either way. Shown only when Mobile.controls_shown() says so.

signal pause_pressed

const BUTTONS: Dictionary = {
	"jump": {"label": "JUMP", "action": "jump"},
	"fire": {"label": "SHOOT", "action": "fire"},
	"weapon": {"label": "WEAPON", "action": "next_weapon"},
	"survivor": {"label": "SWAP", "action": "switch_survivor"},
	"use": {"label": "USE", "action": "interact"},
}
## Where each button sits, from the bottom-right corner (in game pixels).
const SPOTS: Array[Vector2] = [Vector2(-62, -64), Vector2(-122, -40), Vector2(-112, -104), Vector2(-52, -128), Vector2(-172, -84)]
const BUTTON_RADIUS := 25.0
const STICK_RADIUS := 34.0
const DEAD_ZONE := 0.3
const CLIMB_ZONE := 0.5
const MOVE_ACTIONS: Array[String] = ["move_left", "move_right", "move_up", "move_down"]

var _root: Control
var _buttons: Dictionary = {}
var _pause: Control
var _stick_base: Control
var _stick_knob: Control
## Finger number -> what it's holding: "stick", "pause" or a button id.
var _touches: Dictionary = {}
var _stick_center := Vector2.ZERO
var _shown: Array[String] = []
## Where the pause button goes: a point of the safe screen area (0..1, 0..1)
## plus an offset in pixels. Each screen picks a spot clear of its HUD.
var pause_anchor := Vector2(0.5, 0.0)
var pause_offset := Vector2(0, 4)


func _ready() -> void:
	layer = 60
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_stick_base = _circle(STICK_RADIUS, Color(1, 1, 1, 0.12), "")
	_stick_knob = _circle(14.0, Color(1, 1, 1, 0.35), "")
	_stick_base.visible = false
	_stick_knob.visible = false
	for id: String in BUTTONS:
		_buttons[id] = _circle(BUTTON_RADIUS, Color(0.1, 0.08, 0.12, 0.55), BUTTONS[id]["label"])
	_pause = _circle(16.0, Color(0.1, 0.08, 0.12, 0.55), "II")
	Mobile.touch_mode_changed.connect(_refresh)
	get_viewport().size_changed.connect(_refresh)
	_refresh()


func place_pause(anchor: Vector2, offset: Vector2) -> void:
	pause_anchor = anchor
	pause_offset = offset
	if _root != null:
		_refresh()


## Which action buttons this screen uses right now (ids from BUTTONS).
func set_buttons(ids: Array[String]) -> void:
	if ids == _shown:
		return
	_shown = ids.duplicate()
	for id: String in _touches.values():
		if BUTTONS.has(id) and not _shown.has(id):
			Input.action_release(BUTTONS[id]["action"])
	_refresh()


func _refresh() -> void:
	var shown := Mobile.controls_shown()
	_root.visible = shown
	if not shown:
		release_all()
	var view := Mobile.safe_rect(get_viewport())
	var corner := view.end
	var slot := 0
	for id: String in BUTTONS:
		var button: Control = _buttons[id]
		button.visible = _shown.has(id)
		if button.visible:
			button.position = corner + SPOTS[slot] - button.size / 2.0
			slot += 1
	_pause.position = view.position + view.size * pause_anchor + pause_offset - Vector2(_pause.size.x / 2.0, 0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		release_all()


func release_all() -> void:
	for action: String in MOVE_ACTIONS:
		Input.action_release(action)
	for id: String in BUTTONS:
		Input.action_release(BUTTONS[id]["action"])
	_touches.clear()
	if _stick_base != null:
		_stick_base.visible = false
		_stick_knob.visible = false


func _input(event: InputEvent) -> void:
	if not _root.visible or get_tree().paused:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_press(touch.index, touch.position)
		else:
			_lift(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touches.get(drag.index, "") == "stick":
			_move_stick(drag.position)


func _press(finger: int, at: Vector2) -> void:
	if _hit(_pause, at):
		_touches[finger] = "pause"
		pause_pressed.emit()
		return
	for id: String in _shown:
		if _hit(_buttons[id], at):
			_touches[finger] = id
			Input.action_press(BUTTONS[id]["action"])
			return
	var view := Mobile.safe_rect(get_viewport())
	if at.x < view.position.x + view.size.x * 0.5 and not _touches.values().has("stick"):
		_touches[finger] = "stick"
		_stick_center = at
		_stick_base.visible = true
		_stick_knob.visible = true
		_stick_base.position = at - _stick_base.size / 2.0
		_move_stick(at)


func _lift(finger: int) -> void:
	var held: String = _touches.get(finger, "")
	_touches.erase(finger)
	if held == "stick":
		for action: String in MOVE_ACTIONS:
			Input.action_release(action)
		_stick_base.visible = false
		_stick_knob.visible = false
	elif BUTTONS.has(held):
		Input.action_release(BUTTONS[held]["action"])


func _move_stick(at: Vector2) -> void:
	var offset := (at - _stick_center).limit_length(STICK_RADIUS)
	_stick_knob.position = _stick_center + offset - _stick_knob.size / 2.0
	var push := offset / STICK_RADIUS
	_set_axis("move_left", "move_right", push.x, DEAD_ZONE)
	_set_axis("move_up", "move_down", push.y, CLIMB_ZONE)


func _set_axis(negative: String, positive: String, value: float, dead_zone: float) -> void:
	if value < -dead_zone:
		Input.action_press(negative, minf(1.0, -value))
		Input.action_release(positive)
	elif value > dead_zone:
		Input.action_press(positive, minf(1.0, value))
		Input.action_release(negative)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


func _hit(control: Control, at: Vector2) -> bool:
	if not control.visible:
		return false
	var center := control.position + control.size / 2.0
	return at.distance_to(center) <= control.size.x / 2.0 + 6.0


func _circle(radius: float, color: Color, text: String) -> Control:
	var panel := Panel.new()
	panel.size = Vector2(radius, radius) * 2.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1, 1, 1, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(radius))
	panel.add_theme_stylebox_override("panel", style)
	if text != "":
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.add_theme_font_size_override("font_size", 9 if text.length() > 4 else 11)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
	_root.add_child(panel)
	return panel
