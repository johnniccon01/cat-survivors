class_name TerritoryFlag
extends Node2D
## A boss's flag on a map you have not conquered yet. Stay next to it for a
## few seconds and it turns to your colour; take all of a night's flags and
## win the night, and the map is yours for good (Profile.TERRITORY_BONUS).
## An arrow at the screen edge shows the way while the flag still stands.

signal captured

const RADIUS := 70.0
const CAPTURE_TIME := 6.0
const OUTLINE := Color("2b1d14")
const BOSS := Color("d24a3a")
const YOURS := Color("3fbf8a")

var main: Node
## Seconds next to the flag to take it (tests make it shorter).
var capture_time := CAPTURE_TIME
var taken := false
var _progress := 0.0
var _t := 0.0
var _arrow: QuestArrow


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -2
	_arrow = QuestArrow.new()
	_arrow.color = Color("ff7a6a")
	_arrow.target = position
	main.hud.add_child(_arrow)


func _exit_tree() -> void:
	if is_instance_valid(_arrow):
		_arrow.queue_free()


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if taken:
		return
	var cat: Player = main.player
	if not cat.is_dead and cat.position.distance_to(position) < RADIUS:
		_progress += delta
	else:
		_progress = maxf(_progress - delta * 0.5, 0.0)
	if _progress >= capture_time:
		taken = true
		_arrow.target = null
		captured.emit()


func _draw() -> void:
	var col := YOURS if taken else BOSS
	# The ground it claims, and how far the capture has come.
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 48, Color(col, 0.55), 3.0)
	draw_circle(Vector2.ZERO, RADIUS, Color(col, 0.08))
	if not taken and _progress > 0.0:
		draw_arc(Vector2.ZERO, RADIUS - 6.0, -PI * 0.5, -PI * 0.5 + TAU * _progress / capture_time, 48, Color("f2c14e"), 5.0)
	# The pole and a waving flag.
	draw_rect(Rect2(-2, -46, 4, 48), OUTLINE)
	draw_rect(Rect2(-1, -45, 2, 46), Color("8a6a4a"))
	var wave := sin(_t * 5.0) * 2.5
	var pts := PackedVector2Array([Vector2(2, -46), Vector2(30, -44 + wave), Vector2(24, -36), Vector2(30, -28 + wave), Vector2(2, -28)])
	draw_colored_polygon(pts, OUTLINE)
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(p + (Vector2(12, -37) - p) * 0.12)
	draw_colored_polygon(inner, col)
	draw_circle(Vector2(0, -47), 3.0, Color("f2c14e"))
