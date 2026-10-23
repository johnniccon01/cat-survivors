class_name BossArrows
extends Control
## Red arrows at the screen edge pointing at bosses that are off screen, so
## you know where the big ones will come from; a golden one for the golden
## mouse.

const MARGIN := 34.0
const MAX_ARROWS := 6
const COLOR := Color("e04646")
## The golden mouse gets a golden arrow (and a marker while on screen).
const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")

const CHEST := Color("ffd76a")

var _enemies: EnemyManager
var _pickups: Pickups
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
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var view := get_viewport_rect()
	var rect := view.grow(-MARGIN)
	var center := rect.get_center()
	var half := rect.size * 0.5
	var shown := 0
	for e in _enemies.enemies:
		if shown >= MAX_ARROWS:
			break
		var golden := e.id == "GOLDEN_MOUSE"
		if e.dead or not (golden or GameData.enemies[e.id].get("boss", false)):
			continue
		var screen: Vector2 = (e.position - camera.get_screen_center_position()) * camera.zoom + view.size * 0.5
		if rect.has_point(screen):
			# The golden mouse hides in crowds: a bouncing marker above it.
			if golden:
				var top := screen - Vector2(0, 26.0 + 22.0 * camera.zoom.y + absf(sin(_t * 6.0)) * 8.0)
				var mark := PackedVector2Array([top + Vector2(0, 14), top + Vector2(-10, 0), top + Vector2(10, 0)])
				draw_colored_polygon(mark, GOLD)
				draw_polyline(PackedVector2Array([mark[0], mark[1], mark[2], mark[0]]), OUTLINE, 2.0)
			continue
		var dir := (screen - center).normalized()
		var k := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		var tip := center + dir * k
		var size := (22.0 if golden else 18.0) + sin(_t * 5.0) * 2.0
		var side := dir.orthogonal() * size * 0.6
		var base := tip - dir * size
		var pts := PackedVector2Array([tip, base + side, base - side])
		draw_colored_polygon(pts, GOLD if golden else COLOR)
		draw_polyline(PackedVector2Array([tip, base + side, base - side, tip]), OUTLINE, 2.0)
		draw_circle(base - dir * 8.0, 5.5, OUTLINE)
		draw_circle(base - dir * 8.0, 4.0, Color("fff3c8") if golden else Color("f2c14e"))
		shown += 1
	# Chests lying off screen get a golden arrow, so none is forgotten.
	if _pickups == null:
		_pickups = get_tree().get_first_node_in_group("pickups") as Pickups
	if _pickups != null:
		for item in _pickups.items:
			if item.kind != Pickup.Kind.CHEST:
				continue
			var screen: Vector2 = (item.position - camera.get_screen_center_position()) * camera.zoom + view.size * 0.5
			if rect.has_point(screen):
				continue
			var dir := (screen - center).normalized()
			var k := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
			var tip := center + dir * k
			var size := (20.0 if item.value >= 2.0 else 16.0) + sin(_t * 6.0) * 2.5
			var side := dir.orthogonal() * size * 0.6
			var base := tip - dir * size
			draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), CHEST)
			draw_polyline(PackedVector2Array([tip, base + side, base - side, tip]), OUTLINE, 2.0)
			# A little chest behind the arrow.
			var c := base - dir * 11.0
			draw_rect(Rect2(c - Vector2(7, 5), Vector2(14, 10)), OUTLINE)
			draw_rect(Rect2(c - Vector2(6, 4), Vector2(12, 8)), Color("7d52b8") if item.value >= 2.0 else Color("a8703a"))
			draw_rect(Rect2(c - Vector2(1, 2), Vector2(2, 3)), GOLD)
	# Shrines waiting to be woken get an arrow in their colour.
	for node in get_tree().get_nodes_in_group("shrine"):
		var s := node as Shrine
		if s.used:
			continue
		var screen: Vector2 = (s.position - camera.get_screen_center_position()) * camera.zoom + view.size * 0.5
		if rect.has_point(screen):
			continue
		var dir := (screen - center).normalized()
		var k := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		var tip := center + dir * k
		var size := 16.0 + sin(_t * 4.0) * 2.0
		var side := dir.orthogonal() * size * 0.6
		var base := tip - dir * size
		draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), s.color())
		draw_polyline(PackedVector2Array([tip, base + side, base - side, tip]), OUTLINE, 2.0)
		draw_circle(base - dir * 8.0, 5.0, OUTLINE)
		draw_circle(base - dir * 8.0, 3.5, s.color().lightened(0.4))
