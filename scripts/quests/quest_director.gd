class_name QuestDirector
extends Node
## Hands out quests one at a time during the night, following the order in
## data/quests.json ("side" / "cat"). Cat quests prefer cats that are still
## locked, so new players meet new cats first.

signal finished_quest(success: bool)

const SIDE_SCRIPTS := {
	"DEFEND_BOWL": preload("res://scripts/quests/bowl_quest.gd"),
	"RED_DOT": preload("res://scripts/quests/red_dot_quest.gd"),
	"FRIDGE": preload("res://scripts/quests/fridge_quest.gd"),
}

## Cat quests (rescues, duels) never come before this point of the night.
const CAT_QUEST_FROM := 180.0

var main: Node
var active: Quest

var _timer := 0.0
var _index := 0
var _done_cats: Array[String] = []
var _cat_given := false
## Chains whose step failed tonight (they wait for the next night).
var _chains_failed: Array[String] = []
var _cfg: Dictionary

## Secret chains ("secret" in chains.json) are never on the schedule. "far":
## found once the cat wanders that far from where the night began (any
## direction; "dark_from" makes the map darker on the way). "trail": found
## at the end of a long blood trail (BloodTrail).
var _secrets: Array[String] = []
var _secret_found: Array[String] = []
## Chain id -> its BloodTrail.
var _trails: Dictionary = {}
## Where the night began; "far" secrets measure from here.
var _origin := Vector2.ZERO


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func setup(p_main: Node) -> void:
	main = p_main
	_cfg = GameData.quests
	_timer = float(_cfg["schedule"]["first_delay"])
	ChainStep.warm()
	_origin = main.player.position
	for id: String in GameData.chains:
		var chain: Dictionary = GameData.chains[id]
		if not chain.has("secret") or chain.get("stage", "any") != main.spawner.stage_id:
			continue
		if not chain.get("requires", []).all(func(f: String) -> bool: return Profile.has_flag(f)):
			continue
		# A far secret darkens its map even once it's done.
		_secrets.append(id)
		if chain["secret"]["type"] == "trail" and not ChainStep.is_done(id):
			var trail := BloodTrail.new()
			trail.setup(_origin, chain["secret"])
			main.add_child(trail)
			_trails[id] = trail


## End of a secret trail on this map (Vector2.INF if none; tests).
func trail_end() -> Vector2:
	for trail: BloodTrail in _trails.values():
		return trail.end
	return Vector2.INF


## Starts a specific quest right away, next to the cat (debug).
func force(quest_id: String) -> void:
	_cat_given = _cat_given or (_cfg["cat_quests"] as Dictionary).has(quest_id)
	_start(quest_id, 160.0)


func _physics_process(delta: float) -> void:
	if main == null or main.player.is_dead:
		return
	if not _secrets.is_empty():
		_update_secrets()
	if active != null or main.final_boss != null:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	var order: Array = _cfg["schedule"]["order"]
	var kind: String = order[_index % order.size()]
	# Too early for the cat quest: run a side quest now and keep it for later.
	if kind == "cat" and not _cat_given and main.spawner.elapsed < CAT_QUEST_FROM:
		kind = "side"
	else:
		_index += 1
	# Only one cat quest per night.
	var quest_id := ""
	if kind == "cat" and not _cat_given and main.spawner.elapsed >= CAT_QUEST_FROM:
		quest_id = _pick_cat()
		_cat_given = quest_id != ""
	elif kind == "story":
		quest_id = _pick_story()
	elif kind == "chain":
		quest_id = _pick_chain()
	if quest_id == "":
		quest_id = (_cfg["side_quests"] as Dictionary).keys().pick_random()
	var dist: Array = _cfg["distance"]
	_start(quest_id, randf_range(dist[0], dist[1]))


## Finds secrets and starts a found one as soon as no other quest runs.
func _update_secrets() -> void:
	var far: float = main.player.position.distance_to(_origin)
	var dark := 0.0
	for id: String in _secrets:
		var secret: Dictionary = GameData.chains[id]["secret"]
		if secret.has("dark_from"):
			var from := float(secret["dark_from"])
			dark = maxf(dark, clampf((far - from) / (float(secret["distance"]) - from), 0.0, 1.0))
		# (Not while one of its steps runs: the next step is found afterwards.)
		if id in _secret_found or id in _chains_failed or ChainStep.is_done(id) \
				or (active is ChainStep and (active as ChainStep).chain_id == id):
			continue
		var found := false
		match secret["type"]:
			"far":
				found = far >= float(secret["distance"])
			"trail":
				found = _trails.has(id) and (_trails[id] as BloodTrail).reached(main.player.position)
		if found:
			_secret_found.append(id)
	main.night.far_dark = dark
	if active != null or main.final_boss != null or _secret_found.is_empty():
		return
	var id: String = _secret_found.pop_front()
	var at := (_trails[id] as BloodTrail).end if _trails.has(id) else Vector2.INF
	_start(id, 180.0, at)


## The stage's story quest, unless its flag is already set.
func _pick_story() -> String:
	var story_id: String = main.spawner.stage().get("story", "")
	if story_id == "":
		return ""
	if Profile.has_flag(_cfg["story"][story_id]["flag"]):
		return ""
	return story_id


## The first quest chain with a step to play on this map tonight (see
## _chain_rank for the order).
func _pick_chain() -> String:
	var ids: Array = GameData.chains.keys()
	ids.sort_custom(func(x: String, y: String) -> bool: return _chain_rank(x) < _chain_rank(y))
	for id: String in ids:
		if ChainStep.is_done(id) or id in _chains_failed or GameData.chains[id].has("secret"):
			continue
		var needs: Array = GameData.chains[id].get("requires", [])
		if not needs.all(func(f: String) -> bool: return Profile.has_flag(f)):
			continue
		var n := ChainStep.progress_of(id) + 1
		var step: Dictionary = ChainStep.steps(id)[n - 1]
		# "final" steps finish when the final boss falls; some steps need a cat.
		if step["type"] == "final" or (step.has("needs_cat") and not Profile.is_unlocked(step["needs_cat"])):
			continue
		# Big fights wait until later in the night, when the cat has grown.
		if main.spawner.elapsed < float(ChainStep.steps(id)[n - 1].get("after_minute", 0.0)) * 60.0:
			continue
		var stage := ChainStep.stage_of(id, n)
		if stage == "any" or stage == main.spawner.stage_id:
			return id
	return ""


## Stories under way first, then this map's own stories, then the ones
## that can happen anywhere.
func _chain_rank(id: String) -> int:
	if ChainStep.progress_of(id) > 0:
		return 0
	return 2 if GameData.chains[id].get("stage", "any") == "any" else 1


func _pick_cat() -> String:
	var locked: Array[String] = []
	var others: Array[String] = []
	for id: String in main.spawner.stage().get("cat_quests", []):
		if id == main.player.cat_id or id in _done_cats or main.has_companion(id):
			continue
		if Profile.is_unlocked(id):
			others.append(id)
		else:
			locked.append(id)
	if not locked.is_empty():
		return locked.pick_random()
	if not others.is_empty():
		return others.pick_random()
	return ""


## `at`: where the quest waits (Vector2.INF: `distance` away from the cat).
func _start(quest_id: String, distance: float, at: Vector2 = Vector2.INF) -> void:
	var quest: Quest
	var cat_quests: Dictionary = _cfg["cat_quests"]
	if GameData.chains.has(quest_id):
		quest = ChainStep.create(quest_id)
		distance = float(quest.data.get("distance", distance))
	elif (_cfg["story"] as Dictionary).has(quest_id):
		quest = StoryCollarQuest.new()
		quest.data = _cfg["story"][quest_id]
	elif cat_quests.has(quest_id):
		var data: Dictionary = cat_quests[quest_id]
		quest = RescueQuest.new() if data["type"] == "rescue" else DuelQuest.new()
		quest.set("cat_id", quest_id)
		quest.data = data
		_done_cats.append(quest_id)
	else:
		quest = SIDE_SCRIPTS[quest_id].new()
		quest.data = _cfg["side_quests"][quest_id]
		quest.expire_after = float(_cfg["schedule"]["side_expire"])
	quest.quest_id = quest_id
	quest.main = main
	quest.position = at if at != Vector2.INF else main.player.position + Vector2.from_angle(randf() * TAU) * distance
	quest.position = Terrain.fix(quest.position, 40.0)
	quest.finished.connect(_on_finished)
	main.add_child(quest)
	active = quest
	if main.player.controller == "bot":
		print("BOT: quest %s started at %.0f s" % [quest_id, main.spawner.elapsed])
	var line: String = (quest as ChainStep).start_line() if quest is ChainStep else ""
	main.hud.show_banner(tr("QUEST_NEW") % quest.title() + ("\n" + line if line != "" else ""), 5.0 if line != "" else 3.0)
	Audio.play("quest", -4.0, 0.0)


func _on_finished(success: bool) -> void:
	if main.player.controller == "bot" and active != null:
		print("BOT: quest %s %s at %.0f s (%s)" % [active.quest_id, "done" if success else "failed", main.spawner.elapsed, active.objective()])
	if active is ChainStep:
		var id := (active as ChainStep).chain_id
		# Failed steps wait for the next night, and so do "one_per_night" chains.
		if not success or GameData.chains[id].get("one_per_night", false):
			_chains_failed.append(id)
	active = null
	finished_quest.emit(success)
	_timer = float(_cfg["schedule"]["gap"])
