extends Node
## Progress that survives between runs: which cats are unlocked and which cat
## the player picked. Stored in user://profile.cfg.

const PATH := "user://profile.cfg"

var unlocked: Array[String] = []
var selected_cat := "MICA"


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for id: String in cfg.get_value("cats", "unlocked", []):
			unlocked.append(id)
		selected_cat = cfg.get_value("cats", "selected", selected_cat)
	for id: String in GameData.cats:
		if GameData.cats[id].get("unlocked", false) and id not in unlocked:
			unlocked.append(id)
	if selected_cat not in unlocked:
		selected_cat = "MICA"
	# Debug: `-- --cat=LUNA` plays any cat without unlocking it.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--cat="):
			selected_cat = arg.trim_prefix("--cat=")


func is_unlocked(cat_id: String) -> bool:
	return cat_id in unlocked


## Returns true if the cat was newly unlocked.
func unlock(cat_id: String) -> bool:
	if cat_id in unlocked:
		return false
	unlocked.append(cat_id)
	save()
	return true


func select(cat_id: String) -> void:
	selected_cat = cat_id
	save()


func save() -> void:
	# Automated test runs must never touch the real profile.
	if "--bot" in OS.get_cmdline_user_args():
		return
	var cfg := ConfigFile.new()
	cfg.set_value("cats", "unlocked", unlocked)
	cfg.set_value("cats", "selected", selected_cat)
	cfg.save(PATH)
