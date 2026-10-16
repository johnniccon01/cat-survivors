class_name WebPatch
extends Node2D
## A cobweb on the floor: slows every enemy inside it (speed x `slow`) and
## hurts them every `tick` seconds. Silk webs shimmer and hold harder.

var enemies: EnemyManager
var radius := 26.0
var damage := 4.0
var tick := 0.5
var lifetime := 3.0
var slow := 0.45
var silk := false

var _age := 0.0
var _tick_timer := 0.0
var _spin := randf() * TAU


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -1


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	_tick_timer -= delta
	var hurt := _tick_timer <= 0.0
	if hurt:
		_tick_timer = tick
	for enemy in enemies.query_radius(position, radius * 0.9):
		# Held for a moment longer than this frame so they stay stuck in it.
		enemy.slow_down(slow if not enemy.is_boss else maxf(slow, 0.6), 0.15)
		if hurt:
			enemy.hit(damage, Vector2.ZERO, 0.0)
	queue_redraw()


func _draw() -> void:
	var grow := minf(_age * 5.0, 1.0)
	var fade := clampf((lifetime - _age) * 2.0, 0.0, 1.0)
	var r := radius * grow
	var thread := Color(0.95, 0.95, 1.0, 0.55 * fade)
	if silk:
		thread = Color(1.0, 0.92, 0.7, 0.75 * fade)
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.9, 0.6, 0.08 * fade))
	# Spokes, then rings made of straight pieces between them, like a real web.
	var spokes := 8
	for i in spokes:
		draw_line(Vector2.ZERO, Vector2.from_angle(_spin + TAU * i / spokes) * r, thread, 1.0)
	for ring in 4:
		var rr := r * (0.3 + ring * 0.23)
		for i in spokes:
			var a := Vector2.from_angle(_spin + TAU * i / spokes) * rr
			var b := Vector2.from_angle(_spin + TAU * (i + 1) / spokes) * rr * 0.96
			draw_line(a, b, thread, 1.0)
