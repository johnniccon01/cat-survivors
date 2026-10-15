extends Node
## Progress that survives between runs: unlocked cats, cleared stages, story
## flags and the last picked cat and stage. Stored in user://profile.cfg.

const PATH := "user://profile.cfg"

var unlocked: Array[String] = []
var selected_cat := "MICA"
var selected_stage := "LIVING_ROOM"
var cleared_stages: Array[String] = []
var flags: Array[String] = []


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for id: String in cfg.get_value("cats", "unlocked", []):
			unlocked.append(id)
		selected_cat = cfg.get_value("cats", "selected", selected_cat)
		selected_stage = cfg.get_value("stages", "selected", selected_stage)
		for id: String in cfg.get_value("stages", "cleared", []):
			cleared_stages.append(id)
		for flag: String in cfg.get_value("story", "flags", []):
			flags.append(flag)
	for id: String in GameData.cats:
		if GameData.cats[id].get("unlocked", false) and id not in unlocked:
			unlocked.append(id)
	if selected_cat not in unlocked:
		selected_cat = "MICA"
	if not is_stage_unlocked(selected_stage):
		selected_stage = "LIVING_ROOM"
	# Debug: `-- --cat=LUNA` / `-- --stage=BASEMENT` skip unlocking.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--cat="):
			selected_cat = arg.trim_prefix("--cat=")
		elif arg.begins_with("--stage="):
			selected_stage = arg.trim_prefix("--stage=")


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


func select_stage(stage_id: String) -> void:
	selected_stage = stage_id
	save()


## A stage is open when the stage it requires has been cleared.
func is_stage_unlocked(stage_id: String) -> bool:
	var stage: Dictionary = GameData.stages.get(stage_id, {})
	var required: String = stage.get("requires", "")
	return required == "" or required in cleared_stages


## Returns true if this was the first clear.
func clear_stage(stage_id: String) -> bool:
	if stage_id in cleared_stages:
		return false
	cleared_stages.append(stage_id)
	save()
	return true


func has_flag(flag: String) -> bool:
	return flag in flags


func set_flag(flag: String) -> void:
	if flag not in flags:
		flags.append(flag)
		save()


func save() -> void:
	# Automated test runs must never touch the real profile.
	if "--bot" in OS.get_cmdline_user_args():
		return
	var cfg := ConfigFile.new()
	cfg.set_value("cats", "unlocked", unlocked)
	cfg.set_value("cats", "selected", selected_cat)
	cfg.set_value("stages", "selected", selected_stage)
	cfg.set_value("stages", "cleared", cleared_stages)
	cfg.set_value("story", "flags", flags)
	cfg.save(PATH)
