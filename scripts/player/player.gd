class_name Player
extends Node2D
## The cat. Moves with WASD / arrows / left stick; weapons fire on their own.

signal died

const RADIUS := 7.0
const HIT_INVULN := 0.4

const FUR := Color("d98c4a")
const FUR_DARK := Color("a8602c")
const BELLY := Color("f3d9b8")
const OUTLINE := Color("2b1d14")
const NOSE := Color("f3a9b8")

@export var max_hp := 100.0
@export var move_speed := 100.0

var hp := 100.0
var facing := 1
var velocity := Vector2.ZERO
var is_dead := false
## Set by main when started with `-- --bot`; drives the cat automatically for tests.
var bot_mode := false

var _invuln := 0.0
var _hurt_flash := 0.0
var _walk_t := 0.0
var _bot_t := 0.0

@onready var weapons: Node = $Weapons
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	hp = max_hp
	add_weapon("SCRATCH")


func add_weapon(id: String) -> Weapon:
	var data: Dictionary = GameData.weapons[id]
	var weapon: Weapon = load(data["script"]).new()
	weapon.setup(id, data, self)
	weapons.add_child(weapon)
	return weapon


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var input: Vector2
	if bot_mode:
		input = _bot_input(delta)
	else:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * move_speed
	position += velocity * delta
	if absf(input.x) > 0.1:
		facing = 1 if input.x > 0.0 else -1
	_invuln = maxf(_invuln - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_walk_t += delta * (12.0 if velocity.length_squared() > 1.0 else 3.0)
	queue_redraw()


func take_damage(amount: float) -> void:
	if is_dead or _invuln > 0.0:
		return
	hp -= amount
	_invuln = HIT_INVULN
	_hurt_flash = 0.12
	if hp <= 0.0:
		hp = 0.0
		is_dead = true
		queue_redraw()
		died.emit()


func _bot_input(delta: float) -> Vector2:
	_bot_t += delta
	return Vector2(cos(_bot_t * 0.4), sin(_bot_t * 0.8)).normalized()


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
