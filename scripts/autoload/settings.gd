extends Node
## Player settings persisted in user://settings.cfg (currently the language).
## Languages come from locale/translations.csv: adding a column there and
## its code here is all a new language needs.

const PATH := "user://settings.cfg"
const LANGUAGES: Array[String] = ["en", "sk"]

var language := "en"


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		language = cfg.get_value("general", "language", language)
	if language not in LANGUAGES:
		language = LANGUAGES[0]
	TranslationServer.set_locale(language)


func cycle_language() -> void:
	language = LANGUAGES[(LANGUAGES.find(language) + 1) % LANGUAGES.size()]
	TranslationServer.set_locale(language)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("general", "language", language)
	cfg.save(PATH)
