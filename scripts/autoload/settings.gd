extends Node
## Player settings persisted in user://settings.cfg: language and sound on/off.
## Languages come from locale/translations.csv: adding a column there and
## its code here is all a new language needs.

const PATH := "user://settings.cfg"
const LANGUAGES: Array[String] = ["en", "sk"]

var language := "en"
var muted := false
var damage_numbers := true
var screen_shake := true


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		language = cfg.get_value("general", "language", language)
		muted = cfg.get_value("general", "muted", muted)
		damage_numbers = cfg.get_value("general", "damage_numbers", damage_numbers)
		screen_shake = cfg.get_value("general", "screen_shake", screen_shake)
	if language not in LANGUAGES:
		language = LANGUAGES[0]
	TranslationServer.set_locale(language)


func cycle_language() -> void:
	language = LANGUAGES[(LANGUAGES.find(language) + 1) % LANGUAGES.size()]
	TranslationServer.set_locale(language)
	_save()


func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	_save()


func toggle_damage_numbers() -> void:
	damage_numbers = not damage_numbers
	_save()


func toggle_screen_shake() -> void:
	screen_shake = not screen_shake
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("general", "language", language)
	cfg.set_value("general", "muted", muted)
	cfg.set_value("general", "damage_numbers", damage_numbers)
	cfg.set_value("general", "screen_shake", screen_shake)
	cfg.save(PATH)
