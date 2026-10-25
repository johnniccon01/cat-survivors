class_name EnemyHazard
extends Node2D
## A danger zone left by a boss. "steam" hurts the cat every half second
## while it stands inside, for `lifetime` seconds; "strike" is a warning
## circle for `lifetime` seconds and then hits once (style: "pitchfork" or
## "lightning" or "anchor" picks the look; "portal" is a dark swirl where a
## boss is about to appear, harmless when damage is 0).

const TICK := 0.5
## Steam first shows where it will be for this long, then starts to burn.
const ARM_TIME := 1.0

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
		if inside and _tick <= 0.0 and _t >= ARM_TIME:
			_tick = TICK
			player.take_damage(damage)
		if _t >= lifetime + ARM_TIME:
			queue_free()
			return
	elif _struck < 0.0 and _t >= lifetime:
		_struck = _t
		if inside and damage > 0.0:
			player.take_damage(damage)
		Audio.play("thunder" if style == "lightning" else "hit", -6.0 if style == "lightning" else -10.0)
	elif _struck >= 0.0 and _t - _struck > 0.25:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if mode == "steam":
		if _t < ARM_TIME:
			# Warning: a blinking ring that fills up before the steam burns.
			var k := _t / ARM_TIME
			var blink := 0.6 + 0.4 * sin(_t * 18.0)
			Blit.disc(self, Vector2.ZERO, radius * k, Color(1.0, 0.55, 0.35, 0.18))
			Blit.ring(self, Vector2.ZERO, radius + 0.75, 1.5, Color(1.0, 0.45, 0.25, 0.8 * blink))
			return
		var a := clampf(lifetime + ARM_TIME - _t, 0.0, 1.0) * minf((_t - ARM_TIME) * 4.0, 1.0)
		for k in 3:
			var r := radius * (0.6 + 0.2 * k) + sin(_t * 5.0 + k) * 1.5
			Blit.disc(self, Vector2(0, -k * 2), r, Color(1.0, 0.9, 0.85, 0.16 * a))
		Blit.ring(self, Vector2.ZERO, radius + 1.0 * 0.5, 1.0, Color(1.0, 0.55, 0.35, 0.5 * a))
		return
	if _struck < 0.0 and style == "portal":
		_draw_portal(_t / lifetime)
		return
	if _struck < 0.0:
		var k := _t / lifetime
		Blit.disc(self, Vector2.ZERO, radius, Color(0.9, 0.2, 0.1, 0.10 + 0.15 * k))
		Blit.disc(self, Vector2.ZERO, radius * k, Color(0.9, 0.2, 0.1, 0.18))
		Blit.ring(self, Vector2.ZERO, radius + 1.5 * 0.5, 1.5, Color(1.0, 0.35, 0.2, 0.9))
		return
	var f := 1.0 - (_t - _struck) / 0.25
	if style == "lightning":
		var pts := PackedVector2Array([Vector2(0, -160)])
		for i in 6:
			pts.append(Vector2(randf_range(-8.0, 8.0), -160.0 + (i + 1) * 160.0 / 6.0))
		draw_polyline(pts, Color(1.0, 0.95, 0.5, f), 3.0)
		draw_polyline(pts, Color(1, 1, 1, f), 1.0)
	elif style == "portal":
		Blit.ring(self, Vector2.ZERO, radius * (1.0 + (1.0 - f)), 3.0, Color(0.7, 0.4, 1.0, f))
	elif style == "anchor":
		var iron := Color(0.42, 0.44, 0.47, f)
		Blit.line(self, Vector2(0, -radius), Vector2(0, 4), iron, 3.0)
		draw_arc(Vector2(0, -4), radius * 0.6, 0.3, PI - 0.3, 10, iron, 3.0)
		Blit.line(self, Vector2(-5, -radius + 4), Vector2(5, -radius + 4), iron, 2.0)
	else:
		for x: float in [-5.0, 0.0, 5.0]:
			draw_line(Vector2(x, -radius), Vector2(x, 2), Color(0.75, 0.7, 0.6, f), 2.0)
		draw_line(Vector2(-6, -radius), Vector2(6, -radius), Color(0.6, 0.45, 0.3, f), 2.0)
	Blit.disc(self, Vector2.ZERO, radius, Color(1.0, 0.9, 0.6, 0.35 * f))


## A dark swirl that opens up: purple arms turning round a black middle.
func _draw_portal(k: float) -> void:
	var r := radius * minf(k * 2.5, 1.0)
	Blit.disc(self, Vector2.ZERO, r, Color(0.12, 0.02, 0.2, 0.55))
	for arm in 4:
		var a := _t * 5.0 + arm * TAU / 4.0
		draw_arc(Vector2.ZERO, r * 0.75, a, a + 1.4, 10, Color(0.62, 0.3, 0.95, 0.8), 3.0)
		draw_arc(Vector2.ZERO, r * 0.45, a + 0.8, a + 2.0, 8, Color(0.8, 0.5, 1.0, 0.7), 2.0)
	Blit.disc(self, Vector2.ZERO, r * 0.25, Color(0, 0, 0, 0.9))
	Blit.ring(self, Vector2.ZERO, r, 1.5, Color(0.7, 0.4, 1.0, 0.6 + 0.3 * sin(_t * 12.0)))
