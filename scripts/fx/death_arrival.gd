class_name DeathArrival
extends Node2D
## Death (the devil cat) arrives, played while the game is paused so nobody
## can miss it:
##   1. the world goes black and red, "Death is coming..."
##   2. a burning circle tears open, lightning strikes into it
##   3. Death climbs out, huge, scythe in paw
##   4. a red shockwave rolls out and every enemy on the map dies (reap);
##      only the cat is left standing
##   5. "Survive 5:00 – then Death can be hurt", and the hunt begins (finished)
## main.gd kills the enemies on `reap` and spawns the real devil on `finished`.

signal reap
signal finished

const DARKEN := 1.0
const OPEN := 2.6
const RISE := 3.8
const SHOCK := 4.4
const SHOCK_TIME := 1.0
const END := 7.4
const RED := Color(1.0, 0.15, 0.08)
const NIGHT := Color(0.06, 0.0, 0.02)

## The devil's look (CatArt) and where the cat stands (for the light on it).
var cat_pos := Vector2.ZERO
var survive_seconds := 300.0

var _t := 0.0
var _reaped := false
var _layer: CanvasLayer
var _title: Label
var _sub: Label
var _bolts: Array = []
var _thunder_at := [1.0, 1.9, 2.7, 4.4]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 4000
	_layer = CanvasLayer.new()
	_layer.layer = 5
	add_child(_layer)
	_title = _label(52, Color("ff4a3a"), 110)
	_title.text = tr("DEATH_TITLE")
	_sub = _label(26, Color("f2d6d0"), 180)
	_sub.text = tr("DEVIL_COMING")
	Audio.play("devil", 3.0, 0.0)


func _label(size: int, color: Color, top: float) -> Label:
	var l := Label.new()
	l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	l.offset_top = top
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = 8
	settings.outline_color = Color("120004")
	l.label_settings = settings
	l.modulate.a = 0.0
	_layer.add_child(l)
	return l


func _process(delta: float) -> void:
	_t += delta
	for at: float in _thunder_at.duplicate():
		if _t >= at:
			_thunder_at.erase(at)
			Audio.play("thunder", 2.0, 0.1)
			_strike()
	for bolt: Dictionary in _bolts:
		bolt["t"] = float(bolt["t"]) - delta
	_bolts = _bolts.filter(func(b: Dictionary) -> bool: return float(b["t"]) > 0.0)
	if not _reaped and _t >= SHOCK:
		_reaped = true
		Audio.play("roar", 4.0, 0.0)
		reap.emit()
	_title.modulate.a = clampf(_t / 0.8, 0.0, 1.0) * clampf((END - _t) / 0.6, 0.0, 1.0)
	_sub.modulate.a = _title.modulate.a
	if _t >= SHOCK + 0.4 and _sub.text == tr("DEVIL_COMING"):
		_sub.text = tr("DEATH_SURVIVE") % ("%d:%02d" % [int(survive_seconds) / 60, int(survive_seconds) % 60])
	if _t >= END:
		finished.emit()
		queue_free()
		return
	queue_redraw()


## A lightning bolt from the top of the screen into the circle.
func _strike() -> void:
	var pts := PackedVector2Array()
	var from := Vector2(randf_range(-260.0, 260.0), -420.0)
	for i in 9:
		var k := i / 8.0
		pts.append(from.lerp(Vector2.ZERO, k) + Vector2(randf_range(-22.0, 22.0) * (1.0 - k), 0))
	_bolts.append({"pts": pts, "t": 0.35})


func _draw() -> void:
	var fade_out := clampf((END - _t) / 0.8, 0.0, 1.0)
	var dark := clampf(_t / DARKEN, 0.0, 1.0) * 0.8 * fade_out
	draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(NIGHT, dark))
	# A red pulse over everything.
	draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(RED, 0.06 * dark * (0.6 + 0.4 * sin(_t * 5.0))))
	# A faint light on the cat, so it is clear who survives.
	Blit.disc(self, cat_pos - position, 26.0, Color(1.0, 0.9, 0.8, 0.12 * dark))

	# The circle tearing open.
	var k := clampf((_t - DARKEN * 0.6) / (OPEN - DARKEN * 0.6), 0.0, 1.0)
	var r := 8.0 + k * 70.0
	if k > 0.0:
		for i in 4:
			draw_circle(Vector2.ZERO, r + i * 18.0, Color(RED, 0.07 * fade_out))
		draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, r, r * 0.5, 40), Color(0.08, 0.0, 0.02, 0.95 * fade_out))
		draw_polyline(Shapes.closed(Shapes.ellipse(Vector2.ZERO, r, r * 0.5, 40)), Color(1.0, 0.35, 0.1, fade_out), 3.0)
		var star := PackedVector2Array()
		for i in 6:
			var p := Vector2.from_angle(-PI * 0.5 + i * TAU * 2.0 / 5.0) * r * 0.85
			star.append(Vector2(p.x, p.y * 0.5))
		draw_polyline(star, Color(1.0, 0.4, 0.1, 0.9 * fade_out), 2.0)
		for i in 24:
			var ang := TAU * i / 24.0 + _t * 0.7
			var base := Vector2(cos(ang) * r, sin(ang) * r * 0.5)
			var h := (10.0 + 10.0 * sin(_t * 9.0 + i * 1.7)) * k
			draw_line(base, base + Vector2(0, -h), Color(1.0, 0.45 + 0.3 * sin(i + _t * 5.0), 0.1, fade_out), 3.0)
		# Cracks running out over the floor.
		for i in 8:
			var d := Vector2.from_angle(TAU * i / 8.0 + 0.3)
			var crack := PackedVector2Array([d * r, d.rotated(0.2) * (r + 30.0 * k), d.rotated(-0.1) * (r + 70.0 * k)])
			for j in crack.size():
				crack[j].y *= 0.5
			draw_polyline(crack, Color(1.0, 0.3, 0.05, 0.8 * fade_out), 2.0)

	for bolt: Dictionary in _bolts:
		var a := float(bolt["t"]) / 0.35
		draw_polyline(bolt["pts"], Color(1.0, 0.85, 0.8, a), 4.0)
		draw_polyline(bolt["pts"], Color(1.0, 0.3, 0.2, a * 0.5), 10.0)
		draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(1.0, 0.9, 0.9, 0.12 * a))

	# Death climbs out, huge, and stays there until the hunt begins.
	var rise := clampf((_t - OPEN) / (RISE - OPEN), 0.0, 1.0)
	if rise > 0.0:
		var y := lerpf(30.0, -34.0, 1.0 - (1.0 - rise) * (1.0 - rise))
		var size := 2.6
		for i in 3:
			draw_circle(Vector2(0, y), 30.0 + i * 16.0, Color(RED, 0.1 * rise * fade_out))
		draw_set_transform(Vector2(0, y), 0.0, Vector2(size, size))
		CatArt.draw(self, CatArt.look("DEVIL"), 1, _t * 3.0, false, false, "angry", Vector2.ZERO, 1.0, false)
		# The scythe.
		draw_line(Vector2(9, 8), Vector2(13, -16), Color("3a2a22", rise), 1.6)
		draw_arc(Vector2(5, -16), 8.0, PI * 1.05, PI * 1.95, 12, Color("d8dde2", rise), 1.6)
		# Burning eyes.
		var glow := 0.6 + 0.4 * sin(_t * 8.0)
		draw_circle(Vector2(-2.5, -9), 1.2, Color(1.0, 0.2, 0.1, glow * rise))
		draw_circle(Vector2(2.5, -9), 1.2, Color(1.0, 0.2, 0.1, glow * rise))
		draw_set_transform(Vector2.ZERO)

	# The reaping shockwave.
	var s := (_t - SHOCK) / SHOCK_TIME
	if s > 0.0 and s < 1.0:
		var wave := 40.0 + s * 1500.0
		draw_arc(Vector2.ZERO, wave, 0.0, TAU, 96, Color(1.0, 0.25, 0.1, 1.0 - s), 14.0 * (1.0 - s) + 2.0)
		draw_arc(Vector2.ZERO, wave * 0.92, 0.0, TAU, 96, Color(1.0, 0.8, 0.6, 0.6 * (1.0 - s)), 4.0)
		draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(RED, 0.25 * (1.0 - s)))
