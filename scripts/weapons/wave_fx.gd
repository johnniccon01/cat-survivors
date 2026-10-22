class_name WaveFx
extends Node2D
## A rolling wall of water: hits each enemy it passes once and pushes it
## along, then fades after `distance`.

var weapon: Weapon
var dir := Vector2.RIGHT
var height := 64.0
var distance := 240.0
var speed := 260.0
var damage := 12.0
var knockback := 2.0

var _travelled := 0.0
var _hit: Dictionary = {}
var _t := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 3


func _physics_process(delta: float) -> void:
	_t += delta
	var step := speed * delta
	position += dir * step
	_travelled += step
	if _travelled >= distance or not is_instance_valid(weapon):
		queue_free()
		return
	var rect := Rect2(position + Vector2(-12, -height * 0.5), Vector2(24, height))
	for e in weapon.enemies.query_rect(rect):
		var key := e.get_instance_id()
		if _hit.has(key):
			continue
		_hit[key] = true
		Weapon.strike_from(weapon, e, damage, dir, knockback)
	queue_redraw()


func _draw() -> void:
	var a := clampf(1.0 - _travelled / distance, 0.0, 1.0) * 0.9 + 0.1
	var h := height * 0.5
	var crest := PackedVector2Array()
	var back := PackedVector2Array()
	for i in 9:
		var y := -h + i * height / 8.0
		var wob := sin(_t * 14.0 + i) * 3.0
		crest.append(Vector2((10.0 + wob) * dir.x, y))
		back.append(Vector2((-16.0 + wob * 0.5) * dir.x, y))
	back.reverse()
	draw_colored_polygon(crest + back, Color(0.35, 0.65, 0.95, 0.45 * a))
	draw_polyline(crest, Color(0.9, 0.97, 1.0, a), 3.0)
	for i in 5:
		Blit.disc(self, crest[i * 2] + Vector2(3.0 * dir.x, 0), 2.0, Color(1, 1, 1, 0.8 * a))
