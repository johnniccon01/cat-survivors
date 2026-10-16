class_name Projectile
extends Node2D
## A flying projectile that damages enemies it touches. Each enemy is hit at
## most once; `pierce` is how many enemies it can hit before vanishing
## (-1 = unlimited). With `return_to` set it flies back like a boomerang,
## may hit every enemy again on the way back, and vanishes at the cat.

const OUTLINE := Color("2b1d14")

var enemies: EnemyManager
## The weapon that made this (for its branch effects); may be null.
var source: Weapon
var velocity := Vector2.ZERO
var gravity := 0.0
var spin := 0.0
var damage := 10.0
var knockback := 0.5
var pierce := 1
var radius := 4.0
var lifetime := 2.0
var style := "yarn"
var return_to: Node2D
var return_accel := 0.0

var _hit: Dictionary = {}
var _returning := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 3


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	velocity.y += gravity * delta
	if is_instance_valid(return_to):
		var to_owner := return_to.position - position
		velocity += to_owner.normalized() * return_accel * delta
		if not _returning and velocity.dot(to_owner) > 0.0:
			_returning = true
			_hit.clear()
		if _returning and to_owner.length() < 10.0:
			queue_free()
			return
	position += velocity * delta
	rotation += spin * delta
	for enemy in enemies.query_radius(position, radius):
		var key := enemy.get_instance_id()
		if _hit.has(key):
			continue
		_hit[key] = true
		Weapon.strike_from(source, enemy, damage, velocity, knockback)
		if pierce > 0:
			pierce -= 1
			if pierce == 0:
				queue_free()
				return


func _draw() -> void:
	var s := radius / 4.0
	match style:
		"feather", "phoenix":
			var main := Color("ff8a3d") if style == "phoenix" else Color("6fc2ff")
			var tip := Color("ffe066") if style == "phoenix" else Color("f28ac0")
			draw_line(Vector2(-radius * 1.2, 0), Vector2(radius * 1.2, 0), Color("e8e0d0"), 1.0)
			var vane := PackedVector2Array([Vector2(-radius, 0), Vector2(-radius * 0.2, -radius * 0.7), Vector2(radius, 0), Vector2(-radius * 0.2, radius * 0.7)])
			draw_colored_polygon(vane, main)
			draw_polyline(Shapes.closed(vane), OUTLINE, 1.0)
			draw_circle(Vector2(radius * 0.6, 0), radius * 0.3, tip)
			if style == "phoenix":
				draw_circle(Vector2.ZERO, radius * 1.4, Color(1.0, 0.5, 0.1, 0.25))
		"hairball":
			var pts := PackedVector2Array()
			for i in 12:
				var r := radius * (1.0 if i % 2 == 0 else 0.75)
				pts.append(Vector2.from_angle(TAU * i / 12.0) * r)
			draw_colored_polygon(pts, Color("7a5235"))
			draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
			draw_line(Vector2(-2, -1) * s, Vector2(2, 1) * s, Color("a8774f"), 1.0)
		_:
			draw_circle(Vector2.ZERO, radius + 1.0, OUTLINE)
			draw_circle(Vector2.ZERO, radius, Color("e0628f"))
			draw_line(Vector2(-radius, -1), Vector2(radius, 1), Color("f7a8c4"), 1.0)
			draw_line(Vector2(-1, -radius), Vector2(1, radius), Color("f7a8c4"), 1.0)
			# Trailing thread
			draw_line(Vector2.ZERO, -velocity.normalized().rotated(-rotation) * radius * 2.5, Color("e0628f"), 1.0)
