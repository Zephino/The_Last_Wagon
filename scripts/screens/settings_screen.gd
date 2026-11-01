extends Node2D
## Settings: fullscreen, install the game as an app, and update to the newest
## version. Install and Update are for the web version; on PC they explain that.

const NOT_WEB_NOTE := "Only needed in the web version."

var _column: VBoxContainer
var _message := ""


func _ready() -> void:
	var root := UiKit.make_layer(self)
	var background := ColorRect.new()
	background.color = Color("0c0a10")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	_column = UiKit.vbox(8)
	UiKit.pin(_column, root, Vector2(0.5, 0), Vector2(-160, 30), Vector2(320, 0))
	_refresh()


func _refresh() -> void:
	UiKit.clear(_column)
	var title := UiKit.label("SETTINGS", 26, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(title)
	var fullscreen_text := "Fullscreen: %s" % ("On" if AppActions.is_fullscreen() else "Off")
	_column.add_child(UiKit.button(fullscreen_text, _on_fullscreen, 13))
	var installed := AppActions.install_state() == "installed"
	var install := UiKit.button("Installed" if installed else "Install app", _on_install, 13)
	install.disabled = installed
	_column.add_child(install)
	_column.add_child(UiKit.button("Update app", _on_update, 13))
	_column.add_child(UiKit.wrapped("Update app reloads the newest version of the game. A trip in progress is not saved yet.", 9, UiKit.DIM, 320))
	if _message != "":
		var note := UiKit.wrapped(_message, 11, UiKit.ACCENT, 320)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_column.add_child(note)
	var back := UiKit.button("Back", Trip.go.bind("title"), 13)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size = Vector2(120, 0)
	_column.add_child(back)
	var version := UiKit.label("Version %s" % ProjectSettings.get_setting("application/config/version", ""), 9, UiKit.DIM)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(version)


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
