class_name EnemyHazard
extends Node2D
## A danger zone left by a boss. "steam" hurts the cat every half second
## while it stands inside, for `lifetime` seconds; "strike" is a warning
## circle for `lifetime` seconds and then hits once (style: "pitchfork" or
## "lightning" or "anchor" picks the look).

const TICK := 0.5

var mode := "steam"
var style := ""
var radius := 16.0
var lifetime := 3.0
var damage := 8.0
var player: Player

var _t := 0.0
var _tick := 0.0
var _struck := -1.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -1


func _physics_process(delta: float) -> void:
	_t += delta
	var inside := is_instance_valid(player) and player.position.distance_to(position) < radius
	if mode == "steam":
		_tick -= delta
		if inside and _tick <= 0.0:
			_tick = TICK
			player.take_damage(damage)
		if _t >= lifetime:
			queue_free()
			return
	elif _struck < 0.0 and _t >= lifetime:
		_struck = _t
		if inside:
			player.take_damage(damage)
		Audio.play("thunder" if style == "lightning" else "hit", -6.0 if style == "lightning" else -10.0)
	elif _struck >= 0.0 and _t - _struck > 0.25:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if mode == "steam":
		var a := clampf(lifetime - _t, 0.0, 1.0) * minf(_t * 4.0, 1.0)
		for k in 3:
			var r := radius * (0.6 + 0.2 * k) + sin(_t * 5.0 + k) * 1.5
			draw_circle(Vector2(0, -k * 2), r, Color(1.0, 0.9, 0.85, 0.16 * a))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(1.0, 0.55, 0.35, 0.5 * a), 1.0)
		return
	if _struck < 0.0:
		var k := _t / lifetime
		draw_circle(Vector2.ZERO, radius, Color(0.9, 0.2, 0.1, 0.10 + 0.15 * k))
		draw_circle(Vector2.ZERO, radius * k, Color(0.9, 0.2, 0.1, 0.18))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(1.0, 0.35, 0.2, 0.9), 1.5)
		return
	var f := 1.0 - (_t - _struck) / 0.25
	if style == "lightning":
		var pts := PackedVector2Array([Vector2(0, -160)])
		for i in 6:
			pts.append(Vector2(randf_range(-8.0, 8.0), -160.0 + (i + 1) * 160.0 / 6.0))
		draw_polyline(pts, Color(1.0, 0.95, 0.5, f), 3.0)
		draw_polyline(pts, Color(1, 1, 1, f), 1.0)
	elif style == "anchor":
		var iron := Color(0.42, 0.44, 0.47, f)
		draw_line(Vector2(0, -radius), Vector2(0, 4), iron, 3.0)
		draw_arc(Vector2(0, -4), radius * 0.6, 0.3, PI - 0.3, 10, iron, 3.0)
		draw_line(Vector2(-5, -radius + 4), Vector2(5, -radius + 4), iron, 2.0)
	else:
		for x: float in [-5.0, 0.0, 5.0]:
			draw_line(Vector2(x, -radius), Vector2(x, 2), Color(0.75, 0.7, 0.6, f), 2.0)
		draw_line(Vector2(-6, -radius), Vector2(6, -radius), Color(0.6, 0.45, 0.3, f), 2.0)
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.9, 0.6, 0.35 * f))
