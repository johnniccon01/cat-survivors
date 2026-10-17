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


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func setup(p_main: Node) -> void:
	main = p_main
	_cfg = GameData.quests
	_timer = float(_cfg["schedule"]["first_delay"])


## Starts a specific quest right away, next to the cat (debug).
func force(quest_id: String) -> void:
	_cat_given = _cat_given or (_cfg["cat_quests"] as Dictionary).has(quest_id)
	_start(quest_id, 160.0)


func _physics_process(delta: float) -> void:
	if active != null or main == null or main.player.is_dead or main.final_boss != null:
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


## The stage's story quest, unless its flag is already set.
func _pick_story() -> String:
	var story_id: String = main.spawner.stage().get("story", "")
	if story_id == "":
		return ""
	if Profile.has_flag(_cfg["story"][story_id]["flag"]):
		return ""
	return story_id


## The first quest chain with a step to play on this map tonight; stories
## already under way come before new ones.
func _pick_chain() -> String:
	var ids: Array = GameData.chains.keys()
	ids.sort_custom(func(x: String, y: String) -> bool: return ChainStep.progress_of(x) > 0 and ChainStep.progress_of(y) == 0)
	for id: String in ids:
		if ChainStep.is_done(id) or id in _chains_failed:
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


func _start(quest_id: String, distance: float) -> void:
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
	quest.position = main.player.position + Vector2.from_angle(randf() * TAU) * distance
	quest.finished.connect(_on_finished)
	main.add_child(quest)
	active = quest
	var line: String = (quest as ChainStep).start_line() if quest is ChainStep else ""
	main.hud.show_banner(tr("QUEST_NEW") % quest.title() + ("\n" + line if line != "" else ""), 5.0 if line != "" else 3.0)
	Audio.play("quest", -4.0, 0.0)


func _on_finished(success: bool) -> void:
	if active is ChainStep:
		var id := (active as ChainStep).chain_id
		# Failed steps wait for the next night, and so do "one_per_night" chains.
		if not success or GameData.chains[id].get("one_per_night", false):
			_chains_failed.append(id)
	active = null
	finished_quest.emit(success)
	_timer = float(_cfg["schedule"]["gap"])
