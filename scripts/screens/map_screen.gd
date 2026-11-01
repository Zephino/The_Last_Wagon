extends Node2D
## Map screen: see the route, look after the party, and choose what to do
## next: scavenge here, visit the store, or travel to the next stop.

const MAP_SCALE := 1.8

var _marker: ColorRect
var _blink := 0.0


func _ready() -> void:
	if Trip.is_game_over():
		Trip.go("end")
		return
	Trip.ensure_active_standing()
	_build()


func _process(delta: float) -> void:
	if _marker == null:
		return
	_blink += delta
	_marker.visible = fmod(_blink, 0.8) < 0.5


func _build() -> void:
	for child: Node in get_children():
		child.queue_free()
	var root := UiKit.make_layer(self)
	var background := ColorRect.new()
	background.color = Color("0c1118")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	_build_map(root)
	_build_status(root)
	_build_log(root)


func _build_map(root: Control) -> void:
	var map_panel := UiKit.panel()
	UiKit.pin(map_panel, root, Vector2(0, 0), Vector2(10, 10))
	var column := UiKit.vbox(4)
	map_panel.add_child(column)
	column.add_child(UiKit.label("%s  -  Day %d" % [Trip.route["name"], int(Trip.days) + 1], 13, UiKit.ACCENT))
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(MapPainter.WIDTH, MapPainter.HEIGHT) * MAP_SCALE
	column.add_child(holder)
	var map_image := TextureRect.new()
	map_image.texture = MapPainter.paint(Trip.stops(), Trip.stop_index, Trip.apocalypse.land_tint())
	map_image.stretch_mode = TextureRect.STRETCH_SCALE
	map_image.size = holder.custom_minimum_size
	map_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(map_image)
	var stop := Trip.current_stop()
	var pixel := MapPainter.to_pixel(float(stop["lon"]), float(stop["lat"]))
	_marker = ColorRect.new()
	_marker.color = UiKit.DANGER
	_marker.size = Vector2(5, 5) * MAP_SCALE
	_marker.position = Vector2(pixel) * MAP_SCALE - _marker.size / 2.0
	holder.add_child(_marker)
	column.add_child(UiKit.label("Apocalypse: %s" % Trip.apocalypse.title(), 11, UiKit.DANGER))


func _build_status(root: Control) -> void:
	var status := UiKit.panel(Vector2(230, 0))
	UiKit.pin(status, root, Vector2(1, 0), Vector2(-240, 10))
	var column := UiKit.vbox(3)
	status.add_child(column)
	var stop := Trip.current_stop()
	column.add_child(UiKit.label(Trip.stop_label(stop), 15, UiKit.ACCENT))
	var next := Trip.next_stop()
	if not next.is_empty():
		column.add_child(UiKit.label("Next: %s (%d mi)" % [Trip.stop_label(next), next["miles"]], 10, UiKit.DIM))
	column.add_child(UiKit.wrapped(UiKit.supplies_text(), 10, UiKit.TEXT, 214))
	var vehicle_row := UiKit.hbox(4)
	vehicle_row.add_child(UiKit.label(UiKit.vehicle_text(), 10))
	if Trip.has_vehicle:
		var repair := UiKit.button("Repair (%d scrap)" % Trip.REPAIR_SCRAP_COST, _on_repair, 9)
		repair.disabled = not Trip.can_repair()
		vehicle_row.add_child(repair)
	column.add_child(vehicle_row)
	column.add_child(UiKit.label("Party", 12, UiKit.ACCENT))
	for index: int in Trip.party.size():
		column.add_child(_survivor_row(index))
	column.add_child(UiKit.label("Medkits: %d" % Trip.medkits, 9, UiKit.DIM))
	_add_actions(column)


func _survivor_row(index: int) -> VBoxContainer:
	var survivor := Trip.party[index]
	var block := UiKit.vbox(1)
	block.add_child(UiKit.party_row(survivor, index == Trip.active_index))
	var buttons := UiKit.hbox(3)
	if not survivor.is_downed() and index != Trip.active_index:
		buttons.add_child(UiKit.button("Lead", _on_lead.bind(index), 9))
	if survivor.is_downed():
		var revive := UiKit.button("Revive (medkit)", _on_treat.bind(survivor), 9)
		revive.disabled = Trip.medkits <= 0
		buttons.add_child(revive)
	elif survivor.health < Survivor.MAX_HEALTH:
		var heal := UiKit.button("Heal (medkit)", _on_treat.bind(survivor), 9)
		heal.disabled = Trip.medkits <= 0
		buttons.add_child(heal)
	if buttons.get_child_count() > 0:
		block.add_child(buttons)
	return block


func _add_actions(column: VBoxContainer) -> void:
	var stop := Trip.current_stop()
	var kind: int = stop["kind"]
	var standing := Trip.anyone_standing()
	if kind == Routes.Kind.FINISH:
		column.add_child(UiKit.button("Roll into %s" % stop["city"], _on_finish, 13))
		return
	if kind == Routes.Kind.SCAVENGE and not Trip.stop_scavenged:
		var scavenge := UiKit.button("Scavenge %s" % stop["city"], _on_scavenge, 12)
		scavenge.disabled = not standing
		column.add_child(scavenge)
	if kind == Routes.Kind.TOWN or kind == Routes.Kind.START:
		column.add_child(UiKit.button("Visit the store", Trip.go.bind("town"), 12))
	var next := Trip.next_stop()
	var travel_text := "Drive to %s" if Trip.has_vehicle else "Walk to %s"
	var travel := UiKit.button(travel_text % next["city"], _on_travel, 13)
	travel.disabled = not standing
	column.add_child(travel)
	if not standing:
		column.add_child(UiKit.wrapped("Everyone is down. Use a medkit to get someone up.", 9, UiKit.DANGER, 214))


func _build_log(root: Control) -> void:
	var log_panel := UiKit.panel(Vector2(MapPainter.WIDTH * MAP_SCALE + 16, 0))
	UiKit.pin(log_panel, root, Vector2(0, 1), Vector2(10, -96))
	var column := UiKit.vbox(1)
	log_panel.add_child(column)
	for message: String in Trip.messages.slice(-4):
		column.add_child(UiKit.wrapped(message, 9, UiKit.DIM, MapPainter.WIDTH * MAP_SCALE))


func _on_lead(index: int) -> void:
	Trip.active_index = index
	_build()


func _on_treat(survivor: Survivor) -> void:
	Trip.treat(survivor)
	Trip.ensure_active_standing()
	_build()


func _on_repair() -> void:
	Trip.repair_vehicle()
	_build()


func _on_scavenge() -> void:
	Trip.go("scavenge")


func _on_travel() -> void:
	Trip.go("road")


func _on_finish() -> void:
	Trip.won = true
	Trip.go("end")
