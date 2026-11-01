extends Node
## Autoload "Progress". What you keep between trips (the game is a roguelike:
## each trip is a fresh run): earned awards and running totals. Saved on this
## device in user://progress.json. Shows a short pop-up when an award is earned.

signal award_earned(award: Dictionary)

const DEFAULT_PATH := "user://progress.json"
const TOAST_TIME := 4.0

var awards: Dictionary = {}
var stats: Dictionary = {}
var _path := DEFAULT_PATH
var _toast: Label
var _toast_panel: PanelContainer
var _toast_left := 0.0


func _ready() -> void:
	load_progress()
	_build_toast()


func _process(delta: float) -> void:
	if _toast_left <= 0.0:
		return
	_toast_left -= delta
	_toast_panel.visible = _toast_left > 0.0


## Tests use their own file so they never touch real progress.
func use_test_file(path: String) -> void:
	_path = path if path != "" else DEFAULT_PATH
	awards.clear()
	stats.clear()
	if path != "":
		DirAccess.remove_absolute(path)
	load_progress()


func load_progress() -> void:
	awards.clear()
	stats.clear()
	if not FileAccess.file_exists(_path):
		return
	var file := FileAccess.open(_path, FileAccess.READ)
	var json := JSON.new()
	if file == null or json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return
	var data: Dictionary = json.data
	if data.get("awards") is Dictionary:
		awards = data["awards"]
	if data.get("stats") is Dictionary:
		stats = data["stats"]


func save_progress() -> void:
	var file := FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"awards": awards, "stats": stats}, "\t"))


## What goes online (leaderboard-api/src/cloud.js needs "save_version").
func to_save() -> Dictionary:
	return {"save_version": 1, "awards": awards.duplicate(), "stats": stats.duplicate()}


## Combines progress from another device: every award from both is kept
## (with the earliest date) and each total keeps the higher number. Nothing
## is ever lost. Returns true when anything here changed.
func merge(save: Dictionary) -> bool:
	var changed := false
	var other_awards: Variant = save.get("awards", {})
	if other_awards is Dictionary:
		for award_id: String in other_awards:
			if Unlocks.award(award_id).is_empty():
				continue
			var when := str(other_awards[award_id])
			if not awards.has(award_id) or when < str(awards[award_id]):
				awards[award_id] = when
				changed = true
	var other_stats: Variant = save.get("stats", {})
	if other_stats is Dictionary:
		for stat_id: String in other_stats:
			var value := int(other_stats[stat_id])
			if value > stat(stat_id):
				stats[stat_id] = value
				changed = true
	if changed:
		save_progress()
	return changed


func has_award(award_id: String) -> bool:
	return awards.has(award_id)


## Earns an award (once). Returns true the first time.
func earn(award_id: String) -> bool:
	var entry := Unlocks.award(award_id)
	if entry.is_empty() or awards.has(award_id):
		return false
	awards[award_id] = Time.get_datetime_string_from_system(true)
	save_progress()
	_show_toast(entry)
	award_earned.emit(entry)
	return true


func stat(stat_id: String) -> int:
	return int(stats.get(stat_id, 0))


## Adds to a running total and earns any award that total reaches.
func add_stat(stat_id: String, amount := 1) -> void:
	stats[stat_id] = stat(stat_id) + amount
	save_progress()
	match stat_id:
		"crates":
			if stat("crates") >= 25:
				earn("crates_25")
		"enemies":
			if stat("enemies") >= 100:
				earn("kills_100")
		"stashes":
			earn("stash_1")
			if stat("stashes") >= 5:
				earn("stash_5")


## True when a route, survivor role, perk or car color can be used.
func is_unlocked(kind: String, thing_id: String) -> bool:
	if Array(Unlocks.FREE.get(kind, [])).has(thing_id):
		return true
	var entry := Unlocks.award_for(kind, thing_id)
	return not entry.is_empty() and has_award(entry["id"])


## Called once when a trip ends (win or lose): checks the end-of-trip awards.
func record_trip_end(won: bool, route_id: String, days: int, standing: int, party_size: int,
		on_foot: bool, mixed: bool) -> void:
	add_stat("trips")
	if not won:
		if standing == 0:
			earn("wiped_out")
		return
	add_stat("finished")
	earn("finish_any")
	earn("finish_" + route_id)
	if standing == party_size:
		earn("full_house")
	if on_foot:
		earn("on_foot")
	if days <= 12:
		earn("speed_demon")
	if mixed:
		earn("mixed_finish")


func _build_toast() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_toast_panel = UiKit.panel(Vector2(300, 0))
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.pin(_toast_panel, root, Vector2(0.5, 0), Vector2(-150, 6))
	_toast = UiKit.wrapped("", 11, UiKit.ACCENT, 284)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_panel.add_child(_toast)
	_toast_panel.visible = false


func _show_toast(entry: Dictionary) -> void:
	_toast.text = "AWARD: %s\n%s" % [entry["name"], Unlocks.describe_unlock(entry["unlock"])]
	_toast_panel.visible = true
	_toast_left = TOAST_TIME
