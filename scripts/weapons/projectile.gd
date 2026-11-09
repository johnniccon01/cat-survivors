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
var _launch_dir := Vector2.ZERO
## Recent positions, for the motion trail.
var _trail: PackedVector2Array = []
const TRAIL := 6
const TRAIL_COLORS := {"feather": Color("6fc2ff"), "phoenix": Color("ff8a3d"), "hairball": Color("a8774f"),
	"hook": Color("c9ced2"), "golden_hook": Color("f2c14e"), "needle": Color("dfe4e8")}


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
		if _launch_dir == Vector2.ZERO:
			_launch_dir = velocity.normalized()
		velocity += to_owner.normalized() * return_accel * delta
		# It turns back once the pull has reversed its flight (judging by the
		# cat's position instead made throws towards the cat vanish at once).
		if not _returning and velocity.dot(_launch_dir) < 0.0:
			_returning = true
			_hit.clear()
		if _returning and to_owner.length() < 10.0:
			queue_free()
			return
	_trail.append(position)
	if _trail.size() > TRAIL:
		_trail.remove_at(0)
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
	# A fading trail behind the projectile (drawn in world space).
	var tc: Color = TRAIL_COLORS.get(style, Color("e0628f"))
	for i in range(1, _trail.size()):
		var k := float(i) / _trail.size()
		Blit.line(self, to_local(_trail[i - 1]), to_local(_trail[i]), Color(tc, 0.35 * k), radius * 1.4 * k)
	# The line behind a hook or a ball of yarn follows the flight, so it stays
	# drawn here; the projectile itself is a baked pixel-art picture.
	if style in ["hook", "golden_hook"]:
		Blit.line(self, Vector2.ZERO, -velocity.normalized().rotated(-rotation) * radius * 5.0, Color(0.9, 0.9, 0.9, 0.6), 1.0)
	elif not style in ["feather", "phoenix", "needle", "hairball"]:
		Blit.line(self, Vector2.ZERO, -velocity.normalized().rotated(-rotation) * radius * 2.5, Color("e0628f"), 1.0)
	if style == "phoenix":
		Blit.disc(self, Vector2.ZERO, radius * 1.4, Color(1.0, 0.5, 0.1, 0.25))
	if not Shots.draw(self, style, radius):
		Projectile.draw_body(self, style, radius)


## The projectile itself, drawn from shapes (what tools/bake_art.gd bakes).
static func draw_body(ci: CanvasItem, style: String, radius: float) -> void:
	var s := radius / 4.0
	match style:
		"feather", "phoenix":
			var main := Color("ff8a3d") if style == "phoenix" else Color("6fc2ff")
			var tip := Color("ffe066") if style == "phoenix" else Color("f28ac0")
			Blit.line(ci, Vector2(-radius * 1.2, 0), Vector2(radius * 1.2, 0), Color("e8e0d0"), 1.0)
			var vane := PackedVector2Array([Vector2(-radius, 0), Vector2(-radius * 0.2, -radius * 0.7), Vector2(radius, 0), Vector2(-radius * 0.2, radius * 0.7)])
			ci.draw_colored_polygon(vane, main)
			# A soft edge in the feather's own darker colour, not black.
			ci.draw_polyline(Shapes.closed(vane), main.darkened(0.35), 1.0)
			Blit.disc(ci, Vector2(radius * 0.6, 0), radius * 0.3, tip)
		"hook", "golden_hook":
			var metal := Color("f2c14e") if style == "golden_hook" else Color("c9ced2")
			var hook := PackedVector2Array([Vector2(0, -radius), Vector2(0, radius * 0.4), Vector2(-radius * 0.5, radius), Vector2(-radius, radius * 0.6)])
			ci.draw_polyline(hook, OUTLINE, 3.0)
			ci.draw_polyline(hook, metal, 1.5)
		"needle":
			Blit.line(ci, Vector2(-radius * 3.0, 0), Vector2(radius * 3.0, 0), OUTLINE, 2.5)
			Blit.line(ci, Vector2(-radius * 3.0, 0), Vector2(radius * 3.0, 0), Color("dfe4e8"), 1.2)
			Blit.line(ci, Vector2(-radius * 3.0, 0), Vector2(-radius * 6.0, 2), Color("e0628f"), 1.0)
		"hairball":
			var pts := PackedVector2Array()
			for i in 12:
				var r := radius * (1.0 if i % 2 == 0 else 0.75)
				pts.append(Vector2.from_angle(TAU * i / 12.0) * r)
			ci.draw_colored_polygon(pts, Color("7a5235"))
			ci.draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
			Blit.line(ci, Vector2(-2, -1) * s, Vector2(2, 1) * s, Color("a8774f"), 1.0)
		_:
			Blit.disc(ci, Vector2.ZERO, radius + 1.0, OUTLINE)
			Blit.disc(ci, Vector2.ZERO, radius, Color("e0628f"))
			Blit.line(ci, Vector2(-radius, -1), Vector2(radius, 1), Color("f7a8c4"), 1.0)
			Blit.line(ci, Vector2(-1, -radius), Vector2(1, radius), Color("f7a8c4"), 1.0)
