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
## Charm quality 1-4 (Death Must Die-like item quality): each step above 1
## makes the charm 35 % stronger. Finding a better copy upgrades yours.
const MAX_CHARM_QUALITY := 4
const CHARM_QUALITY_STEP := 0.35
var charm_quality: Dictionary = {}
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
## Gear (see Items): every item you own, which one is worn in each slot
## (slot -> uid), and the next uid to give out. The stash holds ITEM_STASH
## items; anything brought home past that is melted into gold.
const ITEM_STASH := 40
var items: Array = []
var equipped_items: Dictionary = {}
var next_item_uid := 1
## The daily night: while it runs, `challenges` holds today's challenges and
## the player's own choice waits in _daily_backup (and is what gets saved).
const DAILY_GOLD := 500
var daily := false
var _daily_backup: Array[String] = []
## Quest chains: chain id -> steps done.
var chains: Dictionary = {}
## Earned achievement ids.
var achievements: Array[String] = []
## Darkness (Death Must Die-like): per map, the level picked for the next
## night and the highest level won there. Each level makes enemies tougher
## and pays more gold; winning one opens the next.
const MAX_DARKNESS := 5
var darkness: Dictionary = {}
var darkness_best: Dictionary = {}


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
		darkness = cfg.get_value("darkness", "selected", {})
		darkness_best = cfg.get_value("darkness", "best", {})
		for flag: String in cfg.get_value("story", "flags", []):
			flags.append(flag)
		gold = cfg.get_value("shop", "gold", 0)
		streak = cfg.get_value("streak", "current", 0)
		for id: String in cfg.get_value("charms", "owned", []):
			charms.append(id)
		charm_quality = cfg.get_value("charms", "quality", {})
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
		chains = cfg.get_value("chains", "steps", {})
		for id: String in cfg.get_value("achievements", "earned", []):
			achievements.append(id)
		for id: String in cfg.get_value("artifacts", "owned", []):
			if GameData.artifacts.has(id):
				artifacts.append(id)
		items = cfg.get_value("items", "owned", [])
		equipped_items = cfg.get_value("items", "equipped", {})
		next_item_uid = cfg.get_value("items", "next_uid", 1)
		_clean_items()
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
		if arg == "--daily":
			start_daily()
		# `-- --chain-step=KIBBLE_THIEF:2` marks two steps of a chain done.
		if arg.begins_with("--chain-step="):
			var parts := arg.trim_prefix("--chain-step=").split(":")
			chains[parts[0]] = int(parts[1])
		# `-- --artifacts=HOURGLASS,THORN_COLLAR` owns and wears them.
		if arg.begins_with("--artifacts="):
			for id in arg.trim_prefix("--artifacts=").split(",", false):
				artifacts.append(id)
				equipped_artifacts.append(id)
		# `-- --gear=RAT_CROWN,rare` owns and wears those legendaries and
		# random items of those rarities.
		if arg.begins_with("--gear="):
			for id in arg.trim_prefix("--gear=").split(",", false):
				var item := Items.legendary(id) if GameData.items["legendaries"].has(id) else Items.roll(1.0, id)
				item["uid"] = next_item_uid
				next_item_uid += 1
				items.append(item)
				equipped_items[item["slot"]] = item["uid"]
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


## The highest darkness that can be picked on a map: one above the best
## won there, once the map has been cleared at all.
func max_darkness(stage_id: String) -> int:
	if stage_id not in cleared_stages:
		return 0
	return mini(int(darkness_best.get(stage_id, 0)) + 1, MAX_DARKNESS)


## The darkness of the next night on `stage_id` (--darkness=N in tests;
## the daily night is always plain).
func darkness_for(stage_id: String) -> int:
	var forced := GameData.arg("--darkness=", "")
	if forced != "":
		return int(forced)
	if daily:
		return 0
	return clampi(int(darkness.get(stage_id, 0)), 0, max_darkness(stage_id))


func set_darkness(stage_id: String, level: int) -> void:
	darkness[stage_id] = clampi(level, 0, max_darkness(stage_id))
	save()


## Records a won darkness; true if it was a new best.
func win_darkness(stage_id: String, level: int) -> bool:
	if level <= int(darkness_best.get(stage_id, 0)):
		return false
	darkness_best[stage_id] = level
	save()
	return true


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


## Today's date, e.g. "2026-10-18" (the daily night's seed).
static func today() -> String:
	return Time.get_date_string_from_system()


## Today's map (an open one) and two challenges, the same all day.
func daily_plan() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("daily" + today())
	var maps: Array = GameData.stages.keys().filter(func(s: String) -> bool: return is_stage_unlocked(s))
	var pool: Array = GameData.challenges.keys()
	var picked: Array[String] = []
	while picked.size() < mini(2, pool.size()):
		var c: String = pool[rng.randi() % pool.size()]
		if c not in picked:
			picked.append(c)
	return {"stage": maps[rng.randi() % maps.size()], "challenges": picked, "seed": hash("night" + today())}


func start_daily() -> void:
	var plan := daily_plan()
	daily = true
	_daily_backup = challenges.duplicate()
	challenges.clear()
	for c: String in plan["challenges"]:
		challenges.append(c)
	selected_stage = plan["stage"]


func end_daily() -> void:
	if not daily:
		return
	daily = false
	challenges = _daily_backup.duplicate()
	_daily_backup.clear()


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


func quality_of(id: String) -> int:
	return int(charm_quality.get(id, 1))


## How much stronger a charm of this quality is than a plain one.
static func quality_mult(quality: int) -> float:
	return 1.0 + CHARM_QUALITY_STEP * (quality - 1)


## Brings charms home after an escape or a win (`quality` matches `found`).
## A better copy of a charm you own upgrades it; any other copy pays gold.
## Returns the gold paid for duplicates; `upgraded` gets the improved ids.
func bank_charms(found: Array[String], quality: Array[int] = [], upgraded: Array[String] = []) -> int:
	var gold_back := 0
	for i in found.size():
		var id := found[i]
		var q: int = quality[i] if i < quality.size() else 1
		if id in charms:
			if q > quality_of(id):
				charm_quality[id] = q
				upgraded.append(id)
			else:
				gold_back += DUPLICATE_CHARM_GOLD
		else:
			charms.append(id)
			charm_quality[id] = q
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


## Brings items home from a run (gets them uids). Past the stash size they
## are melted into gold; returns that gold.
func bank_items(found: Array) -> int:
	var gold_back := 0
	for item: Dictionary in found:
		if items.size() >= ITEM_STASH:
			gold_back += Items.salvage_gold(item)
			continue
		var kept := item.duplicate(true)
		kept["uid"] = next_item_uid
		next_item_uid += 1
		items.append(kept)
	add_gold(gold_back)
	save()
	return gold_back


func item_by_uid(uid: int) -> Dictionary:
	for item: Dictionary in items:
		if int(item["uid"]) == uid:
			return item
	return {}


## The item worn in a slot (empty when none).
func worn_item(slot: String) -> Dictionary:
	return item_by_uid(int(equipped_items.get(slot, 0)))


## Puts an item on (taking off whatever was in its slot), or takes it off
## when it is already worn.
func toggle_item(uid: int) -> void:
	var item := item_by_uid(uid)
	if item.is_empty():
		return
	var slot: String = item["slot"]
	if int(equipped_items.get(slot, 0)) == uid:
		equipped_items.erase(slot)
	else:
		equipped_items[slot] = uid
	save()


## Melts an item down for gold (taking it off first).
func salvage_item(uid: int) -> int:
	var item := item_by_uid(uid)
	if item.is_empty():
		return 0
	if int(equipped_items.get(item["slot"], 0)) == uid:
		equipped_items.erase(item["slot"])
	items.erase(item)
	var gold_back := Items.salvage_gold(item)
	add_gold(gold_back)
	save()
	return gold_back


## Sum of the worn items per stat.
func item_bonus() -> Dictionary:
	var bonus := {}
	for slot: String in equipped_items:
		var item := worn_item(slot)
		if item.is_empty():
			continue
		var stats: Dictionary = item["stats"]
		for key: String in stats:
			if key in Items.TIMERS and bonus.has(key):
				bonus[key] = minf(float(bonus[key]), float(stats[key]))
			else:
				bonus[key] = float(bonus.get(key, 0.0)) + float(stats[key])
	return bonus


## Drops items whose base no longer exists and slots pointing at nothing,
## so a changed items.json never breaks an old profile.
func _clean_items() -> void:
	items = items.filter(func(item: Variant) -> bool: return item is Dictionary and not Items.info(item).is_empty())
	for slot: String in equipped_items.keys():
		if worn_item(slot).is_empty():
			equipped_items.erase(slot)


## Sum of the worn charms per stat.
func charm_bonus() -> Dictionary:
	var bonus := {}
	for id in equipped_charms:
		var data: Dictionary = GameData.charms.get(id, {})
		if not data.is_empty():
			bonus[data["stat"]] = bonus.get(data["stat"], 0.0) + float(data["value"]) * quality_mult(quality_of(id))
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
	cfg.set_value("darkness", "selected", darkness)
	cfg.set_value("darkness", "best", darkness_best)
	cfg.set_value("story", "flags", flags)
	cfg.set_value("shop", "gold", gold)
	cfg.set_value("streak", "current", streak)
	cfg.set_value("charms", "owned", charms)
	cfg.set_value("charms", "quality", charm_quality)
	cfg.set_value("stats", "counters", stats)
	cfg.set_value("stats", "goals_done", goals_done)
	cfg.set_value("charms", "equipped", equipped_charms)
	cfg.set_value("streak", "best", best_streak)
	cfg.set_value("shop", "spent", spent)
	cfg.set_value("shop", "powerups", powerups)
	cfg.set_value("questbook", "steps", questbook)
	cfg.set_value("challenge", "active", _daily_backup if daily else challenges)
	cfg.set_value("artifacts", "owned", artifacts)
	cfg.set_value("chains", "steps", chains)
	cfg.set_value("achievements", "earned", achievements)
	cfg.set_value("artifacts", "equipped", equipped_artifacts)
	cfg.set_value("items", "owned", items)
	cfg.set_value("items", "equipped", equipped_items)
	cfg.set_value("items", "next_uid", next_item_uid)
	# Keep the last good save before writing the new one.
	if FileAccess.file_exists(PATH):
		var previous := ConfigFile.new()
		if previous.load(PATH) == OK:
			DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(BACKUP))
	cfg.save(PATH)
