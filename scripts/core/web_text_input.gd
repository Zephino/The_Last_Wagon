class_name WebTextInput
extends RefCounted
## Typing on a phone in the web version (adapted from Mythriven): a browser
## game can't bring up the phone's keyboard by itself, so tapping a text box
## there opens the browser's own text box instead (it always shows the
## keyboard), and what's typed goes into the game's box. The game's own
## cleaning (max length, text_changed handlers) still applies. Does nothing on
## PC, in apps, or in a desktop browser, where typing works as usual.


## Call once for each LineEdit or TextEdit. `label` is what the pop-up asks
## (the box's placeholder is used when empty).
static func attach(box: Control, label := "") -> void:
	box.gui_input.connect(func(event: InputEvent) -> void: _on_input(box, label, event))


static func needed() -> bool:
	return OS.has_feature("web") and (OS.has_feature("web_android") or OS.has_feature("web_ios"))


## One pop-up per tap (when the finger lifts), never again straight after one closes.
static func _on_input(box: Control, label: String, event: InputEvent) -> void:
	if not needed():
		return
	var lifted: bool = (event is InputEventMouseButton and not (event as InputEventMouseButton).pressed) \
			or (event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed)
	if not lifted or Time.get_ticks_msec() < int(box.get_meta("web_text_quiet_until", 0)):
		return
	box.accept_event()
	# A tap arrives as both a touch and a mouse click: ask only once.
	box.set_meta("web_text_quiet_until", Time.get_ticks_msec() + 100000)
	_ask.call_deferred(box, label)


static func _ask(box: Control, label: String) -> void:
	var question: String = label if label != "" else str(box.get("placeholder_text"))
	var current: String = str(box.get("text"))
	var answer: Variant = JavaScriptBridge.eval("window.prompt(%s, %s)" % [JSON.stringify(question), JSON.stringify(current)], true)
	# The tap that opened it can echo back as the pop-up closes; ignore taps for a moment.
	box.set_meta("web_text_quiet_until", Time.get_ticks_msec() + 600)
	if not answer is String:
		return
	apply_answer(box, answer)


## Puts typed text into the box the same way typing would (tests use this too).
static func apply_answer(box: Control, answer: String) -> void:
	if box is LineEdit:
		var line := box as LineEdit
		line.text = answer.left(line.max_length) if line.max_length > 0 else answer
		line.text_changed.emit(line.text)
	elif box is TextEdit:
		(box as TextEdit).text = answer
		(box as TextEdit).text_changed.emit()
