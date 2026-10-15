class_name Enemy
extends Node2D
## One enemy. Movement and collision are driven centrally by EnemyManager
## (much cheaper than hundreds of physics bodies); this node only stores
## state and draws itself.

const KNOCK_SPEED := 120.0
const KNOCK_DECAY := 600.0
const OUTLINE := Color("2b1d14")

var id := ""
var max_hp := 1.0
var hp := 1.0
var speed := 30.0
var damage := 1.0
var radius := 6.0
var xp := 1.0
var knockback_resist := 0.0
var dead := false
var is_prop := false
var manager: EnemyManager

var _shape := "sock"
var _stripes := false
var _color := Color.WHITE
var _accent := Color.GRAY
var _knock := Vector2.ZERO
var _flash := 0.0
var _wobble := randf() * TAU


func setup(p_id: String, data: Dictionary, p_manager: EnemyManager) -> void:
	id = p_id
	manager = p_manager
	max_hp = data.get("hp", 1.0)
	hp = max_hp
	speed = data.get("speed", 30.0)
	damage = data.get("damage", 1.0)
	radius = data.get("radius", 6.0)
	xp = data.get("xp", 1.0)
	knockback_resist = data.get("knockback_resist", 0.0)
	_shape = data.get("shape", "sock")
	_stripes = data.get("stripes", false)
	_color = Color(data.get("color", "#ffffff"))
	_accent = Color(data.get("accent", "#888888"))


func tick(delta: float, target: Vector2, push: Vector2) -> void:
	var dir := (target - position).normalized()
	position += (dir * speed + _knock + push) * delta
	_knock = _knock.move_toward(Vector2.ZERO, KNOCK_DECAY * delta)
	if absf(dir.x) > 0.2:
		scale.x = signf(dir.x)
	_wobble += delta * speed * 0.15
	rotation = sin(_wobble) * 0.12
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			queue_redraw()


func hit(amount: float, direction: Vector2, knockback: float) -> void:
	if dead:
		return
	hp -= amount
	_flash = 0.08
	queue_redraw()
	_knock = direction.normalized() * KNOCK_SPEED * knockback * (1.0 - knockback_resist)
	if hp <= 0.0:
		dead = true
		manager.on_enemy_dead(self)


func _draw() -> void:
	var body := Color.WHITE if _flash > 0.0 else _color
	draw_colored_polygon(Shapes.ellipse(Vector2(1, radius + 2), radius, 2), Color(0, 0, 0, 0.25))
	match _shape:
		"dust":
			_draw_dust(body)
		"box":
			_draw_box(body)
		"plant":
			_draw_plant(body)
		_:
			_draw_sock(body)


func _draw_sock(body: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(-5, -10), Vector2(3, -10), Vector2(3, 2), Vector2(9, 3),
		Vector2(10, 6), Vector2(8, 9), Vector2(-3, 9), Vector2(-5, 6),
	])
	draw_colored_polygon(pts, body)
	draw_rect(Rect2(-5, -10, 8, 3), _accent)
	if _stripes:
		draw_rect(Rect2(-5, -4, 8, 2), _accent)
		draw_rect(Rect2(-5, 1, 8, 2), _accent)
	draw_colored_polygon(Shapes.ellipse(Vector2(7, 6), 2, 2, 8), _accent)
	draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	# Grumpy face
	draw_rect(Rect2(-3, -6, 1, 2), OUTLINE)
	draw_rect(Rect2(0, -6, 1, 2), OUTLINE)
	draw_line(Vector2(-4, -8), Vector2(-2, -7), OUTLINE, 1.0)
	draw_line(Vector2(2, -8), Vector2(0, -7), OUTLINE, 1.0)


func _draw_dust(body: Color) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		var r := radius + (1.5 if i % 2 == 0 else -0.5)
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	draw_colored_polygon(pts, body)
	draw_polyline(Shapes.closed(pts), _accent, 1.0)
	for e: Vector2 in [Vector2(-2, -1), Vector2(2, -1)]:
		draw_circle(e, 1.8, Color.WHITE)
		draw_rect(Rect2(e + Vector2(0, -0.5), Vector2(1, 1)), OUTLINE)


func _draw_box(body: Color) -> void:
	var r := Rect2(-8, -9, 16, 15)
	draw_rect(r, body)
	draw_rect(Rect2(-8, -9, 16, 4), body.darkened(0.15))
	draw_rect(Rect2(-1.5, -9, 3, 15), _accent)
	draw_rect(r, OUTLINE, false, 1.0)
	draw_line(Vector2(-8, -5), Vector2(8, -5), OUTLINE, 1.0)


func _draw_plant(body: Color) -> void:
	for leaf: Vector2 in [Vector2(-6, -12), Vector2(0, -15), Vector2(6, -12), Vector2(-3, -9), Vector2(3, -9)]:
		var pts := PackedVector2Array([Vector2(0, -4), leaf + Vector2(-2, 1), leaf, leaf + Vector2(2, 1)])
		draw_colored_polygon(pts, _accent)
		draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	var pot := PackedVector2Array([Vector2(-6, -5), Vector2(6, -5), Vector2(4, 6), Vector2(-4, 6)])
	draw_colored_polygon(pot, body)
	draw_rect(Rect2(-7, -6, 14, 3), body.lightened(0.15))
	draw_polyline(Shapes.closed(pot), OUTLINE, 1.0)
