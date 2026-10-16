class_name SprinklerSpin
extends Node2D
## The spinning water jets of the Sprinkler, centred on the cat.

var enemies: EnemyManager
## The weapon that made this (for its branch effects); may be null.
var source: Weapon
var follow: Node2D
var arms := 1
var length := 70.0
var spin_speed := 2.4
var damage := 6.0
var knockback := 0.8
var tick := 0.25
var lifetime := 3.0

var _angle := randf() * TAU
var _tick_timer := 0.0
var _age := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 2


func _physics_process(delta: float) -> void:
	_age += delta
	lifetime -= delta
	if lifetime <= 0.0 or not is_instance_valid(follow):
		queue_free()
		return
	position = follow.position
	_angle += spin_speed * delta
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick
		for i in arms:
			var dir := Vector2.from_angle(_angle + TAU * i / arms)
			for enemy in enemies.query_segment(position, position + dir * length, 7.0):
				Weapon.strike_from(source, enemy, damage, dir, knockback)
	queue_redraw()


func _draw() -> void:
	var fade := clampf(lifetime * 3.0, 0.0, 1.0) * clampf(_age * 5.0, 0.0, 1.0)
	draw_circle(Vector2.ZERO, 4.0, Color(0.3, 0.55, 0.3, fade))
	for i in arms:
		var dir := Vector2.from_angle(_angle + TAU * i / arms)
		var side := dir.orthogonal()
		# A jet of droplets that spreads out and trails behind the spin.
		for k in 9:
			var t := (k + 1) / 9.0
			var wob := sin(_age * 20.0 + k * 1.7) * 2.0 * t
			var p := dir.rotated(-0.25 * t) * length * t + side * wob
			draw_circle(p, 1.2 + t * 2.0, Color(0.6, 0.85, 1.0, 0.75 * fade * (1.0 - t * 0.4)))
		draw_line(Vector2.ZERO, dir * length * 0.35, Color(0.8, 0.95, 1.0, 0.8 * fade), 2.0)
