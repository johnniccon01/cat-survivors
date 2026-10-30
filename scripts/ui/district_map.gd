class_name DistrictMap
extends Control
## The neighbourhood at night: every map is a place on one hand-built pixel
## town (the flat, the garden, the block of flats, the supermarket, the
## harbour, the factory) with roads, a railway, street lamps, lit windows,
## smoke, a boat and a passing train. Places that are not open yet sit in
## fog; future maps (park, cemetery, island, station) wait beyond them.
## Drag to look around, click a sign to choose a place.

signal place_chosen(id: String)
signal report_chosen(index: int)
signal moon_chosen
signal resident_chosen(cat: String)

## Where each resident lives in the town.
const RESIDENT_SPOTS := {
	"OLD_CAT": Vector2(150, 47), "BOLT": Vector2(312, 66), "TUCKO": Vector2(300, 216),
	"KAPITAN": Vector2(370, 226), "CLOVER": Vector2(126, 97),
}

## Night report kinds: sign letter and colour.
const REPORT_LOOK := {"trip": ["»", Color("8a4ad0")], "defend": ["!", Color("c0392b")], "hunt": ["★", Color("d4801c")], "gold": ["$", Color("2f8a6a")], "rescue": ["+", Color("3a6ad0")]}

const WW := 720
const WH := 300
## One town pixel is at least this many screen pixels; a taller or wider map
## area zooms in further so the town always fills it.
const MIN_PX := 2.0
## How many steps the mouse wheel can zoom in past the fill level.
const MAX_ZOOM := 2.0
const SEA_B := 252.0
const OUTLINE := Color("2b1d14")

## Where every map sits in the town, and the part of the town its picture
## in the side panel shows.
const PLACES := {
	"LIVING_ROOM": {"pos": Vector2(70, 142), "view": Rect2(30, 140, 120, 95)},
	"BASEMENT": {"pos": Vector2(56, 224), "view": Rect2(30, 176, 120, 74)},
	"GARDEN": {"pos": Vector2(96, 40), "view": Rect2(10, 8, 172, 98)},
	"ROOFTOP": {"pos": Vector2(262, 14), "view": Rect2(214, 0, 100, 112)},
	"SUPERMARKET": {"pos": Vector2(260, 128), "view": Rect2(206, 134, 108, 100)},
	"HARBOR": {"pos": Vector2(350, 166), "view": Rect2(300, 128, 140, 100)},
	"FACTORY": {"pos": Vector2(376, 46), "view": Rect2(318, 0, 122, 108)},
	"PARK": {"pos": Vector2(520, 50), "view": Rect2(446, 0, 146, 118)},
	"CEMETERY": {"pos": Vector2(660, 50), "view": Rect2(600, 0, 120, 118)},
	"ISLAND": {"pos": Vector2(622, 190), "view": Rect2(570, 166, 104, 76)},
	"STATION": {"pos": Vector2(140, 276), "view": Rect2(56, 250, 170, 50)},
}
## Paths from the open maps on to the future ones (still in fog).
const FUTURE_LINKS := []
## Fog over each place until it opens.
const FOG := {
	"FACTORY": Rect2(318, 0, 126, 110), "PARK": Rect2(446, 0, 146, 118), "CEMETERY": Rect2(600, 0, 120, 118),
	"ISLAND": Rect2(576, 178, 92, 56), "STATION": Rect2(56, 274, 170, 26),
}

## Home bonus stats -> [text key, multiplier for the shown number].
const HOME_STATS := {
	"might": ["BONUS_MIGHT", 100.0], "cooldown": ["BONUS_COOLDOWN", -100.0], "area": ["BONUS_AREA", 100.0],
	"speed": ["BONUS_SPEED", 100.0], "max_hp": ["BONUS_MAX_HP", 1.0], "luck": ["BONUS_LUCK", 100.0],
	"regen": ["BONUS_REGEN", 1.0], "growth": ["BONUS_GROWTH", 100.0], "magnet": ["BONUS_MAGNET", 1.0],
	"proj_speed": ["BONUS_PROJ_SPEED", 100.0],
}

static var _image: Image
static var _lamps: Array[Vector2] = []
static var _candles: Array[Vector2] = []
static var _lit: Array = []

var selected := ""
## Screen pixels per town pixel right now (see MIN_PX).
var px := MIN_PX
## The zoom that just fills the map area (the wheel never goes below it).
var _fill_px := MIN_PX
var cam := Vector2.ZERO
var _cam_to := Vector2.ZERO
var _t := 0.0
var _world: Control
var _pins_layer: Control
var _anim: Control
var _windows: Control
var _lights: Control
var _fx: Control
var _texture: ImageTexture
var _glow: GradientTexture2D
var _pins := {}
var _ring: Control
var _drag := false
var _dragged := false
var _water: PackedVector2Array = []
var _puffs := {}
var _mini: Control
var _arrows := {}
var _reports: Array[Control] = []
var _hover := ""
## The resident under the mouse: its service is shown beside it.
var _hover_cat := ""
var _hint: PanelContainer
var _paths_btn: Button
var _press_at := Vector2.ZERO
## The night report on show in the side panel, or -1.
var selected_report := -1


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _image == null:
		_build_town()
	_texture = ImageTexture.create_from_image(_image)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	_glow = GradientTexture2D.new()
	_glow.gradient = g
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)
	_glow.width = 64
	_glow.height = 64
	for y in range(140, int(SEA_B), 3):
		for x in range(0, WW, 4):
			if _is_water(x, y) and _is_water(x - 4, y):
				_water.append(Vector2(x, y))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for id: String in FOG:
		var r: Rect2 = FOG[id]
		var list: Array = []
		for i in maxi(8, int(r.size.x * r.size.y / 500.0)):
			list.append([r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y), 10.0 + rng.randf() * 14.0, rng.randf() * 6.0])
		_puffs[id] = list

	_world = Control.new()
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.scale = Vector2(px, px)
	_world.size = Vector2(WW, WH)
	add_child(_world)
	var base := TextureRect.new()
	base.texture = _texture
	base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(base)
	_anim = _layer(_draw_anim)
	# Night: everything is multiplied by a blue that deepens to the south-east.
	var night := TextureRect.new()
	var ng := Gradient.new()
	ng.set_color(0, Color8(112, 122, 182))
	ng.set_color(1, Color8(66, 72, 128))
	var nt := GradientTexture2D.new()
	nt.gradient = ng
	nt.fill_from = Vector2(0, 0)
	nt.fill_to = Vector2(1, 1)
	night.texture = nt
	night.size = Vector2(WW, WH)
	night.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mul := CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	night.material = mul
	_world.add_child(night)
	_windows = _layer(_draw_windows)
	_lights = _layer(_draw_lights)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_lights.material = add
	_fx = _layer(_draw_fx)

	_pins_layer = Control.new()
	_pins_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pins_layer)
	_ring = Control.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.size = Vector2(WW, WH) * px
	_ring.draw.connect(_draw_ring)
	_pins_layer.add_child(_ring)
	for id: String in PLACES:
		_add_pin(id)

	# Edge arrows (only where there is more town) and a minimap.
	for d: String in ["l", "r", "u", "d"]:
		var b := UiStyle.click_button({"l": "‹", "r": "›", "u": "", "d": ""}[d], 40, 24)
		b.custom_minimum_size = Vector2(40, 40)
		if d == "u" or d == "d":
			# Up and down are drawn: the font has no such arrows.
			var up := d == "u"
			b.draw.connect(func() -> void:
				var c := b.size * 0.5
				var k := -1.0 if up else 1.0
				b.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -4 * k), c + Vector2(8, -4 * k), c + Vector2(0, 5 * k)]), UiStyle.GOLD))
		var step: Vector2 = {"l": Vector2(-220, 0), "r": Vector2(220, 0), "u": Vector2(0, -120), "d": Vector2(0, 120)}[d]
		b.pressed.connect(func() -> void: _cam_to = _clamp_cam(_cam_to + step))
		add_child(b)
		_arrows[d] = b
	_mini = Control.new()
	_mini.custom_minimum_size = Vector2(180, 75)
	_mini.size = Vector2(180, 75)
	_mini.mouse_filter = Control.MOUSE_FILTER_STOP
	_mini.draw.connect(_draw_mini)
	_mini.gui_input.connect(_on_mini_input)
	add_child(_mini)
	# The paths between the places can be switched off.
	_paths_btn = UiStyle.click_button(tr("DISTRICT_PATHS"), 120, 14)
	_paths_btn.pressed.connect(func() -> void:
		Settings.toggle_map_paths()
		_style_paths_btn())
	add_child(_paths_btn)
	_style_paths_btn()
	# A short hint in the bottom-right corner: closes with its cross and
	# fades away by itself after a few seconds.
	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", UiStyle.box(Color(0.06, 0.05, 0.09, 0.8), Color("4a3f5c")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(UiStyle.label(tr("DISTRICT_HINT"), 13, Color("cfc3dc")))
	# The font has no cross: it is drawn.
	var close := UiStyle.click_button("", 26, 13)
	close.custom_minimum_size = Vector2(26, 22)
	close.draw.connect(func() -> void:
		var c := close.size * 0.5
		close.draw_line(c + Vector2(-4, -4), c + Vector2(4, 4), UiStyle.GOLD, 2.0)
		close.draw_line(c + Vector2(4, -4), c + Vector2(-4, 4), UiStyle.GOLD, 2.0))
	close.pressed.connect(_hide_hint)
	row.add_child(close)
	_hint.add_child(row)
	add_child(_hint)
	get_tree().create_timer(5.0).timeout.connect(_hide_hint)
	resized.connect(_place_controls)
	_place_controls()


func _hide_hint() -> void:
	if not is_instance_valid(_hint) or not _hint.visible:
		return
	var tw := _hint.create_tween()
	tw.tween_property(_hint, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_hint.hide)


func _style_paths_btn() -> void:
	_paths_btn.modulate = Color.WHITE if Settings.map_paths else Color(1, 1, 1, 0.5)


func _layer(fn: Callable) -> Control:
	var c := Control.new()
	c.size = Vector2(WW, WH)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(fn.bind(c))
	_world.add_child(c)
	return c


func view_size() -> Vector2:
	return size / px


func _clamp_cam(c: Vector2) -> Vector2:
	var v := view_size()
	return Vector2(clampf(c.x, 0.0, maxf(WW - v.x, 0.0)), clampf(c.y, 0.0, maxf(WH - v.y, 0.0)))


func _place_controls() -> void:
	_fill_px = maxf(MIN_PX, ceilf(maxf(size.y / WH, size.x / WW)))
	if px < _fill_px and size.x > 0.0:
		_set_px(_fill_px, size * 0.5)
	_arrows["l"].position = Vector2(10, size.y * 0.5 - 20)
	_arrows["r"].position = Vector2(size.x - 50, size.y * 0.5 - 20)
	_arrows["u"].position = Vector2(size.x * 0.5 - 20, 10)
	_arrows["d"].position = Vector2(size.x * 0.5 - 20, size.y - 50)
	_mini.position = Vector2(size.x - 192, 12)
	_paths_btn.reset_size()
	_paths_btn.position = Vector2(size.x - 12 - _paths_btn.size.x, 94)
	_hint.reset_size()
	_hint.position = Vector2(size.x - _hint.size.x - 10, size.y - _hint.size.y - 58)
	# The real size is only known now: centre on the chosen place again.
	if selected != "":
		select(selected, cam == Vector2.ZERO)
	else:
		_cam_to = _clamp_cam(_cam_to)


## Chooses a place: its sign lights up and the town glides to it.
func select(id: String, instant: bool = false) -> void:
	selected = id
	for pid: String in _pins:
		_style_pin(pid)
	var v := view_size()
	_cam_to = _clamp_cam(PLACES[id]["pos"] - v * 0.5 + Vector2(0, 20))
	for i in _reports.size():
		_reports[i].queue_redraw()
	if instant:
		cam = _cam_to
	_ring.queue_redraw()


func view_rect(id: String) -> Rect2:
	return PLACES[id]["view"]


func town_texture() -> Texture2D:
	return _texture


func _process(delta: float) -> void:
	_t += delta
	if not _drag:
		cam = cam.lerp(_cam_to, minf(1.0, delta * 7.0))
	# Snap to whole screen pixels, not whole town pixels: a smooth glide.
	_world.position = (-cam * px).round()
	_pins_layer.position = _world.position
	_arrows["l"].visible = _cam_to.x > 1.0
	_arrows["r"].visible = _cam_to.x < WW - view_size().x - 1.0
	_arrows["u"].visible = _cam_to.y > 1.0
	_arrows["d"].visible = _cam_to.y < WH - view_size().y - 1.0
	# Everything that moves is redrawn every frame, so nothing stutters.
	_anim.queue_redraw()
	_windows.queue_redraw()
	_lights.queue_redraw()
	_fx.queue_redraw()
	_ring.queue_redraw()
	_mini.queue_redraw()
	for i in _reports.size():
		var r: Control = _reports[i]
		r.position = r.get_meta("at") + Vector2(0, sin(_t * 3.5 + i) * 4.0)
		if i == 0:
			r.queue_redraw()


## What is under the mouse: a report sign ("report", index; the moon is -1),
## a place's sign or building ("place", id), or nothing ([]).
func _hit(global: Vector2, local: Vector2) -> Array:
	for sign in _reports:
		if sign.get_global_rect().grow(4).has_point(global):
			return ["report", int(sign.get_meta("report"))]
	for id: String in _pins:
		if (_pins[id] as Control).get_global_rect().grow(3).has_point(global):
			return ["place", id]
	# A resident (or the empty spot of a kidnapped one).
	var town := cam + local / px
	for cat: String in RESIDENT_SPOTS:
		if (Profile.is_unlocked(cat)) and town.distance_to(RESIDENT_SPOTS[cat] - Vector2(0, 4)) < 9.0:
			return ["resident", cat]
	# A click on a building: the smallest place whose area holds the point.
	var at := cam + local / px
	var best := ""
	var best_area := INF
	for id: String in PLACES:
		var r: Rect2 = PLACES[id]["view"]
		if r.has_point(at) and r.get_area() < best_area:
			best = id
			best_area = r.get_area()
	return ["place", best] if best != "" else []


## Zooms to `new_px` screen pixels per town pixel, keeping the town point
## under `focus` (map coordinates) where it is.
func _set_px(new_px: float, focus: Vector2) -> void:
	var town := cam + focus / px
	px = new_px
	_world.scale = Vector2(px, px)
	# The paths layer must cover the whole town, or Godot hides it whenever
	# its corner scrolls off screen.
	_ring.size = Vector2(WW, WH) * px
	cam = _clamp_cam(town - focus / px)
	_cam_to = cam
	for id: String in _pins:
		_style_pin(id)
	if not _reports.is_empty():
		show_reports()


func _gui_input(event: InputEvent) -> void:
	# The mouse wheel zooms in (up to MAX_ZOOM more) and back out.
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var step := 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
		var target := clampf(px + step, _fill_px, _fill_px + MAX_ZOOM)
		if target != px:
			_set_px(target, event.position)
		return
	if event is InputEventMouseMotion and not _drag:
		var hit := _hit(event.global_position, event.position)
		var over: String = hit[1] if not hit.is_empty() and hit[0] == "place" else ""
		if over != _hover:
			_hover = over
			_ring.queue_redraw()
		_hover_cat = hit[1] if not hit.is_empty() and hit[0] == "resident" else ""
		mouse_default_cursor_shape = Control.CURSOR_ARROW if hit.is_empty() else Control.CURSOR_POINTING_HAND
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag = event.pressed
		if event.pressed:
			_dragged = false
			_press_at = event.position
		elif not _dragged:
			# A press and release without dragging is a click.
			var hit := _hit(event.global_position, event.position)
			if hit.is_empty():
				return
			if hit[0] == "place":
				place_chosen.emit(hit[1])
			elif hit[0] == "resident":
				resident_chosen.emit(hit[1])
			elif hit[1] < 0:
				moon_chosen.emit()
			else:
				report_chosen.emit(hit[1])
		return
	if event is InputEventMouseMotion and _drag:
		# A few pixels of wobble while clicking is still a click.
		if event.position.distance_to(_press_at) > 6.0:
			_dragged = true
		if not _dragged:
			return
		cam = _clamp_cam(cam - event.relative / px)
		_cam_to = cam


func _on_mini_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_cam_to = _clamp_cam(event.position / _mini.size * Vector2(WW, WH) - view_size() * 0.5)


# --- signs on the map ---------------------------------------------------------

## The night reports (Profile.reports) as bobbing round signs beside their
## places, and the moon over your home (nights left, or glowing when full).
func show_reports() -> void:
	for r in _reports:
		r.queue_free()
	_reports.clear()
	var moon := Control.new()
	moon.size = Vector2(40, 40)
	moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon.set_meta("report", -1)
	var home: Vector2 = PLACES["LIVING_ROOM"]["pos"] * px
	moon.set_meta("at", Vector2(home.x - 90, home.y - 40))
	moon.position = moon.get_meta("at")
	moon.draw.connect(func() -> void: draw_moon(moon, moon.size * 0.5, 15.0, Profile.nights_to_moon(), _t))
	_pins_layer.add_child(moon)
	_reports.append(moon)
	for i in Profile.reports.size():
		var rep: Dictionary = Profile.reports[i]
		if not PLACES.has(rep["stage"]):
			continue
		var sign := Control.new()
		sign.size = Vector2(34, 34)
		sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sign.set_meta("report", i)
		var p: Vector2 = PLACES[rep["stage"]]["pos"] * px
		sign.set_meta("at", Vector2(p.x + 34, p.y - 30))
		sign.position = sign.get_meta("at")
		sign.draw.connect(_draw_report.bind(sign, i))
		_pins_layer.add_child(sign)
		_reports.append(sign)


## A moon `nights` nights from full (0 = full, glowing), on any canvas item.
static func draw_moon(ci: CanvasItem, c: Vector2, r: float, nights: int, t: float, number: bool = true) -> void:
	if nights == 0:
		ci.draw_circle(c, r + 6.0 + sin(t * 3.0) * 2.0, Color(1, 0.9, 0.5, 0.35))
	ci.draw_circle(c + Vector2(0, 3), r + 1.0, Color(0, 0, 0, 0.45))
	ci.draw_circle(c, r + 2.0, Color("2a2238"))
	ci.draw_circle(c, r, Color("f4ecd4"))
	ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.25), r * 0.22, Color("d8ccb0"))
	ci.draw_circle(c + Vector2(r * 0.35, r * 0.3), r * 0.15, Color("d8ccb0"))
	if nights > 0:
		# The dark part shrinks as the full moon nears.
		var k := float(nights) / float(Profile.MOON_CYCLE - 1)
		ci.draw_circle(c + Vector2(r * (2.0 - 1.4 * k), 0), r * 0.98, Color("2a2238"))
		if number:
			ci.draw_string(ThemeDB.fallback_font, c + Vector2(-r, r + 15), str(nights), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 14, Color("f4ecd4"))


func _draw_report(sign: Control, i: int) -> void:
	if i >= Profile.reports.size():
		return
	var look: Array = REPORT_LOOK.get(Profile.reports[i]["kind"], ["?", Color.GRAY])
	var c := sign.size * 0.5
	var col: Color = look[1]
	sign.draw_circle(c + Vector2(0, 3), 16.0, Color(0, 0, 0, 0.45))
	if i == selected_report:
		sign.draw_circle(c, 19.0, Color(UiStyle.GOLD, 0.5))
	sign.draw_circle(c, 16.0, Color.WHITE)
	sign.draw_circle(c, 14.0, col)
	var font := ThemeDB.fallback_font
	sign.draw_string(font, Vector2(0, c.y + 7), look[0], HORIZONTAL_ALIGNMENT_CENTER, sign.size.x, 20, Color.WHITE)
	# A siege counts down the nights it still waits; the last one pulses.
	var rep: Dictionary = Profile.reports[i]
	if rep["kind"] == "defend":
		var left := Profile.REPORT_DEFEND_NIGHTS - int(rep["nights"])
		var b := c + Vector2(13, -13)
		var r := 7.5 + (1.5 * absf(sin(_t * 5.0)) if left <= 1 else 0.0)
		sign.draw_circle(b, r + 1.5, OUTLINE)
		sign.draw_circle(b, r, Color("ffd94a") if left <= 1 else Color.WHITE)
		sign.draw_string(font, b + Vector2(-8, 4), str(left), HORIZONTAL_ALIGNMENT_CENTER, 16, 11, Color("3a2600"))


func _add_pin(id: String) -> void:
	var pin := PanelContainer.new()
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.add_child(box)
	var title := UiStyle.label("", 15, UiStyle.TEXT)
	title.name = "Name"
	box.add_child(title)
	var stars := UiStyle.label("", 12, UiStyle.GOLD)
	stars.name = "Stars"
	box.add_child(stars)
	pin.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not _dragged:
			place_chosen.emit(id))
	_pins_layer.add_child(pin)
	_pins[id] = pin
	_style_pin(id)


func refresh() -> void:
	for id: String in _pins:
		_style_pin(id)


func _style_pin(id: String) -> void:
	var pin: PanelContainer = _pins[id]
	var state := place_state(id)
	var title: Label = pin.find_child("Name", true, false)
	var stars: Label = pin.find_child("Stars", true, false)
	var order := stage_order().find(id)
	title.text = place_name(id) if order < 0 else "%d · %s" % [order + 1, place_name(id)]
	var edge: Color = {"yours": Color("3f9a78"), "boss": Color("9a4a3a"), "locked": Color("55505e")}[state]
	title.label_settings.font_color = {"yours": Color("bff0dc"), "boss": Color("ffd0c4"), "locked": Color("c9c2d4")}[state]
	if state == "locked":
		stars.text = "🔒 " + tr("DISTRICT_SOON" if PLACES[id].get("future", false) else "DISTRICT_LOCKED")
		stars.label_settings.font_color = Color("b0a8c0")
		stars.label_settings.font_size = 11
	else:
		var n := place_stars(id)
		stars.text = "★".repeat(n) + "☆".repeat(3 - n)
		stars.label_settings.font_color = UiStyle.GOLD
		stars.label_settings.font_size = 12
	var sb := UiStyle.box(Color(0.1, 0.07, 0.13, 0.9), UiStyle.GOLD if id == selected else edge)
	sb.set_corner_radius_all(7)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 1
	sb.content_margin_bottom = 2
	if id == selected:
		sb.shadow_color = Color(UiStyle.GOLD, 0.45)
		sb.shadow_size = 8
	pin.add_theme_stylebox_override("panel", sb)
	pin.reset_size()
	var p: Vector2 = PLACES[id]["pos"] * px
	pin.position = Vector2(p.x - pin.size.x * 0.5, p.y + 38 - pin.size.y - 14)


func _draw_ring() -> void:
	if Settings.map_paths:
		_draw_paths()
		_draw_last_trip()
	_draw_residents()
	# The place under the mouse: its area outlined in gold.
	if _hover != "" and _hover != selected:
		var hr: Rect2 = PLACES[_hover]["view"]
		_ring.draw_rect(Rect2(hr.position * px, hr.size * px), Color(UiStyle.GOLD, 0.12))
		_ring.draw_rect(Rect2(hr.position * px, hr.size * px), Color(UiStyle.GOLD, 0.8), false, 2.0)
	if selected == "":
		return
	var sr: Rect2 = PLACES[selected]["view"]
	_ring.draw_rect(Rect2(sr.position * px, sr.size * px), Color(UiStyle.GOLD, 0.35 + 0.15 * sin(_t * 3.0)), false, 2.0)
	_draw_next()
	var p: Vector2 = PLACES[selected]["pos"] * px + Vector2(0, 60)
	var k := fmod(_t, 1.4) / 1.4
	_ring.draw_arc(p, 20.0 + k * 26.0, 0, TAU, 40, Color(UiStyle.GOLD, 1.0 - k), 3.0)
	# A little flag pole under the sign, in the owner's colour.
	for id: String in PLACES:
		var state := place_state(id)
		if state == "locked":
			continue
		var q: Vector2 = PLACES[id]["pos"] * px + Vector2(0, 24)
		_ring.draw_rect(Rect2(q, Vector2(2, 14)), Color("2a1c10"))
		var wave := sin(_t * 5.0 + q.x) * 1.5
		# Conquered maps fly a gold flag.
		var col := Color("f2c14e") if id in Profile.territories else (Color("3fbf8a") if state == "yours" else Color("d24a3a"))
		_ring.draw_colored_polygon(PackedVector2Array([q + Vector2(2, 0), q + Vector2(15, wave), q + Vector2(11, 4.5), q + Vector2(15, 9 + wave), q + Vector2(2, 9)]), col)


## The maps in the order they open (each one "requires" the one before).
static func stage_order() -> Array[String]:
	var order: Array[String] = []
	var left: Array = GameData.stages.keys()
	while not left.is_empty():
		var added := false
		for id: String in left.duplicate():
			var req: String = GameData.stages[id].get("requires", "")
			if req == "" or req in order:
				order.append(id)
				left.erase(id)
				added = true
		if not added:
			order.append_array(left)
			break
	return order


## The map to play next: the first open one you have not won yet.
static func next_place() -> String:
	for id in stage_order():
		if Profile.is_stage_unlocked(id) and id not in Profile.cleared_stages:
			return id
	return ""


## Where a path meets a place: just under its sign.
func _path_end(id: String) -> Vector2:
	return PLACES[id]["pos"] * px + Vector2(0, 46)


## A dotted path from `a` to `b` along a gentle curve. `march` makes the dots
## walk towards `b`.
func _draw_path(a: Vector2, b: Vector2, col: Color, march: bool, size: float = 2.6) -> void:
	var mid := (a + b) * 0.5 + (b - a).orthogonal().normalized() * minf(a.distance_to(b) * 0.12, 40.0)
	var length := a.distance_to(mid) + mid.distance_to(b)
	var step := 11.0
	var phase := fmod(_t * 18.0, step) if march else 0.0
	var d := phase
	while d < length:
		var k := d / length
		var p := a.lerp(mid, k).lerp(mid.lerp(b, k), k)
		_ring.draw_circle(p, size + 1.2, Color(OUTLINE, col.a))
		_ring.draw_circle(p, size, col)
		d += step


## The ways between the places: gold where you have been, marching dots to
## the next map, grey to locked ones, faint purple to the maps to come.
func _draw_paths() -> void:
	for link: Array in FUTURE_LINKS:
		_draw_path(_path_end(link[0]), _path_end(link[1]), Color(0.7, 0.6, 0.9, 0.45), false, 2.0)
	for id in stage_order():
		var req: String = GameData.stages[id].get("requires", "")
		if req == "" or not PLACES.has(req) or not PLACES.has(id):
			continue
		var col := Color(0.55, 0.52, 0.6, 0.6)
		var march := false
		if id in Profile.cleared_stages:
			col = Color(UiStyle.GOLD, 0.95)
		elif Profile.is_stage_unlocked(id):
			col = Color("fff0b0")
			march = true
		_draw_path(_path_end(req), _path_end(id), col, march)


## The residents at their spots, each with a sign: a coin when its service
## is for sale, a tick when bought; a kidnapped one leaves a red "?".
func _draw_residents() -> void:
	var font := ThemeDB.fallback_font
	for cat: String in RESIDENT_SPOTS:
		if not Profile.is_unlocked(cat):
			continue
		var at: Vector2 = RESIDENT_SPOTS[cat] * px
		var sign_at := at + Vector2(0, -15.0 * px * 0.5 - 14.0 - absf(sin(_t * 3.0 + at.x)) * 3.0)
		if cat == Profile.kidnapped:
			_ring.draw_circle(sign_at, 9.0, OUTLINE)
			_ring.draw_circle(sign_at, 7.5, Color("c0392b"))
			_ring.draw_string(font, sign_at + Vector2(-8, 5), "?", HORIZONTAL_ALIGNMENT_CENTER, 16, 13, Color.WHITE)
			continue
		var lk := CatArt.look(cat)
		CatArt.draw(_ring, lk, -1 if at.x > 400 else 1, _t * 2.0, false, false, "normal", at, px * 0.45, false)
		var bought := cat in Profile.services
		if bought:
			_ring.draw_circle(sign_at, 8.5, OUTLINE)
			_ring.draw_circle(sign_at, 7.0, Color("2f8a6a"))
			_ring.draw_string(font, sign_at + Vector2(-8, 5), "✓", HORIZONTAL_ALIGNMENT_CENTER, 16, 12, Color.WHITE)
		else:
			# A price tag: the service costs this much gold.
			var price := str(int(Profile.RESIDENTS[cat][1]))
			var w := font.get_string_size(price, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 16.0
			var tag := Rect2(sign_at - Vector2(w * 0.5, 8), Vector2(w, 16))
			_ring.draw_rect(tag.grow(1.5), OUTLINE)
			_ring.draw_rect(tag, UiStyle.GOLD)
			_ring.draw_circle(tag.position + Vector2(7, 8), 4.0, Color("c98a10"))
			_ring.draw_circle(tag.position + Vector2(7, 8), 2.5, Color("ffe27a"))
			_ring.draw_string(font, tag.position + Vector2(12, 12), price, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("3a2600"))
		if cat == _hover_cat:
			# What the resident offers, right there under the mouse.
			var text := tr("CAT_%s_NAME" % cat) + ": " + tr("RESIDENT_%s_SERVICE" % cat)
			var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var box := Rect2(sign_at + Vector2(-tw * 0.5 - 6, -32), Vector2(tw + 12, 18))
			_ring.draw_rect(box, Color(OUTLINE, 0.92))
			_ring.draw_rect(box, Color("3f7a5a"), false, 1.5)
			_ring.draw_string(font, box.position + Vector2(6, 13), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d6f5c4"))


## The way your last night trip went, in cyan.
func _draw_last_trip() -> void:
	var route := Profile.last_trip
	for i in range(1, route.size()):
		if PLACES.has(route[i - 1]) and PLACES.has(route[i]):
			_draw_path(_path_end(route[i - 1]) + Vector2(6, 6), _path_end(route[i]) + Vector2(6, 6), Color(0.4, 0.9, 1.0, 0.85), false, 2.0)


## A bouncing "next" arrow over the map to play next.
func _draw_next() -> void:
	var id := next_place()
	if id == "" or not _pins.has(id):
		return
	var pin: Control = _pins[id]
	var tip := Vector2(pin.position.x + pin.size.x * 0.5, pin.position.y - 6.0 - absf(sin(_t * 4.0)) * 6.0)
	var tri := PackedVector2Array([tip, tip + Vector2(-9, -12), tip + Vector2(9, -12)])
	_ring.draw_colored_polygon(PackedVector2Array([tri[0] + Vector2(0, 2), tri[1] + Vector2(-2, -1), tri[2] + Vector2(2, -1)]), OUTLINE)
	_ring.draw_colored_polygon(tri, UiStyle.GOLD)
	var font := ThemeDB.fallback_font
	var text := tr("DISTRICT_NEXT")
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var box := Rect2(tip + Vector2(-w * 0.5 - 6, -32), Vector2(w + 12, 18))
	_ring.draw_rect(box, Color(OUTLINE, 0.9))
	_ring.draw_rect(box, UiStyle.GOLD, false, 1.5)
	_ring.draw_string(font, box.position + Vector2(6, 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiStyle.GOLD)


## "yours" (won there), "boss" (open but not won yet) or "locked".
static func place_state(id: String) -> String:
	if not GameData.stages.has(id) or not Profile.is_stage_unlocked(id):
		return "locked"
	return "yours" if id in Profile.cleared_stages else "boss"


static func place_name(id: String) -> String:
	if GameData.stages.has(id):
		return TranslationServer.translate("STAGE_%s_NAME" % id) if Profile.is_stage_unlocked(id) or id in PLACES else "???"
	return TranslationServer.translate("DISTRICT_%s_NAME" % id)


## Stars: a win there, a win in the dark, and every story of the map done.
static func place_stars(id: String) -> int:
	if not GameData.stages.has(id):
		return 0
	var n := 0
	if id in Profile.cleared_stages:
		n += 1
	if int(Profile.darkness_best.get(id, 0)) > 0:
		n += 1
	var stories := place_stories(id)
	if stories.y > 0 and stories.x >= stories.y:
		n += 1
	return n


## A cat's home bonus as text ("+15 % damage").
static func home_text(cat_id: String) -> String:
	return stats_text(GameData.cats[cat_id].get("home_bonus", {}))


## Stat bonuses as text ("+15 % damage, +10 health").
static func stats_text(bonus: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in bonus:
		if HOME_STATS.has(key):
			var v := float(bonus[key]) * float(HOME_STATS[key][1])
			var shown := str(roundi(v)) if absf(v - roundf(v)) < 0.01 else ("%.1f" % v).replace(".", TranslationServer.translate("DECIMAL_SEP"))
			parts.append(TranslationServer.translate(HOME_STATS[key][0]) % shown)
	return ", ".join(parts)


## Stories of a map: (done, all).
static func place_stories(id: String) -> Vector2i:
	var done := 0
	var all := 0
	for cid: String in GameData.chains:
		if GameData.chains[cid].get("stage", "any") != id or GameData.chains[cid].has("secret"):
			continue
		all += 1
		if ChainStep.progress_of(cid) >= ChainStep.steps(cid).size():
			done += 1
	return Vector2i(done, all)


# --- the moving bits ------------------------------------------------------------

func _draw_anim(c: Control) -> void:
	var t := _t
	for p in _water:
		var v := sin(p.x * 0.3 + p.y * 0.5 + t * 2.2) + sin(p.x * 0.07 - t * 1.3)
		if v > 1.55:
			c.draw_rect(Rect2(p, Vector2(2, 1)), Color("8cc8ec"))
		elif v < -1.6:
			c.draw_rect(Rect2(p, Vector2(3, 1)), Color("1e5078"))
	for y in range(140, int(SEA_B), 3):
		if sin(t * 3.0 + y * 0.7) > 0.2:
			c.draw_rect(Rect2(floorf(_shore(y) + 2.0 + sin(t * 2.0 + y) * 1.2), y, 2, 1), Color("d8f0ff"))
	# The fishing boat rocks by the pier, with a wake behind it.
	var b := Vector2(404 + sin(t * 0.4) * 3.0, 200 + sin(t * 1.6) * 1.5).round()
	c.draw_rect(Rect2(b + Vector2(-13, 5), Vector2(28, 3)), Color(0, 0, 0, 0.25))
	c.draw_rect(Rect2(b + Vector2(-14, 0), Vector2(28, 6)), Color("3a2410"))
	c.draw_rect(Rect2(b + Vector2(-13, 0), Vector2(26, 4)), Color("8a4a2a"))
	c.draw_rect(Rect2(b + Vector2(-13, 0), Vector2(26, 1)), Color("e8e4dc"))
	c.draw_rect(Rect2(b + Vector2(-4, -7), Vector2(9, 7)), Color("e8e4dc"))
	c.draw_rect(Rect2(b + Vector2(8, -14), Vector2(1, 14)), Color("3a2410"))
	c.draw_rect(Rect2(b + Vector2(9, -14), Vector2(5, 3)), Color("c0392b"))
	for i in 3:
		c.draw_rect(Rect2(b + Vector2(-18 - i * 6, 3 + sin(t * 2.0 + i)), Vector2(3, 1)), Color(0.86, 0.94, 1, 0.5 - i * 0.15))
	# The night train.
	var tx := _train_x()
	for k in 4:
		var x := tx - k * 30
		if x < -30 or x > WW:
			continue
		c.draw_rect(Rect2(x, 262, 28, 10), Color("1a1a20"))
		c.draw_rect(Rect2(x + 1, 263, 26, 8), Color("c0392b") if k == 0 else Color("2a5a8a"))
		c.draw_rect(Rect2(x + 1, 263, 26, 1), Color("e8e4dc"))
	# Neighbours out for a stroll, and gulls over the harbour.
	for i in 4:
		var walk: Array = [[0.0, 115.0, 1, Color("d98c4a")], [300.0, 133.0, -1, Color("e8e0cc")], [500.0, 133.0, 1, Color("2a2830")], [203.0, 40.0, 0, Color("8a7a6a")]][i]
		var pos := Vector2(fposmod(float(walk[0]) + t * 9.0 * walk[2], WW), walk[1]) if walk[2] != 0 else Vector2(walk[0], 20.0 + pingpong(t * 7.0, 88.0))
		_mini_cat(c, pos.round(), walk[3], t)
	for i in 3:
		var g := Vector2(330 + i * 35 + sin(t * 0.5 + i * 2) * 40, 150 + i * 6 + cos(t * 0.4 + i * 2) * 14).round()
		var f := int(t * 6 + i * 2) % 2
		c.draw_rect(Rect2(g, Vector2(1, 1)), Color("f4f4f4"))
		c.draw_rect(Rect2(g + Vector2(-2, -f), Vector2(2, 1)), Color("f4f4f4"))
		c.draw_rect(Rect2(g + Vector2(1, -f), Vector2(2, 1)), Color("f4f4f4"))
	# Cloud shadows drifting over the town.
	for i in 4:
		var cc := Vector2(fposmod(t * 6.0 + i * 230.0, WW + 200.0) - 100.0, 40.0 + i * 70.0)
		c.draw_texture_rect(_glow, Rect2(cc - Vector2(60, 60), Vector2(120, 120)), false, Color(0.04, 0.04, 0.12, 0.22))


func _mini_cat(c: Control, p: Vector2, col: Color, t: float) -> void:
	c.draw_rect(Rect2(p + Vector2(-1, 2), Vector2(6, 1)), Color(0, 0, 0, 0.33))
	c.draw_rect(Rect2(p, Vector2(5, 2)), col)
	c.draw_rect(Rect2(p + Vector2(4, -1), Vector2(2, 2)), col)
	c.draw_rect(Rect2(p + Vector2(-1, -1), Vector2(1, 2)), col)
	var s := int(t * 8.0) % 2
	c.draw_rect(Rect2(p + Vector2(s, 2), Vector2(1, 1)), OUTLINE)
	c.draw_rect(Rect2(p + Vector2(3 + s, 2), Vector2(1, 1)), OUTLINE)


func _train_x() -> float:
	return fmod(_t, 18.0) / 18.0 * (WW + 260.0) - 130.0


func _draw_windows(c: Control) -> void:
	for w: Array in _lit:
		var r: Rect2 = w[0]
		var kind: String = w[1]
		if kind == "tv":
			var f := sin(_t * 13.0 + r.position.x) * 0.5 + sin(_t * 7.3 + r.position.y) * 0.5
			c.draw_rect(r, Color("a8d0ff") if f > 0.3 else (Color("7aa0e8") if f > -0.3 else Color("c8e0ff")))
		elif kind == "shop":
			c.draw_rect(r, Color("bfe8ff"))
			c.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color("e8f8ff"))
			if r.size.y > 8:
				for s in 3:
					c.draw_rect(Rect2(r.position + Vector2(1, 5 + s * 3), Vector2(r.size.x - 2, 1)), [Color("e8524a"), Color("f2c14e"), Color("7cc455")][s])
		else:
			c.draw_rect(r, Color("f7c25a"))
			c.draw_rect(Rect2(r.position, Vector2(r.size.x, maxf(1, floorf(r.size.y / 3.0)))), Color("ffe7a0"))
			if r.size.x > 5 and r.size.y > 5:
				c.draw_rect(Rect2(r.position + Vector2(floorf(r.size.x / 2), 0), Vector2(1, r.size.y)), Color("8a5a2a"))
				c.draw_rect(Rect2(r.position + Vector2(0, floorf(r.size.y / 2)), Vector2(r.size.x, 1)), Color("8a5a2a"))
	var tx := _train_x()
	for k in 4:
		var x := tx - k * 30
		if x > -30 and x < WW:
			for i in 4:
				c.draw_rect(Rect2(x + 3 + i * 6, 265, 4, 3), Color("ffd977"))
	# The supermarket's neon sign flickers now and then.
	var on := sin(_t * 6.0) > -0.85
	c.draw_rect(Rect2(236, 147, 46, 8), Color("2a1012"))
	for i in 6:
		c.draw_rect(Rect2(239 + i * 7, 149, 5, 4), Color("ff7a6a") if on else Color("6a2a24"))
	if sin(_t * 3.0) > 0.4:
		c.draw_rect(Rect2(292, -2, 1, 2), Color("ff4a3a"))


func _glow_at(c: Control, p: Vector2, r: Vector2, col: Color) -> void:
	c.draw_texture_rect(_glow, Rect2(p - r, r * 2.0), false, col)


func _draw_lights(c: Control) -> void:
	for p in _lamps:
		_glow_at(c, p, Vector2(5, 5), Color(1, 0.88, 0.63, 0.6))
		_glow_at(c, p + Vector2(0, 11), Vector2(14, 7), Color(1, 0.67, 0.31, 0.24))
		if _is_water(int(p.x), int(p.y + 14)):
			for k in 4:
				c.draw_rect(Rect2(p.x - 1 + sin(_t * 4.0 + k) * 2.0, p.y + 14 + k * 3, 3, 1), Color(1, 0.78, 0.43, 0.35 - k * 0.07))
	for p in _candles:
		_glow_at(c, p, Vector2(5, 5), Color(1, 0.67, 0.24, 0.5 + sin(_t * 11.0 + p.x) * 0.15))
	for w: Array in _lit:
		var r: Rect2 = w[0]
		var col := Color(0.47, 0.67, 1.0, 0.14) if w[1] == "tv" else (Color(0.55, 0.82, 1.0, 0.14) if w[1] == "shop" else Color(1.0, 0.63, 0.24, 0.14))
		_glow_at(c, r.get_center(), Vector2.ONE * maxf(r.size.x, r.size.y) * 0.9, col)
		if r.size.y >= 8:
			_glow_at(c, Vector2(r.get_center().x, r.end.y + 6), Vector2(r.size.x * 0.8, 4), Color(1, 0.67, 0.31, 0.12))
	var on := 1.0 if sin(_t * 6.0) > -0.85 else 0.25
	_glow_at(c, Vector2(259, 151), Vector2(30, 30), Color(1, 0.31, 0.24, 0.35 * on))
	# The lighthouse sweeps the bay.
	var a := _t * 0.9
	var o := Vector2(423, 124)
	c.draw_colored_polygon(PackedVector2Array([o, o + Vector2.from_angle(a - 0.18) * 150.0, o + Vector2.from_angle(a + 0.18) * 150.0]), Color(1, 0.94, 0.67, 0.14))
	_glow_at(c, o, Vector2(12, 12), Color(1, 0.94, 0.67, 0.85))
	if sin(_t * 3.0) > 0.4:
		_glow_at(c, Vector2(292, 2), Vector2(6, 6), Color(1, 0.24, 0.16, 0.9))
	var tx := _train_x()
	if tx > -30 and tx < WW + 30:
		_glow_at(c, Vector2(tx + 40, 267), Vector2(26, 8), Color(1, 0.94, 0.7, 0.45))
	for i in 26:
		var park := i % 2 == 1
		var base := Vector2(460 + fmod(i * 47.3, 120.0), 14 + fmod(i * 31.7, 90.0)) if park else Vector2(20 + fmod(i * 53.1, 150.0), 14 + fmod(i * 29.3, 86.0))
		var f := base + Vector2(sin(_t * 0.7 + i) * 6.0, cos(_t * 0.9 + i * 2.0) * 4.0)
		var on2 := maxf(0.0, sin(_t * 2.0 + i * 3.0))
		c.draw_rect(Rect2(f.round(), Vector2.ONE), Color(0.9, 1, 0.47, on2))
		_glow_at(c, f, Vector2(4, 4), Color(0.78, 1, 0.39, on2 * 0.35))


func _draw_fx(c: Control) -> void:
	for s: Array in [[Vector2(124, 136), 0], [Vector2(425, 2), 1], [Vector2(425, 2), 2], [Vector2(90, 154), 3]]:
		for i in 6:
			var p := fmod(_t * 0.35 + i / 6.0 + s[1] * 0.17, 1.0)
			var at: Vector2 = s[0] + Vector2(p * 14.0 + sin(_t + i) * 2.0, -p * 26.0)
			c.draw_circle(at, 2.0 + p * 5.0, Color(0.7, 0.7, 0.78, 0.45 * (1.0 - p)))
	for id: String in FOG:
		if place_state(id) != "locked":
			continue
		var r: Rect2 = FOG[id]
		c.draw_texture_rect(_glow, r.grow(16), false, Color(0.59, 0.56, 0.69, 0.55))
		for puff: Array in _puffs[id]:
			var at: Vector2 = puff[0] + Vector2(sin(_t * 0.3 + puff[2]) * 8.0, cos(_t * 0.25 + puff[2]) * 4.0)
			_glow_at(c, at, Vector2.ONE * puff[1], Color(0.77, 0.74, 0.84, 0.4))


func _draw_mini() -> void:
	var r := Rect2(Vector2.ZERO, _mini.size)
	_mini.draw_rect(r.grow(4), Color(0.08, 0.06, 0.11, 0.9))
	_mini.draw_texture_rect(_texture, r, false, Color(0.55, 0.6, 0.9))
	for id: String in PLACES:
		var col: Color = {"yours": Color("5fe0a8"), "boss": Color("ff6a5a"), "locked": Color("9a92a8")}[place_state(id)]
		_mini.draw_rect(Rect2(PLACES[id]["pos"] / Vector2(WW, WH) * _mini.size - Vector2(2, 2), Vector2(4, 4)), col)
	var v := view_size()
	_mini.draw_rect(Rect2(cam / Vector2(WW, WH) * _mini.size, v / Vector2(WW, WH) * _mini.size), UiStyle.GOLD, false, 2.0)
	_mini.draw_rect(r.grow(4), Color("5a4a6e"), false, 2.0)


# --- building the town (once) -------------------------------------------------------

static var _img: Image
static var _rng := RandomNumberGenerator.new()


static func _shore(y: float) -> float:
	return 332.0 - (y - 138.0) * 0.8 + 5.0 * sin(y / 8.0)


static func _on_island(x: float, y: float) -> bool:
	return pow((x - 620.0) / 40.0, 2) + pow((y - 205.0) / 24.0, 2) < 1.0


static func _is_water(x: float, y: float) -> bool:
	return y > 138.0 and y < SEA_B + sin(x / 11.0) * 1.5 and x > _shore(y) and not _on_island(x, y)


static func R(x: float, y: float, w: float, h: float, c: Variant) -> void:
	var r := Rect2i(int(x), int(y), int(w), int(h)).intersection(Rect2i(0, 0, WW, WH))
	if r.size.x > 0 and r.size.y > 0:
		_img.fill_rect(r, c if c is Color else Color(c))


static func P(x: float, y: float, c: Variant) -> void:
	var xi := int(x)
	var yi := int(y)
	if xi >= 0 and yi >= 0 and xi < WW and yi < WH:
		_img.set_pixel(xi, yi, c if c is Color else Color(c))


## Darkens a block (soft shadows under buildings and trees).
static func dim(x: float, y: float, w: float, h: float, k: float) -> void:
	for yy in range(int(y), int(y + h)):
		for xx in range(int(x), int(x + w)):
			if xx >= 0 and yy >= 0 and xx < WW and yy < WH:
				_img.set_pixel(xx, yy, _img.get_pixel(xx, yy).darkened(k))


static func ellipse(cx: float, cy: float, rx: float, ry: float, c: Variant) -> void:
	for y in range(int(cy - ry), int(cy + ry) + 1):
		for x in range(int(cx - rx), int(cx + rx) + 1):
			if pow((x + 0.5 - cx) / rx, 2) + pow((y + 0.5 - cy) / ry, 2) <= 1.0:
				P(x, y, c)


static func dim_ellipse(cx: float, cy: float, rx: float, ry: float, k: float) -> void:
	for y in range(int(cy - ry), int(cy + ry) + 1):
		for x in range(int(cx - rx), int(cx + rx) + 1):
			if x >= 0 and y >= 0 and x < WW and y < WH and pow((x + 0.5 - cx) / rx, 2) + pow((y + 0.5 - cy) / ry, 2) <= 1.0:
				_img.set_pixel(x, y, _img.get_pixel(x, y).darkened(k))


static func _build_town() -> void:
	_img = Image.create(WW, WH, false, Image.FORMAT_RGBA8)
	_rng.seed = 7
	_lamps.clear()
	_candles.clear()
	_lit.clear()
	_ground()
	_roads()
	_railway()
	_garden()
	_house()
	_tower()
	_market()
	_harbor()
	_factory()
	_park()
	_cemetery()
	_island()
	_station()
	_scatter()
	_image = _img


static func _ground() -> void:
	var g := [Color("5c9443"), Color("558b3d"), Color("62a04a"), Color("4f8239")]
	for y in WH:
		for x in WW:
			if _is_water(x, y):
				var d := minf(minf(x - _shore(y), SEA_B - y), sqrt(pow(x - 620.0, 2) / 1.6 + pow(y - 205.0, 2) * 1.6) - 26.0)
				var c := "3d90c0" if d < 5 else ("3884b4" if (x * 3 + y) % 11 == 0 else "2e729e") if d < 16 else ("2a6a96" if (x + y * 5) % 13 == 0 else "245a86")
				_img.set_pixel(x, y, Color(c))
				continue
			if _is_water(x + 4, y) or _is_water(x, y - 4) or _is_water(x + 3, y - 3) or _is_water(x - 4, y) or _is_water(x, y + 4):
				_img.set_pixel(x, y, Color("c9ad78") if (x * 7 + y * 3) % 5 == 0 else Color("dcc48c"))
				continue
			var n := sin(x * 0.21 + y * 0.13) + sin(x * 0.05 - y * 0.11) * 1.5 + _rng.randf() * 1.2
			_img.set_pixel(x, y, g[2] if n > 1.6 else (g[0] if n > 0.2 else (g[1] if n > -1.0 else g[3])))
	for i in 900:
		var x := _rng.randi_range(0, WW - 1)
		var y := _rng.randi_range(0, WH - 2)
		if not _is_water(x, y):
			P(x, y, "78b85a")
			P(x, y + 1, "4a7a34")
	for i in 40:
		var x := _rng.randi_range(0, WW - 1)
		var y := _rng.randi_range(0, WH - 1)
		if not _is_water(x, y):
			P(x, y, ["f2e86a", "f0f0f0", "e8a0d0"][i % 3])


static func _car(x: float, y: float, c: String, vert: bool = false) -> void:
	if vert:
		R(x, y, 7, 12, "1a1a20"); R(x + 1, y + 1, 5, 10, c); R(x + 1, y + 3, 5, 3, "9fc8e8")
	else:
		R(x, y, 12, 7, "1a1a20"); R(x + 1, y + 1, 10, 5, c); R(x + 3, y + 1, 3, 5, "9fc8e8")


static func _roads() -> void:
	R(0, 116, WW, 16, "a49c8e"); R(0, 118, WW, 12, "45434d"); R(0, 118, WW, 1, "5a5864"); R(0, 129, WW, 1, "5a5864"); R(0, 131, WW, 1, "7a7468")
	for x in range(2, WW, 10):
		if x < 186 or x > 210:
			R(x, 123, 5, 1, "e8cf6a")
	R(194, 0, 16, 258, "a49c8e"); R(196, 0, 12, 258, "45434d"); R(196, 0, 1, 258, "5a5864"); R(207, 0, 1, 258, "5a5864")
	for y in range(2, 256, 10):
		if y < 110 or y > 140:
			R(201, y, 1, 5, "e8cf6a")
	R(196, 116, 12, 16, "45434d")
	R(590, 0, 16, 118, "a49c8e"); R(592, 0, 12, 118, "45434d"); R(592, 0, 1, 118, "5a5864"); R(603, 0, 1, 118, "5a5864")
	for y in range(2, 110, 10):
		R(597, y, 1, 5, "e8cf6a")
	R(592, 116, 12, 4, "45434d")
	R(210, 60, 112, 10, "a49c8e"); R(210, 61, 112, 8, "45434d")
	for i in 5000:
		var x := _rng.randi_range(0, WW - 1)
		var y := _rng.randi_range(0, WH - 1)
		if (y > 118 and y < 130) or (x > 196 and x < 208 and y < 258) or (x > 592 and x < 604 and y < 118):
			P(x, y, "4c4a55" if _rng.randf() < 0.5 else "3e3c46")
	for x in range(186, 195, 2):
		R(x, 119, 1, 10, "dcd8d0")
	for x in range(209, 218, 2):
		R(x, 119, 1, 10, "dcd8d0")
	for y in range(106, 115, 2):
		R(197, y, 10, 1, "dcd8d0")
	for y in range(133, 142, 2):
		R(197, y, 10, 1, "dcd8d0")
	for m: Vector2 in [Vector2(150, 124), Vector2(300, 121), Vector2(202, 80), Vector2(450, 125), Vector2(598, 60)]:
		R(m.x - 2, m.y - 1, 5, 3, "2e2c34"); R(m.x - 1, m.y - 2, 3, 5, "2e2c34"); P(m.x, m.y, "55535e")
	_car(30, 119, "c0392b"); _car(330, 124, "3a6ac8"); _car(480, 119, "e0a020"); _car(198, 180, "2f8a6a", true); _car(198, 30, "d8d8d8", true); _car(650, 124, "8a3ab0")


static func _railway() -> void:
	var y := 262
	for x in WW:
		for yy in range(y - 3, y + 13):
			if not _is_water(x, yy):
				P(x, yy, "6a6258" if (x * 7 + yy * 13) % 5 == 0 else ("8a8276" if (x + yy) % 3 == 0 else "7a7268"))
	for x in range(0, WW, 4):
		R(x, y, 2, 10, "5a3a24")
	R(0, y + 2, WW, 1, "b8b8c0"); R(0, y + 3, WW, 1, "6a6a72"); R(0, y + 7, WW, 1, "b8b8c0"); R(0, y + 8, WW, 1, "6a6a72")
	R(196, y - 3, 12, 16, "6a5038")
	for x in range(196, 208, 2):
		R(x, y - 3, 1, 16, "5a4028")
	R(196, y + 2, 12, 1, "b8b8c0"); R(196, y + 7, 12, 1, "b8b8c0")
	for bx: int in [190, 212]:
		R(bx, y - 8, 2, 8, "e8e4dc"); R(bx - 1, y - 10, 4, 3, "c0392b")


static func _tree(x: float, y: float, r: int, c1: String = "2f6e2c", c2: String = "3f8a37", c3: String = "5aa84a") -> void:
	dim_ellipse(x + 3, y + r * 0.75, r * 1.05, r * 0.5, 0.3)
	R(x - 1, y + r * 0.3, 3, r * 0.6, "5a3a20")
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var d := dx * dx + dy * dy
			if d > r * r:
				continue
			var l := float(-dx - dy) / r + _rng.randf() * 0.6
			P(x + dx, y + dy, "1f4a1e" if d > (r - 1) * (r - 1) else (c3 if l > 0.9 else (c2 if l > -0.3 else c1)))
	P(x - r * 0.4, y - r * 0.5, "7ac860")


static func _pine(x: float, y: float, h: int) -> void:
	dim_ellipse(x + 3, y + 2, 5, 2, 0.3)
	for i in h:
		var wd := maxi(1, int(float(i) / h * 6))
		R(x - wd, y - h + i, wd * 2 + 1, 1, "1f4a2e" if i % 3 == 0 else "2a5e3a")
	R(x, y, 1, 2, "5a3a20")


static func _dead_tree(x: float, y: float) -> void:
	R(x, y - 12, 2, 12, "3a3036"); R(x - 4, y - 10, 4, 1, "3a3036"); R(x + 2, y - 8, 4, 1, "3a3036"); R(x - 5, y - 12, 1, 2, "3a3036"); R(x + 5, y - 10, 1, 2, "3a3036")


static func _bush(x: float, y: float) -> void:
	_tree(x, y, 3, "2a5e28", "3a7a32", "4e9a40")


static func _lamp(x: float, y: float) -> void:
	R(x, y - 9, 1, 9, "2a2a30"); R(x - 1, y - 10, 3, 2, "ffe7a0"); R(x - 1, y, 3, 1, "2a2a30")
	_lamps.append(Vector2(x, y - 9))


static func _bench(x: float, y: float) -> void:
	R(x, y, 9, 2, "8a5a34"); R(x, y - 2, 9, 1, "6a4428"); R(x + 1, y + 2, 1, 2, "3a2a20"); R(x + 7, y + 2, 1, 2, "3a2a20")


static func _window(x: float, y: float, w: float, h: float, on: bool = true, kind: String = "") -> void:
	R(x - 1, y - 1, w + 2, h + 2, "3a2a20")
	R(x, y, w, h, "ffd977" if on else "2a3448")
	if on:
		_lit.append([Rect2(x, y, w, h), kind])
	else:
		R(x, y, w, 1, "3a4a68"); P(x + 1, y + 1, "4a5a78")


static func _ao(x: float, y: float, w: float) -> void:
	dim(x, y, w, 2, 0.28)
	dim(x, y + 2, w, 2, 0.14)


static func _house() -> void:
	var x := 36.0
	var y := 146.0
	var w := 108.0
	dim(x + 5, y + 8, w, 80, 0.27)
	R(x - 2, y + 34, w + 4, 40, "2e2018"); R(x, y + 34, w, 38, "e0b07c")
	for i in range(0, int(w), 6):
		R(x + i, y + 34, 1, 38, "d29e6a")
	R(x, y + 34, w, 2, "b8865a")
	R(x - 4, y, w + 8, 36, "2e1a14")
	for r in 34:
		R(x - 3, y + 1 + r, w + 6, 1, ("8e3a28" if r % 4 == 0 else "b44a32") if r < 16 else ("7a3022" if r % 4 == 0 else "9a3e2a"))
	for r in range(2, 34, 4):
		for i in range(0 if r % 8 else 5, int(w) + 6, 10):
			R(x - 3 + i, y + 1 + r, 1, 3, "6a2618")
	R(x - 3, y + 16, w + 6, 2, "5a2016"); R(x - 3, y + 1, w + 6, 1, "c85a3e"); R(x - 4, y + 35, w + 8, 1, "6a6a72")
	R(x + 84, y - 8, 10, 14, "2e1a14"); R(x + 85, y - 7, 8, 13, "8a5a48"); R(x + 84, y - 9, 10, 2, "5a3a2a")
	R(x + 20, y + 4, 12, 10, "2e1a14"); R(x + 21, y + 5, 10, 8, "b44a32"); _window(x + 23, y + 7, 6, 5)
	_window(x + 10, y + 42, 14, 12); _window(x + 34, y + 42, 14, 12, true, "tv"); _window(x + 76, y + 42, 14, 12)
	for wx: float in [x + 9, x + 75]:
		R(wx, y + 55, 16, 3, "7a4a2a")
		for k in 4:
			P(wx + 2 + k * 4, y + 54, ["e8524a", "f2c14e", "e070c0", "e8524a"][k])
	R(x + 56, y + 44, 16, 28, "3a2216"); R(x + 57, y + 45, 14, 27, "7a4a2a"); R(x + 58, y + 46, 12, 12, "8a5a34"); P(x + 68, y + 58, "f2c14e")
	R(x + 54, y + 72, 20, 4, "9a948a")
	_lamps.append(Vector2(x + 52, y + 48)); R(x + 51, y + 47, 2, 3, "ffe7a0")
	R(x - 2, y + 72, w + 4, 12, "2a2a2e"); R(x, y + 73, w, 10, "7a7a80")
	for i in range(0, int(w), 8):
		R(x + i, y + 73, 1, 10, "68686e")
	R(x + 12, y + 75, 14, 6, "1a1a1e")
	for i in range(0, 14, 3):
		R(x + 12 + i, y + 75, 1, 6, "5a5a60")
	R(x + 90, y + 74, 14, 10, "4a4a50")
	for s in 4:
		R(x + 90, y + 74 + s * 2, 14 - s * 2, 1, "8a8a90")
	_ao(x, y + 84, w)
	R(x + 62, y + 84, 4, 32, "a49c8e")
	R(x + 20, y + 90, 2, 6, "5a3a20"); R(x + 18, y + 86, 6, 5, "3a5a9a"); P(x + 19, y + 87, "e8e4dc")
	for i in range(-6, int(w) + 10, 5):
		R(x + i, y + 96, 1, 5, "d8cbb0")
	R(x - 6, y + 97, w + 16, 1, "c8bba0")
	R(x + 30, y + 88, 3, 3, "e24b4a"); P(x + 31, y + 87, "f4f4f4")
	_lamp(x + 80, y + 100)


static func _garden() -> void:
	var x := 10.0
	var y := 8.0
	var w := 172.0
	var h := 98.0
	R(x, y, w, h, "5fa046")
	for i in 1600:
		P(x + _rng.randf() * w, y + _rng.randf() * h, "6cb050" if _rng.randf() < 0.5 else "54913f")
	for i in 60:
		var t := i / 60.0
		P(x + 20 + t * 70, y + 90 - sin(t * 3) * 20, "c8b48a"); P(x + 21 + t * 70, y + 90 - sin(t * 3) * 20, "d8c49a")
	for i in range(0, int(w), 4):
		R(x + i, y, 2, 4, "a07a4a"); R(x + i, y + h - 4, 2, 4, "a07a4a")
	R(x, y + 1, w, 1, "7a5a34"); R(x, y + h - 3, w, 1, "7a5a34")
	for i in range(0, int(h), 4):
		R(x, y + i, 2, 3, "a07a4a"); R(x + w - 2, y + i, 2, 3, "a07a4a")
	for r in 3:
		R(x + 96, y + 50 + r * 12, 56, 8, "6a4428"); R(x + 96, y + 50 + r * 12, 56, 1, "4a2c18")
		for i in range(0, 56, 4):
			P(x + 97 + i, y + 52 + r * 12, ["e8524a", "f2c14e", "e070c0", "fff0f0"][(i / 4 + r) % 4])
			P(x + 99 + i, y + 55 + r * 12, "3f8a37"); P(x + 98 + i, y + 51 + r * 12, "3f8a37")
	ellipse(x + 46, y + 64, 22, 13, "2e5e3a"); ellipse(x + 46, y + 64, 21, 12, "8a8a8a"); ellipse(x + 46, y + 64, 19, 10, "2f6f9a"); ellipse(x + 42, y + 61, 11, 4, "4a92bc")
	R(x + 38, y + 62, 4, 2, "5aa84a"); R(x + 52, y + 67, 4, 2, "5aa84a"); P(x + 39, y + 61, "f0a0c0"); P(x + 53, y + 66, "ffffff")
	R(x + 126, y + 10, 30, 6, "5a2c1e")
	for i in 6:
		R(x + 126, y + 10 + i, 30, 1, "7a3a26" if i % 2 else "8e4630")
	R(x + 128, y + 16, 26, 16, "b08a5a")
	for i in range(0, 26, 3):
		R(x + 128 + i, y + 16, 1, 16, "9a764a")
	R(x + 136, y + 22, 8, 10, "5a3a20"); _window(x + 147, y + 20, 5, 5); _ao(x + 128, y + 32, 26)
	_tree(x + 18, y + 20, 9); _tree(x + 40, y + 16, 7); _tree(x + 84, y + 26, 10); _tree(x + 70, y + 84, 6); _tree(x + 160, y + 84, 7)
	_bush(x + 110, y + 20); _bush(x + 12, y + 88); _bush(x + 28, y + 90); _bench(x + 60, y + 40)
	R(x + 90, y + 70, 8, 3, "8a8a8a"); R(x + 150, y + 42, 4, 5, "c0392b"); P(x + 151, y + 41, "f4f4f4")


static func _tower() -> void:
	var x := 222.0
	var y := 4.0
	var w := 80.0
	dim(x + 6, y + 8, w, 104, 0.3)
	R(x - 1, y, w + 2, 26, "3a3a40"); R(x, y + 1, w, 24, "8a8a92")
	for i in 300:
		P(x + _rng.randf() * w, y + 1 + _rng.randf() * 24, "7e7e86" if _rng.randf() < 0.5 else "9696a0")
	R(x, y + 1, w, 1, "a8a8b0"); R(x, y + 24, w, 2, "6a6a72")
	R(x + 8, y + 5, 12, 10, "5a5a62"); R(x + 9, y + 6, 10, 8, "a0a0aa"); R(x + 10, y + 2, 8, 4, "6a6a72"); R(x + 11, y + 15, 1, 4, "3a3a40"); R(x + 16, y + 15, 1, 4, "3a3a40")
	R(x + 50, y + 6, 8, 6, "c8c8d0"); R(x + 60, y + 6, 8, 6, "c8c8d0"); R(x + 51, y + 7, 6, 1, "7a7a82"); R(x + 61, y + 7, 6, 1, "7a7a82")
	R(x + 70, y - 6, 1, 14, "2a2a30"); R(x + 68, y - 2, 5, 1, "2a2a30")
	R(x + 30, y + 12, 14, 8, "5a4a40"); R(x + 31, y + 13, 12, 6, "7a6a5a")
	for i in 5:
		P(x + 24 + i * 4, y + 20, "e8e4dc")
	R(x - 1, y + 26, w + 2, 82, "3a1e18"); R(x, y + 26, w, 80, "9a4a36")
	for r in range(0, 80, 3):
		for i in range(0 if r % 6 else 3, int(w), 6):
			R(x + i, y + 26 + r, 1, 3, "7e3a2a")
		R(x, y + 26 + r, w, 1, "a85a44")
	R(x + w - 4, y + 26, 4, 80, "7a3626")
	for fy in 5:
		for fx in 5:
			var on := ((fx * 7 + fy * 3) % 5) < 2
			_window(x + 5 + fx * 15, y + 32 + fy * 14, 8, 8, on, "tv" if on and (fx + fy) % 4 == 1 else "")
		R(x + 2, y + 41 + fy * 14, w - 4, 1, "3a2a2a")
		for i in range(0, int(w) - 4, 3):
			P(x + 3 + i, y + 40 + fy * 14, "5a4a4a")
	R(x + 32, y + 96, 16, 10, "3a2216"); R(x + 33, y + 97, 14, 9, "5a5a6a"); _lit.append([Rect2(x + 33, y + 97, 14, 3), ""])
	R(x + 30, y + 94, 20, 2, "c0392b")
	_ao(x, y + 106, w); _lamp(x - 4, y + 108)


static func _market() -> void:
	var x := 214.0
	var y := 138.0
	var w := 92.0
	dim(x + 6, y + 8, w, 56, 0.3)
	R(x - 1, y, w + 2, 20, "3a3a40"); R(x, y + 1, w, 18, "c8c4ba")
	for i in 200:
		P(x + _rng.randf() * w, y + 1 + _rng.randf() * 18, "b8b4aa")
	R(x, y + 1, w, 1, "e0dcd2"); R(x + 8, y + 5, 10, 6, "8a8a92"); R(x + 24, y + 5, 10, 6, "8a8a92"); R(x + 70, y + 4, 14, 8, "7a7a82")
	for i in range(0, 12, 2):
		R(x + 71 + i, y + 5, 1, 6, "5a5a62")
	R(x - 1, y + 20, w + 2, 34, "2e2e34"); R(x, y + 20, w, 32, "ece6d8")
	R(x, y + 20, w, 7, "c0392b")
	for i in range(0, int(w), 8):
		R(x + i, y + 20, 4, 7, "e0503f")
	R(x, y + 27, w, 1, "7a2018")
	for i in 4:
		R(x + 4 + i * 22, y + 30, 18, 16, "2a3448"); R(x + 5 + i * 22, y + 31, 16, 14, "8fd0f0"); _lit.append([Rect2(x + 5 + i * 22, y + 31, 16, 14), "shop"])
	R(x + 38, y + 42, 16, 10, "3a3a40"); R(x + 39, y + 43, 14, 9, "a8e0ff"); _lit.append([Rect2(x + 39, y + 43, 14, 9), "shop"])
	_ao(x, y + 52, w)
	R(x + 2, y + 54, w - 4, 36, "4a4852")
	for i in range(0, int(w) - 4, 12):
		R(x + 6 + i, y + 58, 1, 14, "e8e4dc")
	_car(x + 18, y + 62, "c83a3a", true); _car(x + 66, y + 62, "3a6ac8", true)
	for i in 4:
		R(x + 8 + i * 5, y + 80, 4, 3, "b0b8c0"); P(x + 8 + i * 5, y + 83, "333333")
	_lamp(x + 2, y + 92); _lamp(x + w - 2, y + 92)


static func _harbor() -> void:
	for i in 90:
		R(300 + i, 170, 1, 7, "6a4428" if i % 3 == 0 else "8a5a34")
	R(300, 169, 90, 1, "5a3a20"); R(300, 177, 90, 1, "3a2410")
	for j in 60:
		R(366, 177 + j, 8, 1, "6a4428" if j % 3 == 0 else "8a5a34")
	R(365, 177, 1, 60, "3a2410")
	for i in 6:
		R(302 + i * 16, 177, 2, 4, "3a2410")
	R(320, 163, 6, 6, "8a5a34"); R(321, 164, 4, 4, "a87a4a"); R(328, 165, 5, 4, "8a5a34"); R(340, 166, 10, 3, "5a8a8a")
	var cs := [["c0392b", "e0503f"], ["2a6ab0", "3a82d0"], ["e0a020", "f2c14e"], ["2f8a6a", "3fa880"]]
	for k in 5:
		var cx := 214 + (k % 3) * 13
		var cy := 226 + (-7 if k > 2 else 8)
		var c: Array = cs[k % 4]
		R(cx, cy, 12, 7, c[0])
		for i in range(0, 12, 2):
			R(cx + i, cy, 1, 7, c[1])
	R(380, 150, 3, 22, "c8902a"); R(372, 150, 26, 3, "c8902a"); R(394, 152, 1, 10, "3a3a3a"); R(392, 162, 5, 3, "3a3a3a")
	ellipse(423, 156, 11, 5, "5a5a62"); ellipse(421, 154, 8, 3, "7a7a82")
	R(418, 130, 10, 26, "e8e4dc")
	for i in range(0, 26, 8):
		R(418, 130 + i, 10, 4, "c0392b")
	dim(426, 130, 2, 26, 0.2)
	R(416, 126, 14, 5, "3a3a40"); R(419, 122, 8, 5, "ffe7a0"); R(417, 120, 12, 2, "3a3a40")
	_lamp(306, 168); _lamp(386, 168)


static func _factory() -> void:
	var x := 322.0
	var y := 10.0
	dim(x + 6, y + 8, 108, 90, 0.3)
	for k in 2:
		var fx := x + k * 56
		R(fx - 1, y + 18, 54, 60, "2a2826"); R(fx, y + 18, 52, 58, "6e6862")
		for i in range(0, 52, 4):
			R(fx + i, y + 18, 1, 58, "625c56")
		for i in 4:
			for r in 12:
				R(fx + i * 13, y + 6 + r, 13 - r, 1, "8fa8b8" if r < 2 else "4a4642")
		for i in 4:
			R(fx + 2 + i * 13, y + 30, 9, 7, "2a3448")
		_window(fx + 4, y + 44, 8, 6); _window(fx + 30, y + 44, 8, 6, false)
		R(fx + 18, y + 58, 16, 18, "3a3632")
		for s in range(0, 18, 2):
			R(fx + 18, y + 58 + s, 16, 1, "4e4a46")
		_ao(fx, y + 76, 52)
	R(x + 98, y - 6, 9, 40, "3a3632"); R(x + 99, y - 6, 7, 40, "6a5a52"); R(x + 99, y - 2, 7, 2, "c0392b"); R(x + 99, y + 6, 7, 2, "c0392b")
	R(x + 86, y + 80, 30, 12, "5a5a62"); R(x + 86, y + 80, 30, 2, "e0a020")


static func _park() -> void:
	var x := 452.0
	var y := 8.0
	var w := 134.0
	var h := 100.0
	R(x, y, w, h, "5a9a44")
	for i in 900:
		P(x + _rng.randf() * w, y + _rng.randf() * h, "68ac50" if _rng.randf() < 0.5 else "4e8a3c")
	for i in range(0, int(w), 3):
		R(x + i, y, 2, 2, "2a2a30"); R(x + i, y + h - 2, 2, 2, "2a2a30")
	ellipse(x + 67, y + 50, 26, 18, "c8b48a")
	R(x + 60, y, 14, 32, "c8b48a"); R(x + 60, y + 66, 14, 34, "c8b48a"); R(x, y + 44, 40, 12, "c8b48a"); R(x + 92, y + 44, 42, 12, "c8b48a")
	ellipse(x + 67, y + 50, 13, 8, "8a8a92"); ellipse(x + 67, y + 50, 11, 6, "3a86b4"); R(x + 66, y + 44, 3, 6, "a8a8b0")
	for t: Vector2 in [Vector2(18, 18), Vector2(38, 26), Vector2(110, 20), Vector2(120, 80), Vector2(20, 80), Vector2(96, 90), Vector2(44, 86)]:
		_tree(x + t.x, y + t.y, 7 + int(t.x) % 3)
	_bench(x + 44, y + 34); _bench(x + 82, y + 64); _lamp(x + 52, y + 42); _lamp(x + 84, y + 60)


static func _cemetery() -> void:
	var x := 606.0
	var y := 8.0
	var w := 108.0
	var h := 100.0
	R(x, y, w, h, "4a7a3e")
	for i in 700:
		P(x + _rng.randf() * w, y + _rng.randf() * h, "527e44" if _rng.randf() < 0.5 else "3e6a34")
	for i in range(0, int(w), 3):
		R(x + i, y, 1, 4, "1a1a20"); R(x + i, y + h - 4, 1, 4, "1a1a20")
	R(x, y + 1, w, 1, "1a1a20"); R(x, y + h - 3, w, 1, "1a1a20")
	for r in 4:
		for c in 7:
			if c == 3 and r < 2:
				continue
			var gx := x + 8 + c * 14 + (r % 2) * 4
			var gy := y + 30 + r * 16
			if (r + c) % 3 == 0:
				R(gx + 2, gy - 6, 2, 8, "8a8a92"); R(gx, gy - 4, 6, 2, "8a8a92")
			else:
				R(gx, gy - 5, 6, 7, "6a6a72"); R(gx, gy - 5, 6, 1, "9a9aa2"); R(gx + 1, gy - 6, 4, 1, "9a9aa2")
			R(gx - 1, gy + 2, 8, 3, "3e5a32")
	R(x + 48, y + 8, 16, 18, "5a5a62"); R(x + 46, y + 4, 20, 6, "3a3a40"); R(x + 55, y - 2, 2, 8, "3a3a40"); R(x + 53, y, 6, 2, "3a3a40"); R(x + 54, y + 18, 4, 8, "2a2a30"); _window(x + 54, y + 11, 4, 4)
	_dead_tree(x + 12, y + 24); _dead_tree(x + 98, y + 88); _pine(x + 100, y + 30, 14); _pine(x + 10, y + 90, 12)
	for c: Vector2 in [Vector2(x + 20, y + 42), Vector2(x + 72, y + 58), Vector2(x + 40, y + 74)]:
		R(c.x, c.y, 1, 2, "f4ecd4")
		_candles.append(c)


static func _island() -> void:
	for i in 16:
		var a := i * 0.4
		R(620 + cos(a) * 36, 205 + sin(a) * 21, 3, 2, "6a6a72")
	ellipse(622, 203, 28, 15, "5a9a44")
	for i in 200:
		var a := _rng.randf() * TAU
		var r := _rng.randf()
		P(622 + cos(a) * 28 * r, 203 + sin(a) * 15 * r, "68ac50")
	for p: Vector2 in [Vector2(608, 198), Vector2(634, 196), Vector2(628, 210)]:
		R(p.x, p.y - 10, 2, 10, "8a6a3a")
		for k in 5:
			var a := k * 1.25
			for s in range(1, 6):
				P(p.x + cos(a) * s, p.y - 10 + sin(a) * s * 0.6 + s * 0.2, "2f7a2c")
	R(615, 205, 9, 6, "7a4a2a"); R(615, 205, 9, 2, "a86a3a"); P(619, 207, "f2c14e")
	for i in 16:
		R(588 + i, 214, 1, 4, "8a5a34")


static func _station() -> void:
	var x := 70.0
	var y := 278.0
	R(x, y, 140, 6, "a49c8e"); R(x, y, 140, 1, "e8e4dc")
	R(x + 30, y + 6, 70, 16, "3a2a20"); R(x + 31, y + 6, 68, 15, "c8a878")
	for i in range(0, 68, 4):
		R(x + 31 + i, y + 6, 1, 15, "b0905e")
	R(x + 28, y + 4, 74, 3, "5a3a2a")
	_window(x + 36, y + 10, 8, 7); _window(x + 52, y + 10, 8, 7); _window(x + 86, y + 10, 8, 7, false)
	ellipse(x + 72, y + 12, 4, 4, "e8e4dc"); R(x + 72, y + 10, 1, 3, "2a2a30"); R(x + 72, y + 12, 2, 1, "2a2a30")
	_lamp(x + 10, y + 5); _lamp(x + 120, y + 5); _bench(x + 108, y + 2)


static func _scatter() -> void:
	_tree(186, 140, 6); _tree(186, 206, 7); _tree(176, 236, 5); _tree(18, 128, 6); _tree(150, 232, 6)
	_tree(312, 104, 6); _tree(170, 110, 5); _bush(160, 140); _bush(12, 236); _bush(210, 112); _bush(316, 128)
	_tree(440, 104, 6); _tree(610, 140, 5); _pine(660, 140, 12); _pine(700, 136, 10); _bush(520, 140); _tree(560, 108, 5)
	_tree(20, 292, 5); _tree(240, 290, 6); _pine(300, 296, 10); _bush(260, 282)
	for l: Vector2 in [Vector2(60, 114), Vector2(150, 114), Vector2(250, 114), Vector2(192, 60), Vector2(192, 170), Vector2(212, 40), Vector2(420, 114), Vector2(560, 114), Vector2(680, 114), Vector2(588, 60)]:
		_lamp(l.x, l.y)
