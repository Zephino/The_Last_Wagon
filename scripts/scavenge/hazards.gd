class_name Hazards
extends Node2D
## The hazards in a scavenging level: drawing them and hurting (or slowing)
## the player who walks into them. Enemies don't mind them.
##   fire      - hurts
##   spikes    - hurts more
##   toxic     - hurts a little and slows you
##   wire      - sparks on and off; hurts badly only while sparking
##   quicksand - slows you a lot and hurts a little
##   water     - slows you (no damage)

const DATA: Dictionary = {
	"fire": {"damage": 10, "slow": 1.0, "color": Color("e06020")},
	"spikes": {"damage": 12, "slow": 1.0, "color": Color("9a9aa0")},
	"toxic": {"damage": 6, "slow": 0.6, "color": Color("6ad040")},
	"wire": {"damage": 15, "slow": 1.0, "color": Color("f0e060")},
	"quicksand": {"damage": 4, "slow": 0.4, "color": Color("a08050")},
	"water": {"damage": 0, "slow": 0.55, "color": Color("3a6aa0")},
}
const WIRE_PERIOD := 2.4

var level: ScavengeScreen
var _list: Array[Dictionary] = []
var _time := 0.0


func setup(owner_level: ScavengeScreen, hazards: Array[Dictionary]) -> void:
	level = owner_level
	for hazard: Dictionary in hazards:
		var entry := hazard.duplicate()
		entry["node"] = _draw_hazard(hazard["rect"], hazard["kind"])
		_list.append(entry)


func _process(delta: float) -> void:
	_time += delta
	var sparking := wire_live()
	for hazard: Dictionary in _list:
		var node: Node2D = hazard["node"]
		match str(hazard["kind"]):
			"fire":
				node.modulate = Color(1, randf_range(0.7, 1.1), randf_range(0.6, 0.9))
			"wire":
				node.modulate = Color(1.3, 1.3, 1.0) if sparking else Color(0.35, 0.35, 0.3)


## Live wires spark for half of each cycle.
func wire_live() -> bool:
	return fmod(_time, WIRE_PERIOD) < WIRE_PERIOD / 2.0


## Applies any hazard the player is standing in: damage, and how much they're
## slowed (1.0 = normal speed).
func affect(player_box: Rect2) -> float:
	var slow := 1.0
	for hazard: Dictionary in _list:
		var rect: Rect2 = hazard["rect"]
		if not rect.intersects(player_box):
			continue
		var kind := str(hazard["kind"])
		var data: Dictionary = DATA[kind]
		slow = minf(slow, float(data["slow"]))
		if int(data["damage"]) > 0 and (kind != "wire" or wire_live()):
			level.player.hurt(int(data["damage"]))
	return slow


func _draw_hazard(rect: Rect2, kind: String) -> Node2D:
	var holder := Node2D.new()
	add_child(holder)
	var color: Color = DATA[kind]["color"]
	match kind:
		"spikes":
			var x := rect.position.x
			while x < rect.end.x - 1.0:
				var spike := Polygon2D.new()
				spike.color = color
				spike.polygon = PackedVector2Array([Vector2(x, rect.end.y), Vector2(x + 3, rect.position.y), Vector2(x + 6, rect.end.y)])
				holder.add_child(spike)
				x += 6.0
		"wire":
			holder.add_child(PixelArt.tiled(PixelArt.solid(Color("4a4a4a")), Vector2(rect.position.x, rect.end.y - 20), Vector2(2, 20)))
			holder.add_child(PixelArt.tiled(PixelArt.solid(color), Vector2(rect.position.x, rect.end.y - 3), Vector2(rect.size.x, 2)))
		"fire":
			var x := rect.position.x
			while x < rect.end.x - 1.0:
				var h := randf_range(4.0, 8.0)
				holder.add_child(PixelArt.tiled(PixelArt.solid(color), Vector2(x, rect.end.y - h), Vector2(3, h)))
				holder.add_child(PixelArt.tiled(PixelArt.solid(Color("ffd040")), Vector2(x + 1, rect.end.y - h * 0.5), Vector2(1, h * 0.5)))
				x += 3.0
		_:
			var pool := PixelArt.tiled(PixelArt.solid(color), rect.position, rect.size)
			pool.modulate = Color(1, 1, 1, 0.8)
			holder.add_child(pool)
	return holder
