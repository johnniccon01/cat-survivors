extends ChainStep
## Follow a trail: reach one spot, and the next one shows up a bit further
## on. data: count, spacing [min, max], look.

const REACH := 26.0

var _found := 0
var _past: Array[Vector2] = []
var _dir := Vector2.RIGHT


func _ready() -> void:
	_dir = Vector2.from_angle(randf() * TAU)


func objective() -> String:
	return "%s %d/%d" % [step_text(), _found, int(data.get("count", 5))]


func _tick(_delta: float) -> void:
	if player_dist() > REACH:
		return
	_found += 1
	_past.append(position)
	Audio.play("pop", -6.0, 0.1)
	if _found >= int(data.get("count", 5)):
		complete()
		return
	var spacing: Array = data.get("spacing", [140.0, 200.0])
	_dir = _dir.rotated(randf_range(-0.9, 0.9))
	position += _dir * randf_range(float(spacing[0]), float(spacing[1]))


func _draw() -> void:
	var look: String = data.get("look", "crumbs")
	for p in _past:
		draw_look(p - position, look, 0.4)
	draw_look(Vector2.ZERO, look)
	draw_beacon(Vector2.ZERO, 16.0, Color("f2c14e"))
