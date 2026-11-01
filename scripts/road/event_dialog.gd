class_name EventDialog
extends CanvasLayer
## Shows one road event: its text and choices. After a choice it shows what
## happened, and Continue closes it. The road waits while it's open.

signal closed

var event: Dictionary = {}
var _column: VBoxContainer


func _ready() -> void:
	layer = 40
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := UiKit.panel(Vector2(420, 0))
	UiKit.pin(panel, root, Vector2(0.5, 0), Vector2(-210, 70))
	_column = UiKit.vbox(6)
	panel.add_child(_column)
	_show_choices()


func _show_choices() -> void:
	UiKit.clear(_column)
	_column.add_child(UiKit.label(str(event["title"]), 16, UiKit.ACCENT))
	_column.add_child(UiKit.wrapped(str(event["text"]), 11, UiKit.TEXT, 400))
	for choice: Dictionary in event["choices"]:
		var reason := RoadEvents.blocked_reason(choice)
		var text: String = choice["label"] if reason.is_empty() else "%s  (%s)" % [choice["label"], reason]
		var pick := UiKit.button(text, choose.bind(choice), 11)
		pick.disabled = not reason.is_empty()
		_column.add_child(pick)


## Picks a choice (the buttons call this; tests can too).
func choose(choice: Dictionary) -> void:
	var result := RoadEvents.resolve(choice, Trip.rng)
	Trip.log_message("%s: %s" % [event["title"], result.get_slice("\n", 0)])
	UiKit.clear(_column)
	_column.add_child(UiKit.label(str(event["title"]), 16, UiKit.ACCENT))
	_column.add_child(UiKit.wrapped(result, 11, UiKit.TEXT, 400))
	_column.add_child(UiKit.button("Continue", close, 12))


func close() -> void:
	closed.emit()
	queue_free()
