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
	var s := radius / 6.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
	# Spine, ribs, head and tail of a cartoon fish skeleton.
	Blit.rect(self, Rect2(-6, -1.5, 11, 3), OUTLINE)
	Blit.rect(self, Rect2(-6, -0.5, 11, 1), BONE)
	for x: float in [-3.0, 0.0, 3.0]:
		Blit.rect(self, Rect2(x - 1.5, -3, 3, 6), OUTLINE)
		Blit.rect(self, Rect2(x - 0.5, -3, 1, 6), BONE)
	Blit.disc(self, Vector2(6, 0), 3.0, OUTLINE)
	Blit.disc(self, Vector2(6, 0), 2.0, BONE)
	var tail := PackedVector2Array([Vector2(-6, 0), Vector2(-9, -3), Vector2(-9, 3)])
	draw_colored_polygon(tail, BONE)
	draw_polyline(Shapes.closed(tail), OUTLINE, 1.0)
