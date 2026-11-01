extends Node
## Autoload "Mobile". Phones and touch screens:
## - is_handheld(): a phone or tablet (app or browser).
## - Touch controls: shown on phones and tablets, and on any computer as soon
##   as its screen is touched; hidden again when a keyboard or controller is
##   used. Settings can force them on or off ("auto" / "on" / "off").
## - safe_rect(): the part of the screen clear of notches and rounded corners.
## - Held upright, a phone shows "Turn your phone sideways" and the game waits.

signal touch_mode_changed

const MODES: Array[String] = ["auto", "on", "off"]
const MODE_NAMES: Dictionary = {"auto": "Auto", "on": "On", "off": "Off"}

## Tests only: pretend to be a phone.
var force_handheld := false
## Tests only: pretend the screen is this size (to check portrait).
var force_window_size := Vector2i.ZERO

var _touch_seen := false
var _overlay: CanvasLayer
var _paused_before := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()


func is_handheld() -> bool:
	return force_handheld or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


func mode() -> String:
	var saved := str(PlayerPrefs.get_value("touch_controls", "auto"))
	return saved if MODES.has(saved) else "auto"


func set_mode(new_mode: String) -> void:
	if not MODES.has(new_mode):
		return
	PlayerPrefs.set_value("touch_controls", new_mode)
	touch_mode_changed.emit()


## The next setting after the current one (for a Settings button).
func next_mode() -> String:
	return MODES[(MODES.find(mode()) + 1) % MODES.size()]


func controls_shown() -> bool:
	match mode():
		"on":
			return true
		"off":
			return false
	return is_handheld() or _touch_seen


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		if not _touch_seen:
			_touch_seen = true
			touch_mode_changed.emit()
	elif _touch_seen and _is_keyboard_or_pad(event):
		_touch_seen = false
		touch_mode_changed.emit()


func _is_keyboard_or_pad(event: InputEvent) -> bool:
	if event is InputEventKey:
		return (event as InputEventKey).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	if event is InputEventJoypadMotion:
		return absf((event as InputEventJoypadMotion).axis_value) > 0.5
	return false


## The screen area clear of notches and rounded corners, in game coordinates.
func safe_rect(viewport: Viewport) -> Rect2:
	var view := viewport.get_visible_rect()
	if not is_handheld() or force_handheld:
		return view
	var safe := viewport.get_final_transform().affine_inverse() * Rect2(DisplayServer.get_display_safe_area())
	var clipped := view.intersection(safe)
	return clipped if clipped.has_area() else view


func is_portrait() -> bool:
	if not is_handheld():
		return false
	var size := force_window_size if force_window_size != Vector2i.ZERO else DisplayServer.window_get_size()
	return size.y > size.x


func _process(_delta: float) -> void:
	var portrait := is_portrait()
	if portrait == _overlay.visible:
		return
	_overlay.visible = portrait
	if portrait:
		_paused_before = get_tree().paused
		get_tree().paused = true
	else:
		get_tree().paused = _paused_before


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 120
	_overlay.visible = false
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.97)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(dim)
	var message := Label.new()
	message.text = "Turn your phone sideways\nto play The Last Wagon"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 22)
	message.add_theme_color_override("font_color", Color("f0b040"))
	message.set_anchors_preset(Control.PRESET_FULL_RECT)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overlay.add_child(message)


func overlay_visible() -> bool:
	return _overlay.visible
