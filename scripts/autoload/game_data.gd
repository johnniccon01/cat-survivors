extends Node
## Loads all JSON game data once at startup and registers input actions.
## Content (weapons, enemies, stage waves) lives in res://data so it can be
## tweaked without touching code.

var weapons: Dictionary = {}
var passives: Dictionary = {}
var enemies: Dictionary = {}
var stages: Dictionary = {}
var props: Dictionary = {}
var cats: Dictionary = {}
var quests: Dictionary = {}
var powerups: Dictionary = {}
var charms: Dictionary = {}
var artifacts: Dictionary = {}
var chains: Dictionary = {}
var traps: Dictionary = {}
var goals: Dictionary = {}
var questbook: Dictionary = {}
## base weapon id -> branch id -> {ranks: [effect, effect]}
var branches: Dictionary = {}
## Champion affixes: id -> {hp, speed, damage, taken, scale, split, regen, bomb, color}
var champions: Dictionary = {}
## Challenges: id -> {gold}
var challenges: Dictionary = {}
## Weighted drop table for broken props: [{kind, weight, value}]
var loot: Array = []


func _ready() -> void:
	weapons = _load_json("res://data/weapons.json")
	passives = _load_json("res://data/passives.json")
	cats = _load_json("res://data/cats.json")
	quests = _load_json("res://data/quests.json")
	powerups = _load_json("res://data/powerups.json")
	charms = _load_json("res://data/charms.json")
	artifacts = _load_json("res://data/artifacts.json")
	chains = _load_json("res://data/chains.json")
	traps = _load_json("res://data/traps.json")
	goals = _load_json("res://data/goals.json")
	questbook = _load_json("res://data/questbook.json")
	branches = _load_json("res://data/branches.json")
	champions = _load_json("res://data/champions.json")
	challenges = _load_json("res://data/challenges.json")
	var props_file := _load_json("res://data/props.json")
	props = props_file.get("props", {})
	loot = props_file.get("loot", [])
	enemies = _load_json("res://data/enemies.json")
	stages = _load_json("res://data/stages.json")
	_setup_input()



## Command-line flags (after --). Only in debug builds: a released game
## ignores every testing and cheat flag.
static func args() -> PackedStringArray:
	return OS.get_cmdline_user_args() if OS.is_debug_build() else PackedStringArray()


## Test runs (--bot, --ui-test, --no-save) never write the profile or settings.
static func no_save() -> bool:
	var args := GameData.args()
	return "--bot" in args or "--ui-test" in args or "--no-save" in args

func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameData: failed to parse %s" % path)
		return {}
	return parsed


func _setup_input() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("move_up", [KEY_W, KEY_UP])
	_add_keys("move_down", [KEY_S, KEY_DOWN])
	_add_keys("pause", [KEY_ESCAPE, KEY_P])
	_add_keys("restart", [KEY_R, KEY_ENTER])
	_add_keys("language", [KEY_L])
	_add_keys("mute", [KEY_M])
	_add_keys("shop", [KEY_U])
	_add_keys("reroll", [KEY_R])
	_add_keys("charms", [KEY_C])
	_add_keys("artifacts", [KEY_V])
	_add_keys("goals", [KEY_G])
	_add_keys("questbook", [KEY_Q])
	_add_keys("journal", [KEY_J])
	_add_keys("endless", [KEY_E])
	_add_keys("challenges", [KEY_X])
	_add_keys("toggle_numbers", [KEY_N])
	_add_keys("toggle_shake", [KEY_K])
	_add_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_button("pause", JOY_BUTTON_START)
	_add_button("restart", JOY_BUTTON_A)
	# Godot's menu actions have no gamepad face buttons by default: A confirms,
	# B goes back (and works like Esc in our panels).
	_add_button("ui_accept", JOY_BUTTON_A)
	_add_button("ui_cancel", JOY_BUTTON_B)
	_add_button("pause", JOY_BUTTON_B)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)


func _add_keys(action: String, keys: Array) -> void:
	_ensure_action(action)
	for key: Key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func _add_axis(action: String, axis: JoyAxis, value: float) -> void:
	_ensure_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)


func _add_button(action: String, button: JoyButton) -> void:
	_ensure_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
