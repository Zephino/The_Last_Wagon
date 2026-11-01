extends Node2D
## Title screen: pick a route and start a new trip.

const GROUND_Y := 60.0

var _quit_note: Label


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var look := Apocalypse.new()
	look.threats.append(Apocalypse.Threat.ZOMBIES)
	Backdrop.add_sky(self, look)
	Backdrop.add_camera(self, Vector2.ZERO)
	Backdrop.add_skyline(self, -260, 260, GROUND_Y, Color("241a22"), rng)
	add_child(PixelArt.ground_block(Color("5a4630"), Color("3a2c20"), Vector2(-260, GROUND_Y), Vector2(520, 60)))
	add_child(PixelArt.standing(PixelArt.car(Color("8a3a2a")), Vector2(125, GROUND_Y)))
	_build_menu()


func _build_menu() -> void:
	var root := UiKit.make_layer(self)
	var column := UiKit.vbox(6)
	UiKit.pin(column, root, Vector2(0.5, 0), Vector2(-260, 16), Vector2(520, 0))
	var title := UiKit.label("THE LAST WAGON", 34, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var tagline := UiKit.label("The world ended. The road didn't.", 12, UiKit.DIM)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(tagline)
	column.add_child(UiKit.label("Choose your route:", 12))
	var routes := GridContainer.new()
	routes.columns = 2
	routes.add_theme_constant_override("h_separation", 6)
	routes.add_theme_constant_override("v_separation", 4)
	column.add_child(routes)
	for route: Dictionary in Routes.all():
		routes.add_child(_route_button(route))
	var extras := UiKit.hbox(8)
	extras.alignment = BoxContainer.ALIGNMENT_CENTER
	extras.add_child(UiKit.button("Leaderboard", Trip.go.bind("leaderboard"), 12))
	extras.add_child(UiKit.button("Awards", Trip.go.bind("awards"), 12))
	extras.add_child(UiKit.button("Suggest an idea", _open_suggestions, 12))
	extras.add_child(UiKit.button("Settings", Trip.go.bind("settings"), 12))
	extras.add_child(UiKit.button("Quit", _on_quit, 12))
	column.add_child(extras)
	_quit_note = UiKit.label("", 11, UiKit.ACCENT)
	_quit_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_quit_note)
	var version := UiKit.label("v" + str(ProjectSettings.get_setting("application/config/version", "")), 9, UiKit.DIM)
	UiKit.pin(version, root, Vector2(1, 1), Vector2(-70, -18))
	# Godot's MIT license asks for its copyright notice to ship with the game.
	var credit := UiKit.label("Made with Godot Engine. (c) Godot Engine contributors, MIT license.", 8, UiKit.DIM)
	UiKit.pin(credit, root, Vector2(0, 1), Vector2(8, -16))


## A route button: open routes go to the Prepare screen; locked ones say how to unlock them.
func _route_button(route: Dictionary) -> Button:
	var unlocked := Progress.is_unlocked("route", str(route["id"]))
	var text := "%s (%s)" % [route["name"], Routes.length_name(route)]
	var route_button := UiKit.button(text, _choose_route.bind(route), 11)
	route_button.custom_minimum_size = Vector2(257, 0)
	if not unlocked:
		var award := Unlocks.award_for("route", str(route["id"]))
		route_button.text = "%s  (locked)" % text
		route_button.tooltip_text = "To unlock: %s" % award.get("how", "")
	route_button.disabled = not unlocked
	return route_button


func _choose_route(route: Dictionary) -> void:
	Trip.route = route
	Trip.go("prepare")


func _open_suggestions() -> void:
	add_child(SuggestionForm.new())


## Browsers don't let a page close its own tab, so the web version explains instead.
func _on_quit() -> void:
	if OS.has_feature("web"):
		_quit_note.text = "To quit, just close this browser tab."
		return
	get_tree().quit()
