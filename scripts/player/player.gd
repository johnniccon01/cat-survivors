class_name Player
extends Node2D
## The cat. Moves with WASD / arrows / left stick; weapons fire on their own.

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

const FUR := Color("d98c4a")
const FUR_DARK := Color("a8602c")
const BELLY := Color("f3d9b8")
const OUTLINE := Color("2b1d14")
const NOSE := Color("f3a9b8")

@export var starting_weapon := "SCRATCH"

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
## Set by main when started with `-- --bot`; drives the cat automatically for tests.
var bot_mode := false

var _invuln := 0.0
var _hurt_flash := 0.0
var _walk_t := 0.0
var _bot_t := 0.0

@onready var weapons: Node = $Weapons
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_recalc_stats()
	hp = max_hp
	add_weapon(starting_weapon)


func stat(stat_name: String) -> float:
	return stats[stat_name]


func xp_to_next() -> float:
	# Same shape as Vampire Survivors: cheap first levels, then a steady climb.
	if level < 20:
		return 5.0 + (level - 1) * 8.0
	return 157.0 + (level - 20) * 12.0


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
	if bot_mode:
		input = _bot_input(delta)
	else:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * BASE_SPEED * stats["speed"]
	position += velocity * delta
	if absf(input.x) > 0.1:
		facing = 1 if input.x > 0.0 else -1
	if stats["regen"] > 0.0:
		heal(stats["regen"] * delta)
	_invuln = maxf(_invuln - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_walk_t += delta * (12.0 if velocity.length_squared() > 1.0 else 3.0)
	queue_redraw()


func take_damage(amount: float) -> void:
	if is_dead or _invuln > 0.0:
		return
	hp -= maxf(amount - stats["armor"], 1.0)
	_invuln = HIT_INVULN
	_hurt_flash = 0.12
	if hp <= 0.0:
		hp = 0.0
		is_dead = true
		queue_redraw()
		died.emit()


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
	var fur := Color.WHITE if _hurt_flash > 0.0 else FUR
	var step := sin(_walk_t)

	draw_colored_polygon(Shapes.ellipse(Vector2(0, 8), 9, 3), Color(0, 0, 0, 0.25))

	# Everything below is drawn facing right and mirrored; a dead cat lies on its side.
	if is_dead:
		draw_set_transform(Vector2(0, 2), PI * 0.5 * facing, Vector2(facing, 1))
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))

	# Tail
	var sway := sin(_walk_t * 0.5) * 2.0
	var tail := PackedVector2Array([Vector2(-7, 0), Vector2(-11, -3), Vector2(-11 + sway, -8), Vector2(-9 + sway, -11)])
	draw_polyline(tail, OUTLINE, 4.0)
	draw_polyline(tail, fur, 2.0)

	# Legs: diagonal pairs move in opposite phase
	var legs: Array[Vector2] = [Vector2(-6, 1), Vector2(-3, -1), Vector2(3, -1), Vector2(6, 1)]
	for leg in legs:
		var lift := maxf(step * leg.y, 0.0)
		draw_rect(Rect2(leg.x - 1.5, 4 - lift, 3, 4), OUTLINE)
		draw_rect(Rect2(leg.x - 0.5, 4 - lift, 1, 3), fur)

	# Body
	draw_colored_polygon(Shapes.ellipse(Vector2(0, 1), 9, 6), OUTLINE)
	draw_colored_polygon(Shapes.ellipse(Vector2(0, 1), 8, 5), fur)
	draw_colored_polygon(Shapes.ellipse(Vector2(1, 3), 5, 2.5), BELLY)
	for x: float in [-5.0, -2.0, 1.0]:
		draw_line(Vector2(x, -3), Vector2(x + 1, 0), FUR_DARK, 1.0)

	# Head
	var head := Vector2(6, -5)
	var ears: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(2, -8), Vector2(3, -14), Vector2(7, -9)]),
		PackedVector2Array([Vector2(6, -9), Vector2(10, -14), Vector2(11, -7)]),
	]
	for ear in ears:
		draw_colored_polygon(ear, fur)
		draw_polyline(Shapes.closed(ear), OUTLINE, 1.0)
	draw_circle(head, 6.0, OUTLINE)
	draw_circle(head, 5.0, fur)
	draw_line(head + Vector2(-2, -4), head + Vector2(-1, -2), FUR_DARK, 1.0)
	draw_line(head + Vector2(1, -4), head + Vector2(1, -2), FUR_DARK, 1.0)
	if is_dead:
		for e: Vector2 in [head + Vector2(1, -1), head + Vector2(4, -1)]:
			draw_line(e + Vector2(-1, -1), e + Vector2(1, 1), OUTLINE, 1.0)
			draw_line(e + Vector2(-1, 1), e + Vector2(1, -1), OUTLINE, 1.0)
	else:
		draw_rect(Rect2(head + Vector2(0, -2), Vector2(1, 2)), OUTLINE)
		draw_rect(Rect2(head + Vector2(3, -2), Vector2(1, 2)), OUTLINE)
	draw_rect(Rect2(head + Vector2(4, 1), Vector2(2, 1)), NOSE)

	draw_set_transform(Vector2.ZERO)

	# HP bar
	if not is_dead:
		var w := 18.0
		draw_rect(Rect2(-w * 0.5 - 1, 11, w + 2, 4), OUTLINE)
		draw_rect(Rect2(-w * 0.5, 12, w * hp / max_hp, 2), Color("e04646"))
