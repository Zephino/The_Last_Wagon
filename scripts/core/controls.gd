extends Node
## Autoload "Controls". Registers the game's input actions (keyboard and
## gamepad) at start-up, so every screen can use the same action names.

const ACTIONS: Dictionary = {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE, KEY_W, KEY_UP],
	"fire": [KEY_F, KEY_J, KEY_CTRL],
	"switch_survivor": [KEY_TAB],
	"interact": [KEY_E],
	"prev_weapon": [KEY_Q],
	"next_weapon": [KEY_E],
	"weapon_1": [KEY_1],
	"weapon_2": [KEY_2],
	"weapon_3": [KEY_3],
	"weapon_4": [KEY_4],
	"weapon_5": [KEY_5],
	"weapon_6": [KEY_6],
	"back": [KEY_ESCAPE],
}

const PAD_BUTTONS: Dictionary = {
	"jump": [JOY_BUTTON_A],
	"fire": [JOY_BUTTON_X],
	"switch_survivor": [JOY_BUTTON_Y],
	"prev_weapon": [JOY_BUTTON_LEFT_SHOULDER],
	"next_weapon": [JOY_BUTTON_RIGHT_SHOULDER],
	"interact": [JOY_BUTTON_B],
	"back": [JOY_BUTTON_START],
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
}

const PAD_AXES: Dictionary = {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}


func _ready() -> void:
	for action: String in ACTIONS:
		_register(action)


func _register(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for key: int in ACTIONS[action]:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key as Key
		InputMap.action_add_event(action, key_event)
	for button: int in PAD_BUTTONS.get(action, []):
		var pad_event := InputEventJoypadButton.new()
		pad_event.button_index = button as JoyButton
		InputMap.action_add_event(action, pad_event)
	if PAD_AXES.has(action):
		var axis_event := InputEventJoypadMotion.new()
		axis_event.axis = PAD_AXES[action][0] as JoyAxis
		axis_event.axis_value = PAD_AXES[action][1]
		InputMap.action_add_event(action, axis_event)


## -1 when only left is held, 1 when only right is held, 0 otherwise.
static func horizontal() -> float:
	return Input.get_axis("move_left", "move_right")
