extends Node2D
## Title screen: pick a route and start a new trip.

const GROUND_Y := 60.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var look := Apocalypse.new()
	look.threats.append(Apocalypse.Threat.ZOMBIES)
	Backdrop.add_sky(self, look)
	Backdrop.add_camera(self, Vector2.ZERO)
	Backdrop.add_skyline(self, -260, 260, GROUND_Y, Color("241a22"), rng)
	add_child(PixelArt.ground_block(Color("5a4630"), Color("3a2c20"), Vector2(-260, GROUND_Y), Vector2(520, 60)))
	add_child(PixelArt.standing(PixelArt.car(Color("8a3a2a")), Vector2(70, GROUND_Y)))
	_build_menu()


func _build_menu() -> void:
	var root := UiKit.make_layer(self)
	var column := UiKit.vbox(6)
	UiKit.pin(column, root, Vector2(0.5, 0), Vector2(-150, 24), Vector2(300, 0))
	var title := UiKit.label("THE LAST WAGON", 34, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var tagline := UiKit.label("The world ended. The road didn't.", 12, UiKit.DIM)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(tagline)
	column.add_child(UiKit.label("Choose your route:", 12))
	for route: Dictionary in Routes.all():
		var playable: bool = route["playable"]
		var text: String = route["name"] if playable else "%s  (coming later)" % route["name"]
		var route_button := UiKit.button(text, _start_trip.bind(route))
		route_button.disabled = not playable
		column.add_child(route_button)
	var extras := UiKit.hbox(8)
	extras.alignment = BoxContainer.ALIGNMENT_CENTER
	extras.add_child(UiKit.button("Leaderboard", Trip.go.bind("leaderboard"), 12))
	extras.add_child(UiKit.button("Suggest an idea", _open_suggestions, 12))
	column.add_child(extras)
	var version := UiKit.label("v" + str(ProjectSettings.get_setting("application/config/version", "")), 9, UiKit.DIM)
	UiKit.pin(version, root, Vector2(1, 1), Vector2(-70, -18))
	# Godot's MIT license asks for its copyright notice to ship with the game.
	var credit := UiKit.label("Made with Godot Engine. (c) Godot Engine contributors, MIT license.", 8, UiKit.DIM)
	UiKit.pin(credit, root, Vector2(0, 1), Vector2(8, -16))


func _start_trip(route: Dictionary) -> void:
	Trip.new_trip(route, int(Time.get_unix_time_from_system()))
	Trip.go("town")


func _open_suggestions() -> void:
	add_child(SuggestionForm.new())
