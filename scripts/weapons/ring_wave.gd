class_name RingWave
extends Node2D
## An expanding ring that hits each enemy once as it passes over them.

var enemies: EnemyManager
## The weapon that made this (for its branch effects); may be null.
var source: Weapon
var max_radius := 90.0
var expand_time := 0.45
var damage := 15.0
var knockback := 2.0
var color := Color("f2c14e")
## Draws the bell above the cat (only the bell weapon wants it).
var bell := false

var _age := 0.0
var _radius := 0.0
var _hit: Dictionary = {}


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 4


func _physics_process(delta: float) -> void:
	_age += delta
	var k := _age / expand_time
	if k >= 1.3:
		queue_free()
		return
	_radius = max_radius * minf(k, 1.0)
	if k <= 1.0:
		for enemy in enemies.query_radius(position, _radius):
			var key := enemy.get_instance_id()
			if _hit.has(key):
				continue
			_hit[key] = true
			Weapon.strike_from(source, enemy, damage, enemy.position - position, knockback)
	queue_redraw()


func _draw() -> void:
	var a := clampf(1.3 - _age / expand_time, 0.0, 1.0)
	Blit.disc(self, Vector2.ZERO, _radius, Color(color, 0.06 * a))
	Blit.ring(self, Vector2.ZERO, _radius + 14.0 * 0.5, 14.0, Color(color, 0.12 * a))
	Blit.ring(self, Vector2.ZERO, _radius + 6.0 * 0.5, 6.0, Color(color, 0.25 * a))
	Blit.ring(self, Vector2.ZERO, _radius + 2.0 * 0.5, 2.0, Color(color, 0.9 * a))
	Blit.ring(self, Vector2.ZERO, _radius * 0.8 + 1.0 * 0.5, 1.0, Color(1, 1, 1, 0.35 * a))
	if bell and _age < 0.2:
		# The bell itself, briefly, above the cat.
		var b := Vector2(0, -20)
		var bell := PackedVector2Array([b + Vector2(-4, 3), b + Vector2(-3, -3), b + Vector2(0, -5), b + Vector2(3, -3), b + Vector2(4, 3)])
		draw_colored_polygon(bell, color)
		draw_polyline(Shapes.closed(bell), Color("2b1d14"), 1.0)
		Blit.disc(self, b + Vector2(0, 4), 1.2, Color("2b1d14"))
