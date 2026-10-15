class_name Player
extends Node2D
## A cat: the one you play, or a companion that follows it. Look, starting
## weapon and stat bonus come from data/cats.json. Weapons fire on their own.
##
## Controllers: "input" (WASD / arrows / left stick), "bot" (automated tests)
## "follow" (companion: trails the leader, can't be hurt, borrows the
## leader's stats and levels its weapon as the leader levels up) and
## "escort" (a rescued cat being walked home: slower, unarmed, can be hurt
## and knocked down).

signal died
signal leveled_up
signal xp_changed
signal inventory_changed

const RADIUS := 7.0
const HIT_INVULN := 0.4
const MAX_WEAPONS := 6
const MAX_PASSIVES := 6
const BASE_SPEED := 100.0

## Base values of all character stats; passives add to these.
const BASE_STATS := {
	"might": 1.0, "area": 1.0, "cooldown": 1.0, "amount": 0.0, "speed": 1.0,
	"max_hp": 100.0, "regen": 0.0, "magnet": 40.0, "duration": 1.0,
	"proj_speed": 1.0, "armor": 0.0,
}

const OUTLINE := Color("2b1d14")
## Companion weapon gains a level every this many leader levels.
const COMPANION_LEVEL_STEP := 4

@export var cat_id := "MICA"
@export var controller := "input"

## The cat a companion follows.
var leader: Player
## Max health of an escorted cat.
var escort_hp := 60.0
## Dev cheat: ignore all damage.
var god := false
## External pull (e.g. the final boss sucking the cat in); reset every frame.
var pull := Vector2.ZERO

var hp := 100.0
var max_hp := 100.0
var level := 1
var xp := 0.0
var facing := 1
var velocity := Vector2.ZERO
var is_dead := false
## passive id -> level
var passives: Dictionary = {}
var stats: Dictionary = BASE_STATS.duplicate()
var _look: Dictionary
var _follow_offset := Vector2.ZERO
var _invuln := 0.0
var _hurt_flash := 0.0
var _walk_t := 0.0
var _bot_t := 0.0

@onready var weapons: Node = $Weapons
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	if controller != "follow":
		cat_id = Profile.selected_cat
	_look = CatArt.look(cat_id)
	if controller == "follow" or controller == "escort":
		camera.queue_free()
		camera = null
		_follow_offset = Vector2.from_angle(randf() * TAU) * randf_range(18.0, 30.0)
	_recalc_stats()
	if controller == "escort":
		max_hp = escort_hp
		stats["speed"] = 0.8
	hp = max_hp
	if controller != "escort":
		add_weapon(GameData.cats[cat_id]["weapon"])


func is_companion() -> bool:
	return controller == "follow"


func stat(stat_name: String) -> float:
	if is_companion() and is_instance_valid(leader):
		return leader.stat(stat_name)
	return stats[stat_name]


func xp_to_next() -> float:
	# Same shape as Vampire Survivors: cheap first levels, then a steady climb.
	if level < 20:
		return 5.0 + (level - 1) * 8.0
	if level < 40:
		return 157.0 + (level - 20) * 18.0
	return 517.0 + (level - 40) * 30.0


func add_xp(amount: float) -> void:
	if is_dead:
		return
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		leveled_up.emit()
	xp_changed.emit()


func heal(amount: float) -> void:
	hp = minf(hp + amount, max_hp)


func get_weapon(id: String) -> Weapon:
	for weapon: Weapon in weapons.get_children():
		if weapon.id == id:
			return weapon
	return null


func weapon_count() -> int:
	return weapons.get_child_count()


func add_weapon(id: String) -> Weapon:
	var data: Dictionary = GameData.weapons[id]
	var weapon: Weapon = load(data["script"]).new()
	weapon.setup(id, data, self)
	weapons.add_child(weapon)
	inventory_changed.emit()
	return weapon


func level_up_weapon(id: String) -> void:
	get_weapon(id).level_up()
	inventory_changed.emit()


## Replaces a maxed weapon with its evolved form, keeping its slot.
func evolve_weapon(from_id: String, into_id: String) -> void:
	var old := get_weapon(from_id)
	var index := old.get_index()
	weapons.remove_child(old)
	old.queue_free()
	var evolved := add_weapon(into_id)
	weapons.move_child(evolved, index)
	inventory_changed.emit()


func add_passive(id: String) -> void:
	passives[id] = passives.get(id, 0) + 1
	_recalc_stats()
	inventory_changed.emit()


func _recalc_stats() -> void:
	stats = BASE_STATS.duplicate()
	var bonus: Dictionary = GameData.cats[cat_id].get("bonus", {})
	for key: String in bonus:
		stats[key] += bonus[key]
	for id: String in passives:
		var levels: Array = GameData.passives[id]["levels"]
		for i in passives[id]:
			var lv: Dictionary = levels[i]
			for key: String in lv:
				stats[key] += lv[key]
	var old_max := max_hp
	max_hp = stats["max_hp"]
	hp += maxf(max_hp - old_max, 0.0)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var input: Vector2
	match controller:
		"bot":
			input = _bot_input(delta)
		"follow", "escort":
			input = _follow_input()
		_:
			input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * BASE_SPEED * stat("speed")
	position += (velocity + pull) * delta
	pull = Vector2.ZERO
	var manager: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")
	if manager != null and not manager.arena.is_empty():
		var center: Vector2 = manager.arena["center"]
		var r: float = manager.arena["radius"] - RADIUS
		if position.distance_to(center) > r:
			position = center + (position - center).normalized() * r
	if absf(input.x) > 0.1:
		facing = 1 if input.x > 0.0 else -1
	if stats["regen"] > 0.0:
		heal(stats["regen"] * delta)
	_invuln = maxf(_invuln - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_walk_t += delta * (12.0 if velocity.length_squared() > 1.0 else 3.0)
	queue_redraw()


func take_damage(amount: float) -> void:
	if is_dead or _invuln > 0.0 or is_companion() or god:
		return
	hp -= maxf(amount - stats["armor"], 1.0)
	if controller != "escort":
		Audio.play("hurt", -6.0)
	_invuln = HIT_INVULN
	_hurt_flash = 0.12
	if hp <= 0.0:
		hp = 0.0
		is_dead = true
		queue_redraw()
		died.emit()


## Companion: walk to a spot near the leader; catch up faster when far away.
func _follow_input() -> Vector2:
	if not is_instance_valid(leader):
		return Vector2.ZERO
	if leader.is_dead:
		return Vector2.ZERO
	_sync_companion_weapon()
	var goal := leader.position + _follow_offset
	var to := goal - position
	if to.length() < 6.0:
		return Vector2.ZERO
	if to.length() > 400.0:
		position = goal
		return Vector2.ZERO
	return to.normalized() * clampf(to.length() / 40.0, 0.4, 1.6)


## Brings a knocked-down escorted cat back on its feet.
func revive(fraction: float) -> void:
	is_dead = false
	hp = max_hp * fraction
	_invuln = 1.0
	queue_redraw()


func _sync_companion_weapon() -> void:
	if weapons.get_child_count() == 0:
		return
	var weapon := weapons.get_child(0) as Weapon
	if weapon == null:
		return
	var target := mini(1 + floori(leader.level / float(COMPANION_LEVEL_STEP)), weapon.max_level())
	while weapon.level < target:
		weapon.level_up()


## Test bot: dodges enemies that get close, otherwise drifts towards the
## nearest one so its weapons have something to hit.
func _bot_input(delta: float) -> Vector2:
	_bot_t += delta
	var wander := Vector2(cos(_bot_t * 0.3), sin(_bot_t * 0.5))
	var manager: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")
	var away := Vector2.ZERO
	for enemy in manager.query_radius(position, 36.0):
		var d := position - enemy.position
		away += d / maxf(d.length_squared(), 1.0)
	if away != Vector2.ZERO:
		return (away.normalized() + wander * 0.3).normalized()
	var quest: Quest = get_parent().quests.active if get_parent().get("quests") else null
	if quest != null:
		var to_quest := quest.target_position() - position
		if to_quest.length() > 20.0:
			return (to_quest.normalized() + wander * 0.15).normalized()
		return Vector2.ZERO
	var pickups: Pickups = get_parent().get_node("Pickups")
	var best_d2 := 160.0 * 160.0
	var goal := Vector2.INF
	for item in pickups.items:
		var d2 := item.position.distance_squared_to(position)
		if d2 < best_d2:
			best_d2 = d2
			goal = item.position
	if goal != Vector2.INF:
		return (goal - position).normalized()
	var target := manager.nearest(position)
	if target != null and target.position.distance_to(position) > 50.0:
		return ((target.position - position).normalized() * 0.7 + wander * 0.3).normalized()
	return wander.normalized()


func _draw() -> void:
	CatArt.draw(self, _look, facing, _walk_t, _hurt_flash > 0.0, is_dead)
	if is_dead or is_companion():
		return
	if controller == "escort":
		draw_rect(Rect2(-10, -24, 20, 4), OUTLINE)
		draw_rect(Rect2(-9, -23, 18 * hp / max_hp, 2), Color("6cc46c"))
		return
	# HP bar
	var w := 18.0
	var y := 11.0 * float(_look["size"])
	draw_rect(Rect2(-w * 0.5 - 1, y, w + 2, 4), OUTLINE)
	draw_rect(Rect2(-w * 0.5, y + 1, w * hp / max_hp, 2), Color("e04646"))
