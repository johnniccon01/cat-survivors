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

var main: Node
var active: Quest

var _timer := 0.0
var _index := 0
var _done_cats: Array[String] = []
var _cfg: Dictionary


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func setup(p_main: Node) -> void:
	main = p_main
	_cfg = GameData.quests
	_timer = float(_cfg["schedule"]["first_delay"])


## Starts a specific quest right away, next to the cat (debug).
func force(quest_id: String) -> void:
	_start(quest_id, 160.0)


func _physics_process(delta: float) -> void:
	if active != null or main == null or main.player.is_dead:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	var order: Array = _cfg["schedule"]["order"]
	var kind: String = order[_index % order.size()]
	_index += 1
	var quest_id := _pick_cat() if kind == "cat" else ""
	if quest_id == "":
		quest_id = (_cfg["side_quests"] as Dictionary).keys().pick_random()
	var dist: Array = _cfg["distance"]
	_start(quest_id, randf_range(dist[0], dist[1]))


func _pick_cat() -> String:
	var locked: Array[String] = []
	var others: Array[String] = []
	for id: String in _cfg["cat_quests"]:
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
	if cat_quests.has(quest_id):
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
	main.hud.show_banner(tr("QUEST_NEW") % quest.title(), 3.0)


func _on_finished(success: bool) -> void:
	active = null
	finished_quest.emit(success)
	_timer = float(_cfg["schedule"]["gap"])
