class_name PauseMenu
extends CanvasLayer
## The pause menu on the road and in levels (Esc / Start / the II button).
## Resume, an optional "leave" action (e.g. Leave level), Touch controls and
## Fullscreen settings, and Quit to title (asks first: trips aren't saved).

signal closed

var leave_text := ""
var on_leave := Callable()
var _column: VBoxContainer
var _confirm_quit := false
var _opened_frame := 0


## Pauses the game and shows the menu on top of `host`.
static func open(host: Node, leave_label := "", leave_action := Callable()) -> PauseMenu:
	var menu := PauseMenu.new()
	menu.leave_text = leave_label
	menu.on_leave = leave_action
	host.add_child(menu)
	return menu


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_frame = Engine.get_process_frames()
	get_tree().paused = true
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var panel := UiKit.panel(Vector2(240, 0))
	UiKit.pin(panel, root, Vector2(0.5, 0.5), Vector2(-120, -110))
	_column = UiKit.vbox(6)
	panel.add_child(_column)
	_build()


func _build() -> void:
	UiKit.clear(_column)
	var title := UiKit.label("PAUSED", 20, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(title)
	if _confirm_quit:
		_column.add_child(UiKit.wrapped("Quit this trip? Trips aren't saved, so it will be over.", 11, UiKit.TEXT, 224))
		_column.add_child(UiKit.button("Yes, quit to title", _quit, 13))
		_column.add_child(UiKit.button("No, keep playing", _cancel_quit, 13))
		return
	_column.add_child(UiKit.button("Resume", close, 14))
	if leave_text != "":
		_column.add_child(UiKit.button(leave_text, _leave, 13))
	_column.add_child(UiKit.button("Touch controls: %s" % Mobile.MODE_NAMES[Mobile.mode()], _cycle_touch, 12))
	_column.add_child(UiKit.button("Fullscreen: %s" % ("On" if AppActions.is_fullscreen() else "Off"), _toggle_fullscreen, 12))
	_column.add_child(UiKit.button("Quit to title", _ask_quit, 12))


func _process(_delta: float) -> void:
	if Engine.get_process_frames() > _opened_frame + 1 and Input.is_action_just_pressed("back"):
		close()


func close() -> void:
	if is_queued_for_deletion():
		return
	get_tree().paused = false
	closed.emit()
	queue_free()


func _leave() -> void:
	close()
	if on_leave.is_valid():
		on_leave.call()


func _cycle_touch() -> void:
	Mobile.set_mode(Mobile.next_mode())
	_build()


func _toggle_fullscreen() -> void:
	AppActions.toggle_fullscreen()
	await get_tree().create_timer(0.4).timeout
	if is_inside_tree():
		_build()


func _ask_quit() -> void:
	_confirm_quit = true
	_build()


func _cancel_quit() -> void:
	_confirm_quit = false
	_build()


func _quit() -> void:
	get_tree().paused = false
	Trip.go("title")
