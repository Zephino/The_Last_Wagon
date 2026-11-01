extends Node2D
## Before a trip: pick 4 survivors, one starting perk and a car color.
## Locked choices show which award unlocks them. Choices are remembered.

const PARTY_SIZE := 4

var _roles: Array[Survivor.Role] = []
var _perk := "none"
var _color := "classic_red"
var _root: Control
var _start: Button


func _ready() -> void:
	_load_choices()
	_root = UiKit.make_layer(self)
	_build()


func _load_choices() -> void:
	for role_id: String in PlayerPrefs.get_value("party_roles", []):
		var role := Survivor.role_from_id(role_id)
		if Progress.is_unlocked("role", role_id) and not _roles.has(role) and _roles.size() < PARTY_SIZE:
			_roles.append(role)
	if _roles.size() != PARTY_SIZE:
		_roles = Survivor.BASE_ROLES.duplicate()
	var perk_id := str(PlayerPrefs.get_value("perk", "none"))
	_perk = perk_id if Progress.is_unlocked("perk", perk_id) else "none"
	var color_id := str(PlayerPrefs.get_value("car_color", "classic_red"))
	_color = color_id if Progress.is_unlocked("color", color_id) else "classic_red"


func _build() -> void:
	UiKit.clear(_root)
	var background := ColorRect.new()
	background.color = Color("0c0a10")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(background)
	var stops: Array = Trip.route.get("stops", [])
	var title := UiKit.label("Prepare: %s  (%d stops, %s)" % [Trip.route.get("name", ""), stops.size(), Routes.length_name(Trip.route)], 18, UiKit.ACCENT)
	UiKit.pin(title, _root, Vector2(0.5, 0), Vector2(-300, 8), Vector2(600, 0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The choices scroll if they don't fit (small phone screens).
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiKit.pin(scroll, _root, Vector2(0.5, 0), Vector2(-310, 36), Vector2(620, maxf(150.0, _root.size.y - 84.0)))
	var columns := UiKit.hbox(15)
	scroll.add_child(columns)
	var left := UiKit.vbox(3)
	left.custom_minimum_size = Vector2(295, 0)
	columns.add_child(left)
	_build_survivors(left)
	var right := UiKit.vbox(3)
	right.custom_minimum_size = Vector2(295, 0)
	columns.add_child(right)
	_build_perks(right)
	_build_colors(right)
	var buttons := UiKit.hbox(10)
	UiKit.pin(buttons, _root, Vector2(0.5, 1), Vector2(-110, -40), Vector2(220, 0))
	buttons.add_child(UiKit.button("Back", Trip.go.bind("title"), 13))
	_start = UiKit.button("Start trip", start_trip, 13)
	_start.disabled = _roles.size() != PARTY_SIZE
	buttons.add_child(_start)


func _build_survivors(column: VBoxContainer) -> void:
	column.add_child(UiKit.label("Survivors (pick %d): %d chosen" % [PARTY_SIZE, _roles.size()], 12, UiKit.ACCENT))
	for role: Survivor.Role in Survivor.ALL_ROLES:
		var role_id: String = Survivor.ROLE_IDS[role]
		var unlocked := Progress.is_unlocked("role", role_id)
		var chosen := _roles.has(role)
		var text := ("[x] " if chosen else "[  ] ") + Survivor.name_of_role(role)
		var pick := UiKit.button(text, _toggle_role.bind(role), 11)
		pick.alignment = HORIZONTAL_ALIGNMENT_LEFT
		pick.disabled = not unlocked or (not chosen and _roles.size() >= PARTY_SIZE)
		column.add_child(pick)
		var note := Survivor.perk_of_role(role) if unlocked else _locked_text("role", role_id)
		column.add_child(UiKit.wrapped(note, 9, UiKit.DIM if unlocked else UiKit.DANGER, 290))


func _build_perks(column: VBoxContainer) -> void:
	column.add_child(UiKit.label("Starting perk", 12, UiKit.ACCENT))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 3)
	column.add_child(grid)
	for perk: Dictionary in Unlocks.PERKS:
		var perk_id: String = perk["id"]
		var unlocked := Progress.is_unlocked("perk", perk_id)
		var text: String = ("(o) " if perk_id == _perk else "( ) ") + str(perk["name"])
		if not unlocked:
			text = "( ) ???"
		var pick := UiKit.button(text, _pick_perk.bind(perk_id), 10)
		pick.alignment = HORIZONTAL_ALIGNMENT_LEFT
		pick.disabled = not unlocked
		pick.tooltip_text = str(perk["text"]) if unlocked else _locked_text("perk", perk_id)
		pick.custom_minimum_size.x = 145
		grid.add_child(pick)
	column.add_child(UiKit.wrapped(str(Unlocks.perk(_perk)["text"]), 9, UiKit.DIM, 290))


func _build_colors(column: VBoxContainer) -> void:
	column.add_child(UiKit.label("Car color", 12, UiKit.ACCENT))
	var row := GridContainer.new()
	row.columns = 6
	row.add_theme_constant_override("h_separation", 4)
	row.add_theme_constant_override("v_separation", 4)
	for entry: Dictionary in Unlocks.COLORS:
		var color_id: String = entry["id"]
		var unlocked := Progress.is_unlocked("color", color_id)
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(34, 22)
		swatch.focus_mode = Control.FOCUS_NONE
		swatch.disabled = not unlocked
		swatch.text = "*" if color_id == _color else ("" if unlocked else "?")
		var style := StyleBoxFlat.new()
		style.bg_color = entry["color"] if unlocked else Color(0.2, 0.2, 0.2)
		style.set_border_width_all(2 if color_id == _color else 0)
		style.border_color = UiKit.ACCENT
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			swatch.add_theme_stylebox_override(state, style)
		swatch.tooltip_text = str(entry["name"]) if unlocked else _locked_text("color", color_id)
		swatch.pressed.connect(_pick_color.bind(color_id))
		row.add_child(swatch)
	column.add_child(row)
	for entry: Dictionary in Unlocks.COLORS:
		if entry["id"] == _color:
			column.add_child(UiKit.label(str(entry["name"]), 9, UiKit.DIM))


func _locked_text(kind: String, thing_id: String) -> String:
	var award := Unlocks.award_for(kind, thing_id)
	if award.is_empty():
		return "Locked"
	if award["secret"] and not Progress.has_award(award["id"]):
		return "Locked: earned by a secret."
	return "Locked: %s" % award["how"]


func _toggle_role(role: Survivor.Role) -> void:
	if _roles.has(role):
		_roles.erase(role)
	elif _roles.size() < PARTY_SIZE:
		_roles.append(role)
	_build()


func _pick_perk(perk_id: String) -> void:
	_perk = perk_id
	_build()


func _pick_color(color_id: String) -> void:
	_color = color_id
	_build()


## Starts the trip with these choices and remembers them for next time.
func start_trip() -> void:
	if _roles.size() != PARTY_SIZE:
		return
	var role_ids: Array[String] = []
	for role: Survivor.Role in _roles:
		role_ids.append(Survivor.ROLE_IDS[role])
	PlayerPrefs.set_value("party_roles", role_ids)
	PlayerPrefs.set_value("perk", _perk)
	PlayerPrefs.set_value("car_color", _color)
	Trip.new_trip(Trip.route, int(Time.get_unix_time_from_system()), _roles, _perk, _color)
	Trip.go("town")
