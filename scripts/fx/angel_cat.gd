class_name AngelCat
extends Node2D
## The angel cat's rescue, played while the game is paused so it reads as a
## moment of its own:
##   1. the cat falls, the world goes dark around it ("The cat has fallen...")
##   2. a beam of light opens and the angel floats down onto the cat
##   3. it touches the cat, a flash, and the cat stands back up (revive_now)
##   4. the angel rises and fades, the darkness lifts (finished)
## main.gd does the actual revive and unpauses on `finished`.

signal revive_now
signal finished

const FALL := 1.6
const DESCEND := 1.9
const HOVER := 1.6
const RISE := 1.6
## The angel is drawn this much bigger than a cat.
const ANGEL_SIZE := 2.0
const DARK := Color(0.04, 0.02, 0.08)

## The rescued cat's look and facing, drawn on top of the darkness.
var cat_look: Dictionary
var facing := 1

var _t := 0.0
var _revived := false
var _layer: CanvasLayer
var _text: Label
var _title: Label
var _feathers: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 4000
	_layer = CanvasLayer.new()
	_layer.layer = 5
	add_child(_layer)
	_text = Label.new()
	_text.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_text.offset_top = 120
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var settings := LabelSettings.new()
	settings.font_size = 34
	settings.font_color = Color("d9cce6")
	settings.outline_size = 6
	settings.outline_color = Color("2b1d14")
	_text.label_settings = settings
	_text.text = tr("ANGEL_FALLEN")
	_layer.add_child(_text)
	_title = Label.new()
	_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 60
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var big := LabelSettings.new()
	big.font_size = 52
	big.font_color = Color("fff1b8")
	big.outline_size = 8
	big.outline_color = Color("6a4a10")
	_title.label_settings = big
	_title.text = tr("ANGEL_TITLE")
	_title.modulate.a = 0.0
	_layer.add_child(_title)
	for i in 18:
		_feathers.append({"x": randf_range(-220.0, 220.0), "y0": randf_range(-420.0, -120.0), "speed": randf_range(40.0, 80.0), "phase": randf() * TAU})
	Audio.play("fall", 0.0, 0.0)


func _process(delta: float) -> void:
	_t += delta
	var hover_end := FALL + DESCEND + HOVER
	if _t >= FALL and _t - delta < FALL:
		Audio.play("angel", -2.0, 0.0)
	if not _revived and _t >= FALL + DESCEND + HOVER * 0.5:
		_revived = true
		_text.text = tr("ANGEL_SAVED")
		_text.label_settings.font_color = Color("f2d14e")
		revive_now.emit()
	_text.modulate.a = clampf((hover_end + RISE - _t) / 0.6, 0.0, 1.0)
	_title.modulate.a = clampf((_t - FALL) / 0.5, 0.0, 1.0) * _text.modulate.a
	if _t >= hover_end + RISE:
		finished.emit()
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var hover_end := FALL + DESCEND + HOVER
	# Darkness: in over the fall, out while the angel leaves.
	var dark := clampf(_t / 0.8, 0.0, 1.0) * 0.72
	if _t > hover_end:
		dark *= 1.0 - clampf((_t - hover_end) / RISE, 0.0, 1.0)
	draw_rect(Rect2(-3000, -3000, 6000, 6000), Color(DARK, dark))

	# Beam of light and the angel.
	var beam := clampf((_t - FALL) / 0.6, 0.0, 1.0) * (1.0 - clampf((_t - hover_end) / RISE, 0.0, 1.0))
	if beam > 0.0:
		# Rays fanning down from the sky, slowly swaying.
		for i in 9:
			var x := -320.0 + i * 80.0 + sin(_t * 0.8 + i) * 12.0
			draw_colored_polygon(PackedVector2Array([Vector2(x * 0.3 - 10, -600), Vector2(x * 0.3 + 10, -600), Vector2(x + 28, 40), Vector2(x - 28, 40)]), Color(1.0, 0.93, 0.6, 0.05 * beam))
		# Feathers drifting down.
		for f: Dictionary in _feathers:
			var fy := fmod(float(f["y0"]) + (_t - FALL) * float(f["speed"]), 460.0) - 400.0
			var fx := float(f["x"]) + sin(_t * 2.0 + float(f["phase"])) * 14.0
			var tilt := sin(_t * 2.0 + float(f["phase"])) * 0.6
			var tip := Vector2(0, -6).rotated(tilt)
			draw_line(Vector2(fx, fy) - tip, Vector2(fx, fy) + tip, Color(1, 1, 1, 0.85 * beam), 3.0)
			draw_line(Vector2(fx, fy) - tip, Vector2(fx, fy) + tip, Color(1.0, 0.9, 0.6, 0.9 * beam), 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-14, -400), Vector2(14, -400), Vector2(34, 12), Vector2(-34, 12)]), Color(1.0, 0.95, 0.7, 0.2 * beam))
		for i in 5:
			draw_circle(Vector2(0, 2), 14.0 + i * 9.0, Color(1.0, 0.95, 0.75, 0.05 * beam))

	# The cat itself: lying down until the angel's touch, then up again.
	if not cat_look.is_empty():
		CatArt.draw(self, cat_look, facing, 0.0, false, not _revived, "normal", Vector2.ZERO, 1.0, false)
	if _revived:
		var k := clampf((_t - (FALL + DESCEND + HOVER * 0.5)) / 0.6, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 10.0 + k * 70.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.7, 1.0 - k), 3.0)

	var y := -150.0
	var alpha := 0.0
	if _t >= FALL and _t < FALL + DESCEND:
		var k := (_t - FALL) / DESCEND
		y = lerpf(-260.0, -44.0, 1.0 - (1.0 - k) * (1.0 - k))
		alpha = k
	elif _t >= FALL + DESCEND and _t < hover_end:
		y = -44.0
		alpha = 1.0
	elif _t >= hover_end:
		var k := (_t - hover_end) / RISE
		y = lerpf(-44.0, -300.0, k * k)
		alpha = 1.0 - k
	if alpha <= 0.0:
		return
	y += sin(_t * 4.0) * 2.0
	for i in 8:
		var a := _t * 1.5 + TAU * i / 8.0
		var p := Vector2(0, y) + Vector2.from_angle(a) * (24.0 + sin(_t * 3.0 + i) * 4.0)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.97, 0.8, alpha))
	for i in 4:
		draw_circle(Vector2(0, y), 24.0 + i * 12.0, Color(1.0, 0.95, 0.75, 0.08 * alpha))
	# A halo and big wings behind the (bigger than life) angel.
	draw_set_transform(Vector2(0, y), 0.0, Vector2(ANGEL_SIZE, ANGEL_SIZE))
	var flap := sin(_t * 5.0) * 0.25
	for side: float in [-1.0, 1.0]:
		var wing := PackedVector2Array([Vector2(side * 3, -4), Vector2(side * 16, -14 - flap * 10), Vector2(side * 19, -4), Vector2(side * 13, 2), Vector2(side * 4, 0)])
		draw_colored_polygon(wing, Color(1, 1, 1, 0.9 * alpha))
		draw_polyline(Shapes.closed(wing), Color(0.85, 0.75, 0.5, alpha), 0.6)
	draw_arc(Vector2(0, -15), 5.0, 0.0, TAU, 20, Color(1.0, 0.85, 0.3, alpha), 1.2)
	CatArt.draw(self, CatArt.look("ANGEL"), facing, _t * 6.0, false, false, "normal", Vector2.ZERO, 1.0, false)
	draw_set_transform(Vector2.ZERO)
	if alpha < 1.0:
		draw_circle(Vector2(0, y), 36.0, Color(1.0, 0.97, 0.85, (1.0 - alpha) * 0.9))
