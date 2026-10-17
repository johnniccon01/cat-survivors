extends Node
## Progress that survives between runs: gold, bought power-ups, unlocked
## cats, cleared stages, story flags and the last picked cat and stage.
## Stored in user://profile.cfg.

const PATH := "user://profile.cfg"
## The previous save, kept in case the main file gets damaged.
const BACKUP := "user://profile.bak.cfg"

var unlocked: Array[String] = []
var selected_cat := "MICA"
var selected_stage := "LIVING_ROOM"
var cleared_stages: Array[String] = []
var flags: Array[String] = []
var gold := 0
## Successful escapes/wins in a row (a death resets it) and the record.
var streak := 0
## Charms found and brought home, and the ones worn on the collar.
const CHARM_SLOTS := 3
## Gold given instead when you bring home a charm you already own.
const DUPLICATE_CHARM_GOLD := 50
var charms: Array[String] = []
## Lifetime counters for long-term goals ("kills", "kills:SOCK", "escapes"...)
var stats: Dictionary = {}
var goals_done: Array[String] = []
var equipped_charms: Array[String] = []
var best_streak := 0
## Gold spent on power-ups (refunded in full on request).
var spent := 0
## power-up id -> bought rank
var powerups: Dictionary = {}
## Quest book: line id -> steps done
var questbook: Dictionary = {}
## Challenges switched on for the next nights.
var challenges: Array[String] = []
## Artifacts earned from the quest book, and the ones taken into the night.
const ARTIFACT_SLOTS := 2
var artifacts: Array[String] = []
var equipped_artifacts: Array[String] = []


func _ready() -> void:
	var cfg := ConfigFile.new()
	# Automated tests start from a fresh profile, so their results don't depend
	# on how far the player has got.
	var args := GameData.args()
	var fresh := "--bot" in args or "--ui-test" in args
	var loaded := false
	if not fresh:
		loaded = cfg.load(PATH) == OK
		if not loaded and FileAccess.file_exists(BACKUP):
			# The profile is missing or broken: fall back to the last good one.
			loaded = cfg.load(BACKUP) == OK
			if loaded:
				push_warning("Profile: %s could not be read, using the backup" % PATH)
	if loaded:
		for id: String in cfg.get_value("cats", "unlocked", []):
			unlocked.append(id)
		selected_cat = cfg.get_value("cats", "selected", selected_cat)
		selected_stage = cfg.get_value("stages", "selected", selected_stage)
		for id: String in cfg.get_value("stages", "cleared", []):
			cleared_stages.append(id)
		for flag: String in cfg.get_value("story", "flags", []):
			flags.append(flag)
		gold = cfg.get_value("shop", "gold", 0)
		streak = cfg.get_value("streak", "current", 0)
		for id: String in cfg.get_value("charms", "owned", []):
			charms.append(id)
		stats = cfg.get_value("stats", "counters", {})
		for id: String in cfg.get_value("stats", "goals_done", []):
			goals_done.append(id)
		for id: String in cfg.get_value("charms", "equipped", []):
			equipped_charms.append(id)
		best_streak = cfg.get_value("streak", "best", 0)
		spent = cfg.get_value("shop", "spent", 0)
		powerups = cfg.get_value("shop", "powerups", {})
		questbook = cfg.get_value("questbook", "steps", {})
		for id: String in cfg.get_value("challenge", "active", []):
			if GameData.challenges.has(id):
				challenges.append(id)
		for id: String in cfg.get_value("artifacts", "owned", []):
			if GameData.artifacts.has(id):
				artifacts.append(id)
		for id: String in cfg.get_value("artifacts", "equipped", []):
			if id in artifacts:
				equipped_artifacts.append(id)
	for id: String in GameData.cats:
		if GameData.cats[id].get("unlocked", false) and id not in unlocked:
			unlocked.append(id)
	if selected_cat not in unlocked:
		selected_cat = "MICA"
	if not is_stage_unlocked(selected_stage):
		selected_stage = "LIVING_ROOM"
	# Debug: `-- --cat=LUNA` / `-- --stage=BASEMENT` skip unlocking,
	# `-- --challenges=HYPER,GLASS` sets challenges for this run.
	for arg: String in GameData.args():
		if arg.begins_with("--challenges="):
			challenges.clear()
			for id in arg.trim_prefix("--challenges=").split(",", false):
				challenges.append(id)
		# `-- --artifacts=HOURGLASS,THORN_COLLAR` owns and wears them.
		if arg.begins_with("--artifacts="):
			for id in arg.trim_prefix("--artifacts=").split(",", false):
				artifacts.append(id)
				equipped_artifacts.append(id)
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


## Bumps a lifetime counter in memory (saved with the next save()).
func add_stat(key: String, amount: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + amount


func set_stat_max(key: String, value: int) -> void:
	stats[key] = maxi(int(stats.get(key, 0)), value)


## Counter value; a few are computed from other profile data.
func get_stat(key: String) -> int:
	match key:
		"best_streak":
			return best_streak
		"cats_unlocked":
			return unlocked.size()
	return int(stats.get(key, 0))


func has_challenge(id: String) -> bool:
	return id in challenges


func toggle_challenge(id: String) -> void:
	if id in challenges:
		challenges.erase(id)
	else:
		challenges.append(id)
	save()


## Gold multiplier of all challenges switched on.
func challenge_gold() -> float:
	var mult := 1.0
	for id in challenges:
		mult *= float(GameData.challenges.get(id, {}).get("gold", 1.0))
	return mult


func has_charm(id: String) -> bool:
	return id in charms


## Brings charms home after an escape or a win. Returns the gold paid for
## duplicates.
func bank_charms(found: Array[String]) -> int:
	var gold_back := 0
	for id in found:
		if id in charms:
			gold_back += DUPLICATE_CHARM_GOLD
		else:
			charms.append(id)
	gold += gold_back
	save()
	return gold_back


## Wears or takes off a charm. Returns false when all slots are full.
func toggle_charm(id: String) -> bool:
	if not has_charm(id):
		return false
	if id in equipped_charms:
		equipped_charms.erase(id)
	elif equipped_charms.size() >= CHARM_SLOTS:
		return false
	else:
		equipped_charms.append(id)
	save()
	return true


func has_artifact(id: String) -> bool:
	return id in artifacts


## Returns true if the artifact is new.
func give_artifact(id: String) -> bool:
	if id in artifacts:
		return false
	artifacts.append(id)
	save()
	return true


## Takes an artifact along or leaves it home. Returns false when both slots
## are full.
func toggle_artifact(id: String) -> bool:
	if not has_artifact(id):
		return false
	if id in equipped_artifacts:
		equipped_artifacts.erase(id)
	elif equipped_artifacts.size() >= ARTIFACT_SLOTS:
		return false
	else:
		equipped_artifacts.append(id)
	save()
	return true


## Sum of the equipped artifacts per stat.
func artifact_bonus() -> Dictionary:
	var total := {}
	for id in equipped_artifacts:
		var bonus: Dictionary = GameData.artifacts.get(id, {}).get("stats", {})
		for key: String in bonus:
			total[key] = float(total.get(key, 0.0)) + float(bonus[key])
	return total


## Sum of the worn charms per stat.
func charm_bonus() -> Dictionary:
	var bonus := {}
	for id in equipped_charms:
		var data: Dictionary = GameData.charms.get(id, {})
		if not data.is_empty():
			bonus[data["stat"]] = bonus.get(data["stat"], 0.0) + float(data["value"])
	return bonus


## Gold bonus from the current streak: +10 % per step, up to +50 %.
func streak_multiplier() -> float:
	return 1.0 + 0.1 * mini(streak, 5)


func add_streak(steps: int) -> void:
	streak += steps
	best_streak = maxi(best_streak, streak)
	save()


func reset_streak() -> void:
	streak = 0
	save()


func add_gold(amount: int) -> void:
	gold += amount
	save()


func powerup_rank(id: String) -> int:
	return int(powerups.get(id, 0))


func total_ranks() -> int:
	var n := 0
	for id: String in powerups:
		n += int(powerups[id])
	return n


## Price of the next rank: grows with the rank and with everything bought so
## far (like Vampire Survivors), so the order you buy in matters a little.
func powerup_cost(id: String) -> int:
	var base := float(GameData.powerups[id]["base_cost"])
	return roundi(base * (powerup_rank(id) + 1) * (1.0 + 0.1 * total_ranks()))


func buy_powerup(id: String) -> bool:
	var data: Dictionary = GameData.powerups[id]
	if powerup_rank(id) >= int(data["max_rank"]):
		return false
	var cost := powerup_cost(id)
	if gold < cost:
		return false
	gold -= cost
	spent += cost
	powerups[id] = powerup_rank(id) + 1
	save()
	return true


## Gives back everything spent on power-ups.
func refund_powerups() -> void:
	gold += spent
	spent = 0
	powerups = {}
	save()


## Sum of all bought power-ups per stat.
func powerup_bonus() -> Dictionary:
	var bonus := {}
	for id: String in powerups:
		var data: Dictionary = GameData.powerups.get(id, {})
		if data.is_empty():
			continue
		bonus[data["stat"]] = bonus.get(data["stat"], 0.0) + float(data["per_rank"]) * int(powerups[id])
	return bonus


func has_flag(flag: String) -> bool:
	return flag in flags


func set_flag(flag: String) -> void:
	if flag not in flags:
		flags.append(flag)
		save()


func save() -> void:
	# Automated test runs must never touch the real profile.
	if GameData.no_save():
		return
	var cfg := ConfigFile.new()
	cfg.set_value("cats", "unlocked", unlocked)
	cfg.set_value("cats", "selected", selected_cat)
	cfg.set_value("stages", "selected", selected_stage)
	cfg.set_value("stages", "cleared", cleared_stages)
	cfg.set_value("story", "flags", flags)
	cfg.set_value("shop", "gold", gold)
	cfg.set_value("streak", "current", streak)
	cfg.set_value("charms", "owned", charms)
	cfg.set_value("stats", "counters", stats)
	cfg.set_value("stats", "goals_done", goals_done)
	cfg.set_value("charms", "equipped", equipped_charms)
	cfg.set_value("streak", "best", best_streak)
	cfg.set_value("shop", "spent", spent)
	cfg.set_value("shop", "powerups", powerups)
	cfg.set_value("questbook", "steps", questbook)
	cfg.set_value("challenge", "active", challenges)
	cfg.set_value("artifacts", "owned", artifacts)
	cfg.set_value("artifacts", "equipped", equipped_artifacts)
	# Keep the last good save before writing the new one.
	if FileAccess.file_exists(PATH):
		var previous := ConfigFile.new()
		if previous.load(PATH) == OK:
			DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(BACKUP))
	cfg.save(PATH)
