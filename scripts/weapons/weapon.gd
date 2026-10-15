class_name Weapon
extends Node
## Base for all weapons. Stats come from data/weapons.json: level 1 holds the
## base values and every further level only lists increments, which are summed
## up to the current level (same scheme as Vampire Survivors).
##
## Every `interval` seconds the weapon fires a burst of `amount` shots spaced
## `repeat_interval` apart; subclasses implement shoot().

var id := ""
var data: Dictionary
var player: Player
var enemies: EnemyManager
var world: Node2D
var level := 1
var stats: Dictionary = {}

var _cooldown := 0.3
var _burst_index := 0
var _burst_count := 0
var _burst_timer := 0.0


func setup(p_id: String, p_data: Dictionary, p_player: Player) -> void:
	id = p_id
	data = p_data
	player = p_player
	_recalc()


func _ready() -> void:
	enemies = get_tree().get_first_node_in_group("enemy_manager")
	world = player.get_parent()


func max_level() -> int:
	return data["levels"].size()


func level_up() -> void:
	if level < max_level():
		level += 1
		_recalc()


func stat(stat_name: String, default: float = 0.0) -> float:
	return float(stats.get(stat_name, default))


# Final values: the weapon's own stats combined with the cat's passives.

func damage() -> float:
	return stat("damage") * player.stat("might")


func area() -> float:
	return stat("area", 1.0) * player.stat("area")


func interval() -> float:
	return maxf(stat("interval", 1.0) * player.stat("cooldown"), 0.1)


func amount() -> int:
	return int(stat("amount", 1.0) + player.stat("amount"))


func duration() -> float:
	return stat("duration", 1.0) * player.stat("duration")


func proj_speed() -> float:
	return stat("speed", 1.0) * player.stat("proj_speed")


## Shots per burst; weapons that spawn everything at once override this.
func shots() -> int:
	return amount()


func _recalc() -> void:
	stats = {}
	for i in level:
		var lv: Dictionary = data["levels"][i]
		for key: String in lv:
			stats[key] = stats.get(key, 0.0) + lv[key]


func _physics_process(delta: float) -> void:
	if player.is_dead:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown += interval()
		_burst_index = 0
		_burst_count = shots()
		_burst_timer = 0.0
	if _burst_index < _burst_count:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			shoot(_burst_index)
			_burst_index += 1
			_burst_timer = stat("repeat_interval", 0.1)


## Fires shot number `index` of the current burst (0-based).
func shoot(_index: int) -> void:
	pass
