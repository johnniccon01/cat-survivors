class_name Gizmo
extends Node2D
## One thing the newer weapons leave in the world, by `kind`:
## - "box": a cardboard box that sits there, then bursts (Cardboard Box).
## - "drop": a shadow grows, then a sardine lands and splashes (Sardine Rain).
## - "arc": a quick sweep in a half circle (Tail Whip).
## - "beam": a cone of light ahead of the cat, hurting a little and often
##   (Flashlight); `spin` turns it round and round instead.
## - "cap": a bottle cap that ricochets from enemy to enemy (Bottle Caps).
## - "bubble": a soap bubble drifting slowly; it pops on the first enemy,
##   hurting and slowing everyone close (Soap Bubbles).
## - "plane": a paper plane that turns towards the nearest enemy.
## - "cloud": a cloud of litter dust that hurts whoever stands in it.
## - "ring": only a fading ring where something burst.
## Every hit goes through Weapon.strike_from, so branches and combos apply.

const OUTLINE := Color("2b1d14")

var kind := "box"
var source: Weapon
var enemies: EnemyManager
var player: Player
var damage := 10.0
var radius := 20.0
var lifetime := 2.0
var knockback := 0.5
var velocity := Vector2.ZERO
var bounces := 3
## Beam: its direction, half its angle and its reach; `spin` in rad/s.
var dir := Vector2.RIGHT
var half_angle := 0.45
var reach := 120.0
var spin := 0.0
var evolved := false

var _age := 0.0
var _tick := 0.0
var _hit: Dictionary = {}
var _done := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 3


func _physics_process(delta: float) -> void:
	_age += delta
	match kind:
		"ring":
			if _age >= lifetime:
				queue_free()
				return
		"box":
			if _age >= lifetime:
				_burst(radius * 2.2, damage * 2.5)
				queue_free()
				return
			# Enemies that bump into the box get a scratch.
			_every(0.5, func() -> void: _hurt_in(radius, damage * 0.3))
		"drop":
			if _age >= lifetime and not _done:
				_done = true
				_burst(radius, damage)
			if _age >= lifetime + 0.35:
				queue_free()
				return
		"arc":
			if not _done:
				_done = true
				for e in enemies.query_radius(position, reach):
					var to := e.position - position
					if to == Vector2.ZERO or absf(dir.angle_to(to)) <= half_angle:
						Weapon.strike_from(source, e, damage, to, knockback)
			if _age >= 0.22:
				queue_free()
				return
		"beam":
			position = player.position
			if spin != 0.0:
				dir = dir.rotated(spin * delta)
			elif player.velocity.length() > 5.0:
				dir = dir.slerp(player.velocity.normalized(), minf(delta * 8.0, 1.0))
			_every(0.2, func() -> void:
				for e in enemies.query_radius(position, reach):
					var to := e.position - position
					if to != Vector2.ZERO and absf(dir.angle_to(to)) <= half_angle:
						Weapon.strike_from(source, e, damage, to, knockback))
			if _age >= lifetime:
				queue_free()
				return
		"cap":
			position += velocity * delta
			rotation += 14.0 * delta
			for e in enemies.query_radius(position, radius):
				var key := e.get_instance_id()
				if _hit.has(key):
					continue
				_hit[key] = true
				Weapon.strike_from(source, e, damage, velocity, knockback)
				bounces -= 1
				var next := _nearest_unhit(e.position, 220.0)
				if bounces < 0 or next == null:
					queue_free()
					return
				velocity = (next.position - position).normalized() * velocity.length()
				Audio.play("pop", -14.0)
			if _age >= lifetime:
				queue_free()
				return
		"bubble":
			position += velocity * delta
			velocity = velocity.rotated(sin(_age * 3.0) * delta)
			if not enemies.query_radius(position, radius).is_empty() or _age >= lifetime:
				for e in enemies.query_radius(position, radius * 2.4):
					Weapon.strike_from(source, e, damage, e.position - position, knockback)
					e.slow_down(0.5, 1.5 if not evolved else 2.5)
				_pop_fx()
				queue_free()
				return
		"plane":
			var target := enemies.nearest(position, 320.0)
			if target != null:
				var want := (target.position - position).normalized() * velocity.length()
				velocity = velocity.lerp(want, minf(delta * 3.5, 1.0))
			position += velocity * delta
			rotation = velocity.angle()
			for e in enemies.query_radius(position, radius):
				Weapon.strike_from(source, e, damage, velocity, knockback)
				if not evolved:
					queue_free()
					return
				# Origami planes fold back and fly on.
				bounces -= 1
				if bounces < 0:
					queue_free()
					return
				velocity = velocity.rotated(PI * 0.8)
				break
			if _age >= lifetime:
				queue_free()
				return
		"cloud":
			_every(0.4, func() -> void:
				for e in enemies.query_radius(position, radius):
					Weapon.strike_from(source, e, damage, Vector2.ZERO, 0.0)
					if evolved:
						e.slow_down(0.7, 0.6))
			if _age >= lifetime:
				queue_free()
				return
	queue_redraw()


func _every(seconds: float, what: Callable) -> void:
	_tick -= get_physics_process_delta_time()
	if _tick <= 0.0:
		_tick = seconds
		what.call()


func _hurt_in(r: float, amount: float) -> void:
	for e in enemies.query_radius(position, r):
		Weapon.strike_from(source, e, amount, e.position - position, 0.3)


func _burst(r: float, amount: float) -> void:
	for e in enemies.query_radius(position, r):
		Weapon.strike_from(source, e, amount, e.position - position, knockback)
	_ring(r, Color("e8d8a8") if kind == "box" else Color("8fd3ff"))
	Audio.play("pop", -10.0)


func _pop_fx() -> void:
	_ring(radius * 2.4, Color("c8f0ff"))
	Audio.play("pop", -12.0)


## A ring that only shows where something burst.
func _ring(r: float, color: Color) -> void:
	var ring := Gizmo.new()
	ring.kind = "ring"
	ring.radius = r
	ring.lifetime = 0.25
	ring.modulate = color
	ring.position = position
	get_parent().add_child(ring)


func _nearest_unhit(from: Vector2, r: float) -> Enemy:
	var best: Enemy = null
	for e in enemies.query_radius(from, r):
		if _hit.has(e.get_instance_id()):
			continue
		if best == null or e.position.distance_squared_to(from) < best.position.distance_squared_to(from):
			best = e
	return best


func _draw() -> void:
	match kind:
		"ring":
			var f := clampf(_age / lifetime, 0.0, 1.0)
			draw_arc(Vector2.ZERO, radius * (0.4 + 0.6 * f), 0.0, TAU, 28, Color(1, 1, 1, 0.8 * (1.0 - f)), 4.0)
		"box":
			var s := radius * 0.9
			var shake := Vector2(sin(_age * 30.0), 0) * (1.5 if _age > lifetime - 0.6 else 0.0)
			draw_rect(Rect2(Vector2(-s, -s) + shake + Vector2(2, 3), Vector2(s, s) * 2), Color(0, 0, 0, 0.25))
			draw_rect(Rect2(Vector2(-s, -s) + shake, Vector2(s, s) * 2), OUTLINE)
			draw_rect(Rect2(Vector2(-s + 1, -s + 1) + shake, Vector2(s - 1, s - 1) * 2), Color("c8a070"))
			draw_rect(Rect2(Vector2(-s + 1, -2) + shake, Vector2(s * 2 - 2, 4)), Color("e8d8a8"))
			draw_rect(Rect2(Vector2(-s + 1, -s + 1) + shake, Vector2(s * 2 - 2, 2)), Color("e0bc88"))
		"drop":
			var k := clampf(_age / lifetime, 0.0, 1.0)
			if not _done:
				draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, radius * k, radius * 0.6 * k, 16), Color(0, 0, 0, 0.3))
				var fall := (1.0 - k) * 140.0
				var body := Shapes.ellipse(Vector2(0, -fall), 7.0, 3.0, 10)
				draw_colored_polygon(body, Color("aab4be"))
				draw_polyline(Shapes.closed(body), OUTLINE, 1.0)
				draw_colored_polygon(PackedVector2Array([Vector2(6, -fall), Vector2(11, -fall - 4), Vector2(11, -fall + 4)]), Color("8c96a0"))
			else:
				var f := clampf((_age - lifetime) / 0.35, 0.0, 1.0)
				draw_arc(Vector2.ZERO, radius * (0.5 + f), 0.0, TAU, 20, Color(0.75, 0.9, 1.0, 1.0 - f), 3.0)
		"arc":
			var f := clampf(_age / 0.22, 0.0, 1.0)
			var a0 := dir.angle() - half_angle
			draw_arc(Vector2.ZERO, reach * (0.6 + 0.4 * f), a0, a0 + half_angle * 2.0, 18, Color(1.0, 0.85, 0.6, 0.85 * (1.0 - f)), 6.0)
			draw_arc(Vector2.ZERO, reach * (0.45 + 0.4 * f), a0, a0 + half_angle * 2.0, 18, Color(1, 1, 1, 0.5 * (1.0 - f)), 2.0)
		"beam":
			var pts := PackedVector2Array([Vector2.ZERO])
			for i in 9:
				pts.append(Vector2.from_angle(dir.angle() - half_angle + half_angle * 2.0 * i / 8.0) * reach)
			var a := 0.16 + 0.04 * sin(_age * 20.0)
			draw_colored_polygon(pts, Color(1.0, 0.95, 0.65, a))
			draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.95, 0.7, 0.6))
		"cap":
			if not Shots.draw(self, "cap_gold" if evolved else "cap", radius):
				Gizmo.draw_cap(self, radius, evolved)
		"bubble":
			draw_circle(Vector2.ZERO, radius, Color(0.75, 0.9, 1.0, 0.25))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(1, 1, 1, 0.75), 1.0)
			draw_arc(Vector2.ZERO, radius * 0.7, PI * 1.1, PI * 1.5, 6, Color(1, 1, 1, 0.9), 1.5)
			draw_arc(Vector2.ZERO, radius * 0.85, 0.2, 0.9, 6, Color(1.0, 0.7, 0.9, 0.6), 1.0)
		"plane":
			if not Shots.draw(self, "plane_gold" if evolved else "plane", radius):
				Gizmo.draw_plane(self, radius, evolved)
		"cloud":
			var fade := clampf((lifetime - _age) / 0.6, 0.0, 1.0)
			for i in 5:
				var p := Vector2.from_angle(TAU * i / 5.0 + _age * 0.6) * radius * 0.45
				draw_circle(p, radius * 0.55, Color(0.82, 0.76, 0.62, 0.22 * fade) if not evolved else Color(0.9, 0.75, 0.45, 0.28 * fade))
			for i in 8:
				var p := Vector2.from_angle(i * 2.4 + _age * 2.0) * radius * fmod(i * 0.37 + _age, 1.0)
				draw_rect(Rect2(p, Vector2(1, 1)), Color(0.6, 0.55, 0.45, 0.8 * fade))


## A bottle cap drawn from shapes (what tools/bake_art.gd bakes).
static func draw_cap(ci: CanvasItem, radius: float, gold: bool) -> void:
	ci.draw_circle(Vector2.ZERO, radius + 1.0, OUTLINE)
	ci.draw_circle(Vector2.ZERO, radius, Color("f2c14e") if gold else Color("d9534f"))
	ci.draw_circle(Vector2.ZERO, radius * 0.55, Color("f4f1ea"))
	for i in 6:
		var p := Vector2.from_angle(TAU * i / 6.0) * radius
		ci.draw_line(p, p * 1.15, OUTLINE, 1.0)


## A paper plane drawn from shapes (what tools/bake_art.gd bakes).
static func draw_plane(ci: CanvasItem, radius: float, gold: bool) -> void:
	var body := PackedVector2Array([Vector2(radius * 1.4, 0), Vector2(-radius, -radius * 0.9), Vector2(-radius * 0.4, 0), Vector2(-radius, radius * 0.9)])
	ci.draw_colored_polygon(body, Color("f2d14e") if gold else Color("f4f1ea"))
	ci.draw_polyline(Shapes.closed(body), OUTLINE, 1.0)
	ci.draw_line(Vector2(-radius * 0.4, 0), Vector2(radius * 1.4, 0), Color("c8c0b0"), 1.0)
