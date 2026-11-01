extends Node2D
## Settings: fullscreen, install the game as an app, update to the newest
## version, and online progress (sync code or Sign in with Google).
## Install and Update are for the web version; on PC they explain that.

const NOT_WEB_NOTE := "Only needed in the web version."

var _root: Control
var _message := ""
var _code_edit: LineEdit
var _code_message := ""


func _ready() -> void:
	_root = UiKit.make_layer(self)
	CloudSync.status_changed.connect(_refresh)
	CloudSync.google.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if not is_inside_tree():
		return
	UiKit.clear(_root)
	var background := ColorRect.new()
	background.color = Color("0c0a10")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(background)
	var title := UiKit.label("SETTINGS", 24, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.pin(title, _root, Vector2(0.5, 0), Vector2(-300, 8), Vector2(600, 0))
	var left := UiKit.vbox(6)
	UiKit.pin(left, _root, Vector2(0.5, 0), Vector2(-310, 50), Vector2(290, 0))
	_build_app(left)
	var right := UiKit.vbox(5)
	UiKit.pin(right, _root, Vector2(0.5, 0), Vector2(10, 50), Vector2(300, 0))
	_build_online(right)
	var bottom := UiKit.vbox(2)
	UiKit.pin(bottom, _root, Vector2(0.5, 1), Vector2(-60, -52), Vector2(120, 0))
	bottom.add_child(UiKit.button("Back", Trip.go.bind("title"), 13))
	var version := UiKit.label("Version %s" % ProjectSettings.get_setting("application/config/version", ""), 9, UiKit.DIM)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(version)


func _build_app(column: VBoxContainer) -> void:
	column.add_child(UiKit.label("Game", 13, UiKit.ACCENT))
	column.add_child(UiKit.button("Fullscreen: %s" % ("On" if AppActions.is_fullscreen() else "Off"), _on_fullscreen, 12))
	column.add_child(UiKit.button("Touch controls: %s" % Mobile.MODE_NAMES[Mobile.mode()], _on_touch_mode, 12))
	var installed := AppActions.install_state() == "installed"
	var install := UiKit.button("Installed" if installed else "Install app", _on_install, 12)
	install.disabled = installed
	column.add_child(install)
	column.add_child(UiKit.button("Update app", _on_update, 12))
	column.add_child(UiKit.wrapped("Update app reloads the newest version of the game. A trip in progress is not saved.", 9, UiKit.DIM, 290))
	if _message != "":
		column.add_child(UiKit.wrapped(_message, 10, UiKit.ACCENT, 290))


func _build_online(column: VBoxContainer) -> void:
	column.add_child(UiKit.label("Online progress", 13, UiKit.ACCENT))
	column.add_child(UiKit.wrapped("Keeps your awards and unlocks the same on every device.", 9, UiKit.DIM, 300))
	if not OnlineConfig.is_set_up():
		column.add_child(UiKit.wrapped("Online features aren't set up yet.", 10, UiKit.DANGER, 300))
		return
	if CloudSync.is_linked():
		_build_linked(column)
	else:
		_build_not_linked(column)
	_build_google(column)
	if CloudSync.status != "":
		column.add_child(UiKit.wrapped(CloudSync.status, 9, UiKit.DIM, 300))


func _build_linked(column: VBoxContainer) -> void:
	if CloudSync.email() != "":
		column.add_child(UiKit.label("Signed in as %s" % CloudSync.email(), 10, UiKit.GOOD))
	column.add_child(UiKit.label("Your sync code: %s" % CloudSync.pretty(CloudSync.code()), 11, UiKit.TEXT))
	column.add_child(UiKit.wrapped("Keep it private: anyone with it can use your progress.", 9, UiKit.DIM, 300))
	var row := UiKit.hbox(6)
	row.add_child(UiKit.button("Copy code", _on_copy, 11))
	row.add_child(UiKit.button("Sync now", CloudSync.request_sync.bind(true), 11))
	row.add_child(UiKit.button("Stop syncing", _on_stop, 11))
	column.add_child(row)
	if _code_message != "":
		column.add_child(UiKit.label(_code_message, 9, UiKit.ACCENT))


func _build_not_linked(column: VBoxContainer) -> void:
	column.add_child(UiKit.button("Create sync code", _on_create, 11))
	column.add_child(UiKit.label("Already have a code from another device?", 9, UiKit.DIM))
	var row := UiKit.hbox(6)
	_code_edit = LineEdit.new()
	_code_edit.placeholder_text = "ABCD-EFGH-JKLM"
	_code_edit.max_length = 16
	_code_edit.custom_minimum_size = Vector2(170, 0)
	_code_edit.add_theme_font_size_override("font_size", 11)
	WebTextInput.attach(_code_edit, "Type your sync code")
	row.add_child(_code_edit)
	row.add_child(UiKit.button("Use code", _on_use_code, 11))
	column.add_child(row)
	if _code_message != "":
		column.add_child(UiKit.label(_code_message, 9, UiKit.DANGER))


func _build_google(column: VBoxContainer) -> void:
	var google := CloudSync.google
	if google.state == "waiting":
		column.add_child(UiKit.wrapped("Finish signing in on the Google page, then come back here.", 10, UiKit.ACCENT, 300))
		var row := UiKit.hbox(6)
		row.add_child(UiKit.button("Open sign-in page", google.open_page, 11))
		row.add_child(UiKit.button("Cancel", google.cancel, 11))
		column.add_child(row)
	elif CloudSync.email() == "":
		var sign_in := UiKit.button("Sign in with Google", google.start, 11)
		sign_in.disabled = google.state == "starting"
		column.add_child(sign_in)
	if google.message != "":
		column.add_child(UiKit.wrapped(google.message, 9, UiKit.DANGER, 300))


func _on_fullscreen() -> void:
	AppActions.toggle_fullscreen()
	# The browser switches a moment later.
	await get_tree().create_timer(0.4).timeout
	_refresh()


func _on_install() -> void:
	match AppActions.install_state():
		"ready":
			_message = ""
			AppActions.install()
		"ios":
			_message = "On iPhone and iPad: tap Share, then Add to Home Screen."
		"not_web":
			_message = NOT_WEB_NOTE
		_:
			_message = "This browser can't install apps (or it's already installed). In Chrome or Edge, use the install icon in the address bar."
	_refresh()


func _on_update() -> void:
	if not AppActions.is_web():
		_message = NOT_WEB_NOTE
		_refresh()
		return
	_message = "Updating..."
	_refresh()
	AppActions.update_now()


## Auto shows them on phones and tablets, and on computers once the screen is touched.
func _on_touch_mode() -> void:
	Mobile.set_mode(Mobile.next_mode())
	_refresh()


func _on_create() -> void:
	_code_message = ""
	CloudSync.create_code()


func _on_use_code() -> void:
	if CloudSync.use_code(_code_edit.text):
		_code_message = ""
	else:
		_code_message = "That isn't a valid code (12 letters and numbers)."
		_refresh()


func _on_copy() -> void:
	DisplayServer.clipboard_set(CloudSync.pretty(CloudSync.code()))
	_code_message = "Copied!"
	_refresh()


func _on_stop() -> void:
	_code_message = ""
	CloudSync.stop_syncing()
