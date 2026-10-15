class_name MilkPuddle
extends Node2D
## A spilled-milk puddle that damages enemies inside it every `tick` seconds.

var enemies: EnemyManager
var radius := 22.0
var damage := 6.0
var tick := 0.35
var lifetime := 2.5

var _age := 0.0
var _tick_timer := 0.0
var _shape := PackedVector2Array()


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -1


func _ready() -> void:
	# Irregular blob outline so every puddle looks a bit different.
	for i in 16:
		var r := radius * randf_range(0.8, 1.1)
		_shape.append(Vector2.from_angle(TAU * i / 16.0) * Vector2(r, r * 0.7))


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick
		for enemy in enemies.query_radius(position, radius * 0.85):
			enemy.hit(damage, Vector2.ZERO, 0.0)
	queue_redraw()


func _draw() -> void:
	var grow := minf(_age * 6.0, 1.0)
	var fade := clampf((lifetime - _age) * 2.0, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(grow, grow))
	draw_colored_polygon(_shape, Color(0.97, 0.96, 0.92, 0.75 * fade))
	draw_polyline(Shapes.closed(_shape), Color(0.85, 0.83, 0.78, 0.9 * fade), 1.0)
	var shine := Shapes.ellipse(Vector2(-radius * 0.3, -radius * 0.2), radius * 0.25, radius * 0.1, 10)
	draw_colored_polygon(shine, Color(1, 1, 1, 0.8 * fade))
