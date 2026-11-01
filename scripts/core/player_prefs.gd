class_name PlayerPrefs
extends RefCounted
## Small things remembered between visits, saved on this device only
## (for example the leaderboard name).

const PATH := "user://prefs.cfg"


static func get_value(key: String, default: Variant) -> Variant:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return default
	return config.get_value("player", key, default)


static func set_value(key: String, value: Variant) -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value("player", key, value)
	config.save(PATH)
