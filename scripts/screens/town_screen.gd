extends Node2D
## Store screen. The starting town and every store town on the route use it.
## Buy supplies, rename the party (start town only), then head out.

## Each item: name, supply id, how much one purchase gives, base price.
const ITEMS: Array[Dictionary] = [
	{"label": "Food (20 lbs)", "supply": "food", "amount": 20, "price": 10},
	{"label": "Fuel (5 gallons)", "supply": "fuel", "amount": 5, "price": 20},
	{"label": "Ammo (20 rounds)", "supply": "ammo", "amount": 20, "price": 15},
	{"label": "Medkit", "supply": "medkits", "amount": 1, "price": 25},
	{"label": "Scrap (5 parts)", "supply": "scrap", "amount": 5, "price": 10},
]
## Later towns charge more. The apocalypse is bad for prices.
const PRICE_RISE_PER_STOP := 0.08
const GROUND_Y := 70.0

var _bought: Dictionary = {}
var _quip := ""
var _money_label: Label
var _supplies_label: Label
var _item_counts: Dictionary = {}


func _ready() -> void:
	_quip = Flavor.pick(Flavor.SHOPKEEPER_LINES, Trip.rng)
	for item: Dictionary in ITEMS:
		_bought[item["supply"]] = 0
	_build_world()
	_build_ui()
	_refresh()


func _build_world() -> void:
	Backdrop.add_sky(self, Trip.apocalypse)
	Backdrop.add_camera(self, Vector2.ZERO)
	var rng := RandomNumberGenerator.new()
	rng.seed = Trip.stop_index + 11
	Backdrop.add_skyline(self, -300, 300, GROUND_Y, Trip.apocalypse.sky_color().darkened(0.4), rng)
	var ground := Trip.apocalypse.ground_color()
	add_child(PixelArt.ground_block(ground.lightened(0.2), ground, Vector2(-300, GROUND_Y), Vector2(600, 40)))
	add_child(PixelArt.tiled(PixelArt.brick_tile(Color("6a3a2a")), Vector2(-150, GROUND_Y - 64), Vector2(120, 64)))
	add_child(PixelArt.standing(PixelArt.person(Color("d9a066"), Color("8a8a8a"), Color("6a2a5a"), Color("2a2a3a")), Vector2(-90, GROUND_Y)))
	var x := 40.0
	for survivor: Survivor in Trip.party:
		add_child(PixelArt.standing(survivor.sprite(), Vector2(x, GROUND_Y)))
		x += 16.0


func _price(item: Dictionary) -> int:
	return roundi(int(item["price"]) * (1.0 + PRICE_RISE_PER_STOP * Trip.stop_index))


func _build_ui() -> void:
	var root := UiKit.make_layer(self)
	var store := UiKit.panel(Vector2(300, 0))
	UiKit.pin(store, root, Vector2(0, 0), Vector2(10, 10))
	var column := UiKit.vbox(4)
	store.add_child(column)
	var stop := Trip.current_stop()
	column.add_child(UiKit.label("%s General Store" % stop["city"], 16, UiKit.ACCENT))
	column.add_child(UiKit.wrapped("\"%s\"" % _quip, 10, UiKit.DIM, 280))
	for item: Dictionary in ITEMS:
		column.add_child(_item_row(item))
	_money_label = UiKit.label("", 12, UiKit.GOOD)
	column.add_child(_money_label)
	_supplies_label = UiKit.wrapped("", 10, UiKit.TEXT, 280)
	column.add_child(_supplies_label)
	column.add_child(UiKit.button("Hit the road", _leave, 14))
	_build_party_panel(root)


func _item_row(item: Dictionary) -> HBoxContainer:
	var row := UiKit.hbox(4)
	var name_label := UiKit.label("%s  $%d" % [item["label"], _price(item)], 11)
	name_label.custom_minimum_size = Vector2(170, 0)
	row.add_child(name_label)
	row.add_child(UiKit.button(" - ", _sell_back.bind(item), 11))
	row.add_child(UiKit.button(" + ", _buy.bind(item), 11))
	var count := UiKit.label("", 11, UiKit.DIM)
	row.add_child(count)
	_item_counts[item["supply"]] = count
	return row


func _build_party_panel(root: Control) -> void:
	var party_panel := UiKit.panel(Vector2(250, 0))
	UiKit.pin(party_panel, root, Vector2(1, 0), Vector2(-260, 10))
	var column := UiKit.vbox(3)
	party_panel.add_child(column)
	column.add_child(UiKit.label("Your party", 14, UiKit.ACCENT))
	var at_start := Trip.stop_index == 0
	for survivor: Survivor in Trip.party:
		if at_start:
			var name_edit := LineEdit.new()
			name_edit.text = survivor.name
			name_edit.max_length = 14
			name_edit.add_theme_font_size_override("font_size", 11)
			name_edit.text_changed.connect(func(new_text: String) -> void: survivor.name = new_text.strip_edges())
			column.add_child(name_edit)
		else:
			column.add_child(UiKit.label(survivor.name, 11))
		column.add_child(UiKit.wrapped("%s: %s" % [survivor.role_name(), survivor.perk()], 9, UiKit.DIM, 230))
	if at_start:
		column.add_child(UiKit.wrapped("You have no car. You'll walk until you find one. Fuel is still worth buying.", 9, UiKit.ACCENT, 230))


func _buy(item: Dictionary) -> void:
	var cost := _price(item)
	if Trip.money < cost:
		return
	Trip.money -= cost
	Trip.add_supply(item["supply"], item["amount"])
	_bought[item["supply"]] += 1
	_refresh()


## Undo a purchase made on this visit only (no selling your old stuff).
func _sell_back(item: Dictionary) -> void:
	if _bought[item["supply"]] <= 0:
		return
	_bought[item["supply"]] -= 1
	Trip.money += _price(item)
	Trip.add_supply(item["supply"], -int(item["amount"]))
	_refresh()


func _refresh() -> void:
	_money_label.text = "Money: $%d" % Trip.money
	_supplies_label.text = UiKit.supplies_text()
	for item: Dictionary in ITEMS:
		var count: Label = _item_counts[item["supply"]]
		count.text = "x%d" % _bought[item["supply"]] if _bought[item["supply"]] > 0 else ""


func _leave() -> void:
	for survivor: Survivor in Trip.party:
		if survivor.name.is_empty():
			survivor.name = "Nameless"
	Trip.go("map")
