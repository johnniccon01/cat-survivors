class_name BossArrows
extends Control
## Red arrows at the screen edge pointing at bosses that are off screen, so
## you know where the big ones will come from.

const MARGIN := 34.0
const MAX_ARROWS := 6
const COLOR := Color("e04646")
const OUTLINE := Color("2b1d14")

var _enemies: EnemyManager
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	if _enemies == null:
		_enemies = get_tree().get_first_node_in_group("enemy_manager") as EnemyManager
	queue_redraw()


func _draw() -> void:
	if _enemies == null:
		return
	var rect := get_viewport_rect().grow(-MARGIN)
	var center := rect.get_center()
	var half := rect.size * 0.5
	var shown := 0
	for e in _enemies.enemies:
		if shown >= MAX_ARROWS:
			break
		if e.dead or not GameData.enemies[e.id].get("boss", false):
			continue
		var screen: Vector2 = get_viewport().get_canvas_transform() * e.position
		if rect.has_point(screen):
			continue
		var dir := (screen - center).normalized()
		var k := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		var tip := center + dir * k
		var size := 13.0 + sin(_t * 5.0) * 1.5
		var side := dir.orthogonal() * size * 0.6
		var base := tip - dir * size
		var pts := PackedVector2Array([tip, base + side, base - side])
		draw_colored_polygon(pts, COLOR)
		draw_polyline(PackedVector2Array([tip, base + side, base - side, tip]), OUTLINE, 2.0)
		draw_circle(base - dir * 7.0, 4.0, OUTLINE)
		draw_circle(base - dir * 7.0, 3.0, Color("f2c14e"))
		shown += 1
