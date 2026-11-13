class_name SettingsPanel
extends ColorRect
## Settings screen, used from the main menu and the pause menu, in the
## "shoe box" look: one big sheet of cardboard, the title on a paper card held
## by tape, paw bullets, scribbled toggles, paw-knob sliders and key caps.
## Works with mouse, keyboard (arrows / Enter / left-right on sliders and the
## language) and gamepad. Everything is saved right away.

signal closed

const STAGE := Vector2(1280, 720)
const LEFT_X := 102.0
const RIGHT_X := 666.0
const LEFT_W := 499.0
const RIGHT_W := 512.0
const ROW_H := 41.0
const ROW_DESC_H := 58.0

var _sound: SetRow
var _fullscreen: SetRow
var _vsync: SetRow
var _numbers: SetRow
var _shake: SetRow
var _contrast: SetRow
var _low_fx: SetRow
var _master: SetRow
var _music: SetRow
var _sfx: SetRow
var _title: Label
var _group_title: Label
var _back: BoxButton
var _reset: BoxButton
var _stage: Control
var _y := 0.0
var _seed := 10
## Movement key rows, and the action waiting for a new key (or "").
var _key_buttons: Dictionary = {}
var _waiting := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.1, 0.07, 0.045, 1.0)
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_stage.offset_left = -STAGE.x * 0.5
	_stage.offset_right = STAGE.x * 0.5
	_stage.offset_top = -STAGE.y * 0.5
	_stage.offset_bottom = STAGE.y * 0.5
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	_stage.add_child(BoxBoard.make("board", Vector2(45, 62), Vector2(1190, 626), 5, -0.4))
	var card := BoxBoard.make("light", Vector2(83, 14), Vector2(384, 98), 4, -2.0)
	_stage.add_child(card)
	_title = BoxStyle.label("SETTINGS_TITLE", 60, BoxStyle.INK, true)
	_title.position = Vector2(0, 8)
	_title.size = Vector2(384, 80)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(_title)
	_stage.add_child(BoxBoard.make("tape", Vector2(56, 34), Vector2(90, 31), 3, -40.0))
	_stage.add_child(BoxBoard.make("stamp", Vector2(1118, 18), Vector2(84, 84), 6, 14.0))

	# Left column: sound, then picture.
	_y = 136.0
	var gcard := BoxBoard.make("light", Vector2(LEFT_X - 8, _y), Vector2(190, 38), 8, -1.2)
	_stage.add_child(gcard)
	_group_title = BoxStyle.label("SET_SOUND", 26, BoxStyle.INK, true)
	_group_title.position = Vector2(0, 0)
	_group_title.size = Vector2(190, 38)
	_group_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_group_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gcard.add_child(_group_title)
	_y += 44.0
	_sound = _row("toggle", "SET_SOUND", LEFT_X, LEFT_W, ROW_H)
	_sound.changed.connect(func(on: bool) -> void:
		if on == Settings.muted:
			Settings.toggle_mute())
	_master = _row("slider", "SET_MASTER", LEFT_X, LEFT_W, ROW_H)
	_master.changed.connect(func(v: float) -> void: Settings.set_volume("master", v))
	_music = _row("slider", "SET_MUSIC", LEFT_X, LEFT_W, ROW_H)
	_music.changed.connect(func(v: float) -> void: Settings.set_volume("music", v))
	_sfx = _row("slider", "SET_SFX", LEFT_X, LEFT_W, ROW_H)
	_sfx.changed.connect(func(v: float) -> void:
		Settings.set_volume("sfx", v)
		Audio.play("xp", -6.0, 0.0))
	_divider(LEFT_X, LEFT_W)
	_fullscreen = _row("toggle", "SET_FULLSCREEN", LEFT_X, LEFT_W, ROW_H)
	_fullscreen.changed.connect(func(on: bool) -> void: Settings.set_fullscreen(on))
	_vsync = _row("toggle", "SET_VSYNC", LEFT_X, LEFT_W, ROW_H)
	_vsync.changed.connect(func(on: bool) -> void: Settings.set_vsync(on))
	_numbers = _row("toggle", "SET_NUMBERS", LEFT_X, LEFT_W, ROW_H)
	_numbers.changed.connect(func(on: bool) -> void:
		if on != Settings.damage_numbers:
			Settings.toggle_damage_numbers())
	_shake = _row("toggle", "SET_SHAKE", LEFT_X, LEFT_W, ROW_H)
	_shake.changed.connect(func(on: bool) -> void:
		if on != Settings.screen_shake:
			Settings.toggle_screen_shake())

	# Right column: game, language, controls.
	_y = 180.0
	_contrast = _row("toggle", "SET_CONTRAST", RIGHT_X, RIGHT_W, ROW_DESC_H, true)
	_contrast.changed.connect(func(on: bool) -> void: Settings.set_high_contrast(on))
	_low_fx = _row("toggle", "SET_LOW_FX", RIGHT_X, RIGHT_W, ROW_DESC_H, true)
	_low_fx.changed.connect(func(on: bool) -> void: Settings.set_low_effects(on))
	var language := _row("lang", "SET_LANGUAGE", RIGHT_X, RIGHT_W, ROW_H)
	language.changed.connect(func(step: int) -> void:
		for i in (1 if step > 0 else Settings.LANGUAGES.size() - 1):
			Settings.cycle_language())
	_divider(RIGHT_X, RIGHT_W)
	for action: String in Settings.REBINDABLE:
		var r := _row("key", "SET_KEY_%s" % action.to_upper(), RIGHT_X, RIGHT_W, ROW_H)
		r.action = action
		r.activated.connect(func() -> void:
			_waiting = action
			_refresh_keys())
		_key_buttons[action] = r

	_back = BoxButton.make("SET_BACK", 30, 11, -1.4, true, false, 217.0)
	_back.position = Vector2(115, 592)
	_back.size = _back.custom_minimum_size
	_back.pressed.connect(close)
	_stage.add_child(_back)
	_reset = BoxButton.make("SET_KEYS_RESET", 22, 12, 1.0, true, false, 358.0)
	_reset.size = _reset.custom_minimum_size
	_reset.position = Vector2(RIGHT_X + RIGHT_W * 0.5 - _reset.size.x * 0.5, 596)
	_reset.pressed.connect(func() -> void:
		Settings.reset_keys()
		_refresh_keys())
	_stage.add_child(_reset)
	_refresh_keys()
	_fit_titles()
	# Up from the first row wraps to Back and down from Back to the first row.
	_sound.focus_neighbor_top = _sound.get_path_to(_back)
	_back.focus_neighbor_bottom = _back.get_path_to(_sound)


func _row(kind: String, title: String, x: float, w: float, h: float, desc: bool = false) -> SetRow:
	_seed += 1
	var r := SetRow.make(kind, title, _seed, desc)
	r.position = Vector2(x, _y)
	r.size = Vector2(w, h)
	_y += h
	_stage.add_child(r)
	return r


## A red marker line between the groups that have no title of their own.
func _divider(x: float, w: float) -> void:
	_y += 4.0
	_stage.add_child(BoxBoard.make("scribble", Vector2(x + 14, _y), Vector2(w - 60, 12), 21 + int(x)))
	_y += 18.0


func open() -> void:
	visible = true
	_sound.on = not Settings.muted
	_fullscreen.on = Settings.fullscreen
	_vsync.on = Settings.vsync
	_numbers.on = Settings.damage_numbers
	_shake.on = Settings.screen_shake
	_contrast.on = Settings.high_contrast
	_low_fx.on = Settings.low_effects
	_master.value = Settings.master_volume
	_music.value = Settings.music_volume
	_sfx.value = Settings.sfx_volume
	for n in _stage.get_children():
		if n is SetRow:
			n.queue_redraw()
	_sound.grab_focus.call_deferred()


func close() -> void:
	_waiting = ""
	_refresh_keys()
	visible = false
	closed.emit()


func _refresh_keys() -> void:
	for action: String in _key_buttons:
		var r: SetRow = _key_buttons[action]
		r.waiting = action == _waiting
		r.key_text = Settings.key_name(action)
		r.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fit_titles()


func _fit_titles() -> void:
	_title.label_settings.font_size = BoxStyle.fit_size(tr("SETTINGS_TITLE"), BoxStyle.head_font(), 60, 340, 24)
	_group_title.label_settings.font_size = BoxStyle.fit_size(tr("SET_SOUND"), BoxStyle.head_font(), 26, 160, 14)


## While waiting for a new movement key, the next key press is it (Esc
## cancels). _input so the press doesn't also click a button.
func _input(event: InputEvent) -> void:
	if not visible or _waiting == "" or not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	var key := (event as InputEventKey).physical_keycode
	if key != KEY_ESCAPE:
		Settings.rebind(_waiting, key)
	_waiting = ""
	_refresh_keys()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


## One line of the sheet: a red paw bullet, the name (and a small note) and
## the control on the right: "toggle", "slider", "lang" (a picker with arrows)
## or "key" (a key cap). Focusable; Enter / A or a click activates it.
class SetRow extends Control:
	signal changed(v: Variant)
	signal activated

	const SLIDER_W := 190.0
	const VALUE_W := 54.0
	const LANG_W := 250.0

	var kind := "toggle"
	var title_key := ""
	var split_desc := false
	var on := false
	var value := 0.0
	var action := ""
	var waiting := false
	var key_text := ""
	var look_seed := 1
	var _drag := false
	var _hover := false


	static func make(kind_: String, title_: String, seed_: int, desc_: bool) -> SetRow:
		var r := SetRow.new()
		r.kind = kind_
		r.title_key = title_
		r.look_seed = seed_
		r.split_desc = desc_
		r.focus_mode = Control.FOCUS_ALL
		r.mouse_entered.connect(func() -> void:
			r._hover = true
			r.grab_focus()
			r.queue_redraw())
		r.mouse_exited.connect(func() -> void:
			r._hover = false
			r.queue_redraw())
		r.focus_entered.connect(r.queue_redraw)
		r.focus_exited.connect(r.queue_redraw)
		r.resized.connect(r.queue_redraw)
		return r


	func _notification(what: int) -> void:
		if what == NOTIFICATION_TRANSLATION_CHANGED:
			queue_redraw()


	func _parts() -> PackedStringArray:
		var t := tr(title_key)
		if not split_desc:
			return PackedStringArray([t, ""])
		var i := -1
		for ch in ["(", "（"]:
			var k := t.find(ch)
			if k > 0 and (i < 0 or k < i):
				i = k
		if i < 0:
			return PackedStringArray([t, ""])
		return PackedStringArray([t.substr(0, i).strip_edges(), t.substr(i + 1).rstrip(")）").strip_edges()])


	func _toggle() -> void:
		on = not on
		changed.emit(on)
		queue_redraw()


	func _set_value(v: float) -> void:
		v = clampf(snappedf(v, 0.05), 0.0, 1.0)
		if is_equal_approx(v, value):
			return
		value = v
		changed.emit(v)
		queue_redraw()


	func _slide_to(x: float) -> void:
		var x0 := size.x - SLIDER_W - VALUE_W - 8.0 - 6.0
		_set_value((x - (x0 + 14.0)) / (SLIDER_W - 28.0))


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var mb := event as InputEventMouseButton
			if not mb.pressed:
				_drag = false
				return
			accept_event()
			match kind:
				"toggle":
					_toggle()
				"slider":
					_drag = true
					_slide_to(mb.position.x)
				"lang":
					changed.emit(-1 if mb.position.x < size.x - LANG_W * 0.5 - 6.0 else 1)
				"key":
					activated.emit()
		elif event is InputEventMouseMotion and _drag:
			_slide_to((event as InputEventMouseMotion).position.x)
		elif event.is_action_pressed("ui_accept"):
			accept_event()
			match kind:
				"toggle":
					_toggle()
				"lang":
					changed.emit(1)
				"key":
					activated.emit()
		elif kind == "slider" and event.is_action_pressed("ui_left", true):
			accept_event()
			_set_value(value - 0.05)
		elif kind == "slider" and event.is_action_pressed("ui_right", true):
			accept_event()
			_set_value(value + 0.05)
		elif kind == "lang" and event.is_action_pressed("ui_left"):
			accept_event()
			changed.emit(-1)
		elif kind == "lang" and event.is_action_pressed("ui_right"):
			accept_event()
			changed.emit(1)


	func _text_y(font: Font, fs: int, mid: float) -> float:
		return mid + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5


	func _wobble(mid: Vector2, r: float, s: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 22:
			var a := TAU * i / 22.0
			pts.append(mid + Vector2(cos(a), sin(a)) * r * (1.0 + 0.07 * sin(a * 3.0 + s) + 0.04 * sin(a * 5.0 + s * 2)))
		return pts


	func _draw() -> void:
		var w := size.x
		var h := size.y
		var lit := has_focus() or _hover
		var body := BoxStyle.body_font()
		var head := BoxStyle.head_font()
		if lit:
			var hl := BoxStyle.torn(Vector2(w, h - 4.0), look_seed, 2.0)
			for i in hl.size():
				hl[i] += Vector2(0, 2)
			draw_colored_polygon(hl, Color(0.98, 0.93, 0.79, 0.62))
		BoxStyle.draw_paw(self, Vector2(17, h * 0.5), 21.0 if lit else 17.0, BoxStyle.RED, -12.0)
		var tx := 36.0
		var parts := _parts()
		var cy := h * 0.5
		match kind:
			"toggle":
				_draw_toggle(Vector2(w - 40.0, cy - 15.0))
				_draw_title(parts, body, tx, w - tx - 52.0, h)
			"slider":
				var cw := SLIDER_W + VALUE_W + 8.0 + 6.0
				_draw_title(parts, body, tx, w - tx - cw - 8.0, h)
				_draw_slider(Vector2(w - cw, cy), head)
			"lang":
				_draw_title(parts, body, tx, w - tx - LANG_W - 14.0, h)
				_draw_lang(Vector2(w - LANG_W - 6.0, cy), head)
			"key":
				_draw_key(parts[0], tx, w, cy, body, head)


	func _draw_title(parts: PackedStringArray, font: Font, x: float, avail: float, h: float) -> void:
		var fs := BoxStyle.fit_size(parts[0], font, 20, avail, 12)
		var mid := h * 0.5 - (11.0 if parts[1] != "" else 0.0)
		draw_string(font, Vector2(x, _text_y(font, fs, mid)), parts[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, BoxStyle.INK)
		if parts[1] != "":
			var ds := BoxStyle.fit_size(parts[1], font, 14, avail, 10)
			draw_string(font, Vector2(x, _text_y(font, ds, h * 0.5 + 13.0)), parts[1], HORIZONTAL_ALIGNMENT_LEFT, -1, ds, Color(BoxStyle.INK, 0.78))


	func _draw_toggle(at: Vector2) -> void:
		var poly := BoxStyle.torn(Vector2(30, 30), look_seed, 2.6)
		for i in poly.size():
			poly[i] += at
		draw_colored_polygon(poly, BoxStyle.CREAM)
		var edge := poly.duplicate()
		edge.append(poly[0])
		draw_polyline(edge, BoxStyle.INK, 2.6, true)
		if on:
			var hook := PackedVector2Array([at + Vector2(5, 16), at + Vector2(12, 24), at + Vector2(16, 18), at + Vector2(35, -3)])
			draw_polyline(hook, BoxStyle.RED, 5.0, true)


	func _draw_slider(at: Vector2, head: Font) -> void:
		var x0 := at.x + 14.0
		var x1 := at.x + SLIDER_W - 14.0
		var kx := lerpf(x0, x1, value)
		draw_line(Vector2(x0 - 6.0, at.y), Vector2(x1 + 6.0, at.y), BoxStyle.KRAFT_DEEP, 8.0, true)
		draw_circle(Vector2(x0 - 6.0, at.y), 4.0, BoxStyle.KRAFT_DEEP)
		draw_circle(Vector2(x1 + 6.0, at.y), 4.0, BoxStyle.KRAFT_DEEP)
		if value > 0.0:
			draw_line(Vector2(x0 - 6.0, at.y), Vector2(kx, at.y), BoxStyle.RED, 6.0, true)
			draw_circle(Vector2(x0 - 6.0, at.y), 3.0, BoxStyle.RED)
		var knob := _wobble(Vector2(kx, at.y), 14.0, look_seed)
		draw_colored_polygon(knob, BoxStyle.CREAM)
		var edge := knob.duplicate()
		edge.append(knob[0])
		draw_polyline(edge, BoxStyle.INK, 2.6, true)
		BoxStyle.draw_paw(self, Vector2(kx, at.y), 14.0, BoxStyle.RED, -10.0)
		var txt := "%d %%" % roundi(value * 100.0)
		var fs := 25
		var tw := head.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(head, Vector2(at.x + SLIDER_W + 8.0 + VALUE_W - tw, _text_y(head, fs, at.y)), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, BoxStyle.INK)


	func _draw_lang(at: Vector2, head: Font) -> void:
		var name_ := tr("LANGUAGE_NAME")
		var fs := BoxStyle.fit_size(name_, head, 26, LANG_W - 60.0, 14)
		var tw := head.get_string_size(name_, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var mx := at.x + LANG_W * 0.5
		draw_string(head, Vector2(mx - tw * 0.5, _text_y(head, fs, at.y)), name_, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, BoxStyle.INK)
		var ax := maxf(tw * 0.5 + 16.0, 40.0)
		for side in [-1.0, 1.0]:
			var c := Vector2(mx + side * ax, at.y)
			var pts := PackedVector2Array([c + Vector2(-side * 6.0, -10.0), c + Vector2(side * 5.0, 0.0), c + Vector2(-side * 6.0, 10.0)])
			draw_polyline(pts, BoxStyle.RED, 4.5, true)


	func _draw_key(title: String, tx: float, w: float, cy: float, body: Font, head: Font) -> void:
		var lfs := BoxStyle.fit_size(title, body, 20, (w * 0.4) if waiting else (w - tx - 80.0), 12)
		var lw := body.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, lfs).x
		draw_string(body, Vector2(tx, _text_y(body, lfs, cy)), title, HORIZONTAL_ALIGNMENT_LEFT, -1, lfs, BoxStyle.INK)
		var space := w - tx - lw - 24.0
		var txt := tr("SET_KEY_WAITING") if waiting else key_text
		var font := body if waiting else head
		var fs := BoxStyle.fit_size(txt, font, 16 if waiting else 24, space - 24.0, 10)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var cw := maxf(46.0, tw + 24.0)
		var ch := 36.0
		var at := Vector2(w - 6.0 - cw, cy - 20.0)
		var rim := BoxStyle.torn(Vector2(cw, ch), look_seed, 2.0)
		for i in rim.size():
			rim[i] += at
		draw_colored_polygon(rim, BoxStyle.INK)
		var top := BoxStyle.torn(Vector2(cw - 7.0, ch - 11.0), look_seed + 1, 1.5)
		for i in top.size():
			top[i] += at + Vector2(3.5, 3.0)
		draw_colored_polygon(top, Color("fff4d6") if waiting else BoxStyle.CREAM)
		if waiting:
			var ring := Rect2(at + Vector2(3.5, 3.0), Vector2(cw - 7.0, ch - 11.0))
			BoxStyle.draw_ring(self, ring, look_seed, BoxStyle.RED, 3.0, 3.0)
		draw_string(font, Vector2(at.x + (cw - tw) * 0.5, _text_y(font, fs, at.y + (ch - 8.0) * 0.5)), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, BoxStyle.INK)
