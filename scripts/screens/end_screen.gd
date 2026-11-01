extends Node2D
## End of a trip: you reached the finish, or everyone is down for good.


func _ready() -> void:
	var root := UiKit.make_layer(self)
	var background := ColorRect.new()
	background.color = Color("0c0a10")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var column := UiKit.vbox(8)
	UiKit.pin(column, root, Vector2(0.5, 0), Vector2(-200, 50), Vector2(400, 0))
	var won := Trip.won
	var title := UiKit.label("YOU MADE IT" if won else "THE ROAD WINS", 30, UiKit.GOOD if won else UiKit.DANGER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var line := Flavor.pick(Flavor.WIN_LINES if won else Flavor.LOSE_LINES, Trip.rng)
	var flavor := UiKit.wrapped(line, 12, UiKit.TEXT, 400)
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(flavor)
	column.add_child(UiKit.label("Apocalypse: %s" % Trip.apocalypse.title(), 11, UiKit.DIM))
	column.add_child(UiKit.label("Days on the road: %d" % (int(Trip.days) + 1), 11))
	column.add_child(UiKit.label("Miles traveled: %d" % Trip.miles_traveled, 11))
	column.add_child(UiKit.label("Survivors still standing: %d of %d" % [Trip.standing_count(), Trip.party.size()], 11))
	column.add_child(UiKit.button("New trip", Trip.go.bind("title"), 14))
