class_name UiKit
extends RefCounted
## Small helpers for building menus and HUDs in code with one shared look.

const TEXT := Color("ece3d0")
const DIM := Color("a89f8c")
const ACCENT := Color("f0b040")
const DANGER := Color("e05a3a")
const GOOD := Color("7ac060")
const PANEL := Color(0.06, 0.05, 0.07, 0.82)


## A full-screen layer for UI on top of the world. Add controls to .get_child(0).
static func make_layer(host: Node) -> Control:
	var layer := CanvasLayer.new()
	host.add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	return root


static func label(text: String, size := 12, color := TEXT) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	result.add_theme_constant_override("shadow_offset_x", 1)
	result.add_theme_constant_override("shadow_offset_y", 1)
	return result


static func wrapped(text: String, size := 11, color := TEXT, width := 200.0) -> Label:
	var result := label(text, size, color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size = Vector2(width, 0)
	return result


static func button(text: String, on_press: Callable, size := 12) -> Button:
	var result := Button.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.focus_mode = Control.FOCUS_NONE
	result.pressed.connect(on_press)
	return result


static func panel(min_size := Vector2.ZERO) -> PanelContainer:
	var result := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color(1, 1, 1, 0.12)
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	result.add_theme_stylebox_override("panel", style)
	result.custom_minimum_size = min_size
	return result


static func vbox(gap := 4) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.add_theme_constant_override("separation", gap)
	return result


static func hbox(gap := 6) -> HBoxContainer:
	var result := HBoxContainer.new()
	result.add_theme_constant_override("separation", gap)
	return result


## A thin health-style bar. value and max_value set how full it is.
static func bar(value: float, max_value: float, fill: Color, size := Vector2(80, 6)) -> ProgressBar:
	var result := ProgressBar.new()
	result.max_value = max_value
	result.value = value
	result.show_percentage = false
	result.custom_minimum_size = size
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.6)
	var front := StyleBoxFlat.new()
	front.bg_color = fill
	result.add_theme_stylebox_override("background", back)
	result.add_theme_stylebox_override("fill", front)
	return result


## Adds a control pinned to a point of the screen. anchor is (0..1, 0..1):
## (0, 0) top-left, (0.5, 0) top-center, (1, 1) bottom-right. offset moves
## its top-left corner from that point, in pixels.
static func pin(control: Control, parent: Control, anchor: Vector2, offset: Vector2, size := Vector2.ZERO) -> Control:
	parent.add_child(control)
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x + size.x
	control.offset_bottom = offset.y + size.y
	return control


static func clear(container: Node) -> void:
	for child: Node in container.get_children():
		child.queue_free()


## One line per supply, for HUDs and the map.
static func supplies_text() -> String:
	return "Food %d   Fuel %.0f   Ammo %d   Medkits %d   Scrap %d   $%d" % [
		Trip.food, ceilf(Trip.fuel), Trip.ammo, Trip.medkits, Trip.scrap, Trip.money]


static func vehicle_text() -> String:
	if Trip.has_vehicle:
		return "Car: %d%%" % Trip.vehicle_health
	return "On foot"


static func party_row(survivor: Survivor, is_active: bool) -> HBoxContainer:
	var row := hbox(4)
	var marker := ">" if is_active else " "
	var color := DANGER if survivor.is_downed() else (ACCENT if is_active else TEXT)
	var status := "DOWN" if survivor.is_downed() else "%d" % survivor.health
	var name_label := label("%s %s (%s)" % [marker, survivor.name, survivor.role_name()], 10, color)
	name_label.custom_minimum_size = Vector2(130, 0)
	row.add_child(name_label)
	var health_bar := bar(survivor.health, Survivor.MAX_HEALTH, GOOD if survivor.health > 35 else DANGER, Vector2(50, 5))
	health_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(health_bar)
	row.add_child(label(status, 9, color))
	return row
