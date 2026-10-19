extends Node
## Player settings persisted in user://settings.cfg: language, sound
## (mute and volumes for master / music / effects), display (fullscreen,
## vsync) and gameplay readability (damage numbers, screen shake).
## Languages come from locale/translations.csv: adding a column there and
## its code here is all a new language needs.

const PATH := "user://settings.cfg"
const LANGUAGES: Array[String] = ["en", "sk", "cs"]

var language := "en"
var muted := false
var damage_numbers := true
var screen_shake := true
## Darker floor and a brighter halo around enemies.
var high_contrast := false
## Fewer hit sparks, death puffs and damage numbers (weaker laptops).
var low_effects := false
## Turned on by the game itself while the frame rate stays low (not saved).
var auto_low := false
var master_volume := 0.8
var music_volume := 0.7
var sfx_volume := 0.8
var fullscreen := false
var vsync := true
## Rebound movement keys: action -> physical keycode (replaces WASD; the
## arrow keys and the gamepad keep working).
var keys: Dictionary = {}
const REBINDABLE: Array[String] = ["move_up", "move_down", "move_left", "move_right"]


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		language = cfg.get_value("general", "language", language)
		muted = cfg.get_value("general", "muted", muted)
		damage_numbers = cfg.get_value("general", "damage_numbers", damage_numbers)
		screen_shake = cfg.get_value("general", "screen_shake", screen_shake)
		high_contrast = cfg.get_value("general", "high_contrast", high_contrast)
		low_effects = cfg.get_value("general", "low_effects", low_effects)
		master_volume = cfg.get_value("audio", "master", master_volume)
		music_volume = cfg.get_value("audio", "music", music_volume)
		sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
		fullscreen = cfg.get_value("display", "fullscreen", fullscreen)
		vsync = cfg.get_value("display", "vsync", vsync)
		keys = cfg.get_value("controls", "keys", {})
	for action: String in keys:
		_apply_key(action, keys[action])
	if language not in LANGUAGES:
		language = LANGUAGES[0]
	TranslationServer.set_locale(language)
	_apply_display()


func cycle_language() -> void:
	language = LANGUAGES[(LANGUAGES.find(language) + 1) % LANGUAGES.size()]
	TranslationServer.set_locale(language)
	_save()


func toggle_mute() -> void:
	muted = not muted
	apply_audio()
	_save()


func toggle_damage_numbers() -> void:
	damage_numbers = not damage_numbers
	_save()


func set_high_contrast(on: bool) -> void:
	high_contrast = on
	_save()


func set_low_effects(on: bool) -> void:
	low_effects = on
	_save()


## Share of the usual effect caps to use: less when the saver is on.
func effects_scale() -> float:
	return 0.35 if low_effects or auto_low else 1.0


func toggle_screen_shake() -> void:
	screen_shake = not screen_shake
	_save()


## bus: "master", "music" or "sfx"; value 0..1.
func set_volume(bus: String, value: float) -> void:
	match bus:
		"master":
			master_volume = value
		"music":
			music_volume = value
		"sfx":
			sfx_volume = value
	apply_audio()
	_save()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_display()
	_save()


func set_vsync(on: bool) -> void:
	vsync = on
	_apply_display()
	_save()


## Pushes mute and volumes to the audio buses (created by the Audio autoload).
func apply_audio() -> void:
	AudioServer.set_bus_mute(0, muted)
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)


func _set_bus(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))
	if bus_name != "Master":
		AudioServer.set_bus_mute(idx, value <= 0.001)


func _apply_display() -> void:
	# Headless test runs have no window to change.
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


func _save() -> void:
	# Automated test runs must never touch the real settings.
	if GameData.no_save():
		return
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("general", "language", language)
	cfg.set_value("general", "muted", muted)
	cfg.set_value("general", "damage_numbers", damage_numbers)
	cfg.set_value("general", "screen_shake", screen_shake)
	cfg.set_value("general", "high_contrast", high_contrast)
	cfg.set_value("general", "low_effects", low_effects)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "vsync", vsync)
	cfg.set_value("controls", "keys", keys)
	cfg.save(PATH)


## The first (main) key of a movement action, e.g. "W".
func key_name(action: String) -> String:
	for e: InputEvent in InputMap.action_get_events(action):
		if e is InputEventKey:
			return OS.get_keycode_string((e as InputEventKey).physical_keycode)
	return "—"


## Puts `keycode` in place of the action's first key and remembers it.
func rebind(action: String, keycode: int) -> void:
	keys[action] = keycode
	_apply_key(action, keycode)
	_save()


func reset_keys() -> void:
	for action: String in keys:
		_apply_key(action, {"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D}[action])
	keys.clear()
	_save()


func _apply_key(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	for e: InputEvent in InputMap.action_get_events(action):
		if e is InputEventKey:
			(e as InputEventKey).physical_keycode = keycode as Key
			return
