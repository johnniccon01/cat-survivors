class_name OrbitProjectile
extends Node2D
## A fish bone circling the player. Can hit the same enemy again after
## HIT_DELAY seconds.

const HIT_DELAY := 0.6
const OUTLINE := Color("2b1d14")
const BONE := Color("eae4d3")

var player: Player
var enemies: EnemyManager
## The weapon that made this (for its branch effects); may be null.
var source: Weapon
var angle := 0.0
var orbit_radius := 40.0
var angular_speed := 3.0
var radius := 6.0
var damage := 10.0
var knockback := 0.8
var lifetime := 3.0

var _time := 0.0
var _last_hit: Dictionary = {}


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 3


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or not is_instance_valid(player):
		queue_free()
		return
	_time += delta
	angle += angular_speed * delta
	position = player.position + Vector2.from_angle(angle) * orbit_radius
	rotation = angle + PI * 0.5
	for enemy in enemies.query_radius(position, radius):
		var key := enemy.get_instance_id()
		if _time - float(_last_hit.get(key, -INF)) < HIT_DELAY:
			continue
		_last_hit[key] = _time
		Weapon.strike_from(source, enemy, damage, enemy.position - player.position, knockback)


func _draw() -> void:
	if not Shots.draw(self, "bone", radius):
		OrbitProjectile.draw_body(self, radius)


## The fish bone drawn from shapes (what tools/bake_art.gd bakes).
static func draw_body(ci: CanvasItem, radius: float) -> void:
	var s := radius / 6.0
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
	# Spine, ribs, head and tail of a cartoon fish skeleton.
	Blit.rect(ci, Rect2(-6, -1.5, 11, 3), Icons.edge(BONE))
	Blit.rect(ci, Rect2(-6, -0.5, 11, 1), BONE)
	for x: float in [-3.0, 0.0, 3.0]:
		Blit.rect(ci, Rect2(x - 1.5, -3, 3, 6), Icons.edge(BONE))
		Blit.rect(ci, Rect2(x - 0.5, -3, 1, 6), BONE)
	Blit.disc(ci, Vector2(6, 0), 3.0, Icons.edge(BONE))
	Blit.disc(ci, Vector2(6, 0), 2.0, BONE)
	var tail := PackedVector2Array([Vector2(-6, 0), Vector2(-9, -3), Vector2(-9, 3)])
	ci.draw_colored_polygon(tail, BONE)
	ci.draw_polyline(Shapes.closed(tail), Icons.edge(BONE), 1.0)
