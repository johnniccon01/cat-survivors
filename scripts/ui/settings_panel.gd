class_name SettingsPanel
extends ColorRect
## Settings screen, used from the main menu and the pause menu. Works with
## mouse, keyboard (arrows / Enter / left-right on sliders) and gamepad.
## Everything is saved right away.

signal closed

var _rows: VBoxContainer
var _language: Button
var _fullscreen: CheckButton
var _sound: CheckButton
var _vsync: CheckButton
var _numbers: CheckButton
var _shake: CheckButton
var _contrast: CheckButton
var _low_fx: CheckButton
var _first: Control
## Movement key buttons, and the action waiting for a new key (or "").
var _key_buttons: Dictionary = {}
var _waiting := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var box := UiStyle.overlay(self, 1.0)
	box.add_child(UiStyle.label("SETTINGS_TITLE", 40, UiStyle.GOLD))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 5)
	box.add_child(_rows)

	_sound = _toggle("SET_SOUND", not Settings.muted, func(on: bool) -> void:
		if on == Settings.muted:
			Settings.toggle_mute())
	_first = _sound
	_slider("SET_MASTER", Settings.master_volume, func(v: float) -> void: Settings.set_volume("master", v))
	_slider("SET_MUSIC", Settings.music_volume, func(v: float) -> void: Settings.set_volume("music", v))
	_slider("SET_SFX", Settings.sfx_volume, func(v: float) -> void:
		Settings.set_volume("sfx", v)
		Audio.play("xp", -6.0, 0.0))
	_fullscreen = _toggle("SET_FULLSCREEN", Settings.fullscreen, func(on: bool) -> void: Settings.set_fullscreen(on))
	_vsync = _toggle("SET_VSYNC", Settings.vsync, func(on: bool) -> void: Settings.set_vsync(on))
	_numbers = _toggle("SET_NUMBERS", Settings.damage_numbers, func(on: bool) -> void:
		if on != Settings.damage_numbers:
			Settings.toggle_damage_numbers())
	_shake = _toggle("SET_SHAKE", Settings.screen_shake, func(on: bool) -> void:
		if on != Settings.screen_shake:
			Settings.toggle_screen_shake())
	_contrast = _toggle("SET_CONTRAST", Settings.high_contrast, func(on: bool) -> void: Settings.set_high_contrast(on))
	_low_fx = _toggle("SET_LOW_FX", Settings.low_effects, func(on: bool) -> void: Settings.set_low_effects(on))
	_language = UiStyle.button("", 520, 20)
	_language.pressed.connect(func() -> void:
		Settings.cycle_language()
		_refresh_language())
	_rows.add_child(_language)
	_refresh_language()
	# Movement keys in two columns to keep the panel on screen.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 5)
	_rows.add_child(grid)
	for action: String in Settings.REBINDABLE:
		var b := UiStyle.button("", 256, 17)
		b.custom_minimum_size.y = 32
		b.pressed.connect(func() -> void:
			_waiting = action
			_refresh_keys())
		grid.add_child(b)
		_key_buttons[action] = b
	var reset := UiStyle.button("SET_KEYS_RESET", 520, 17)
	reset.custom_minimum_size.y = 32
	reset.pressed.connect(func() -> void:
		Settings.reset_keys()
		_refresh_keys())
	_rows.add_child(reset)
	_refresh_keys()

	var back := UiStyle.button("SET_BACK", 520)
	back.pressed.connect(close)
	box.add_child(back)
	# Up from the first row wraps to Back and down from Back to the first row.
	_first.focus_neighbor_top = _first.get_path_to(back)
	back.focus_neighbor_bottom = back.get_path_to(_first)


func open() -> void:
	visible = true
	_sound.button_pressed = not Settings.muted
	_fullscreen.button_pressed = Settings.fullscreen
	_numbers.button_pressed = Settings.damage_numbers
	_shake.button_pressed = Settings.screen_shake
	_contrast.button_pressed = Settings.high_contrast
	_low_fx.button_pressed = Settings.low_effects
	_first.grab_focus.call_deferred()


func close() -> void:
	_waiting = ""
	visible = false
	closed.emit()


func _refresh_keys() -> void:
	for action: String in _key_buttons:
		var b: Button = _key_buttons[action]
		var key := tr("SET_KEY_WAITING") if action == _waiting else Settings.key_name(action)
		b.text = "%s: %s" % [tr("SET_KEY_%s" % action.to_upper()), key]


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


func _refresh_language() -> void:
	_language.text = "%s: %s" % [tr("SET_LANGUAGE"), tr("LANGUAGE_NAME")]


func _slider(title: String, value: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(520, 34)
	var l := UiStyle.label(title, 20, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 260
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(250, 30)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_ALL
	s.value_changed.connect(on_change)
	s.add_theme_stylebox_override("slider", UiStyle.box(UiStyle.PANEL, UiStyle.BORDER))
	s.add_theme_stylebox_override("grabber_area", UiStyle.box(UiStyle.GOLD.darkened(0.3), UiStyle.GOLD))
	s.add_theme_stylebox_override("grabber_area_highlight", UiStyle.box(UiStyle.GOLD, UiStyle.GOLD))
	row.add_child(s)
	_rows.add_child(row)
	return s


func _toggle(title: String, value: bool, on_change: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = title
	c.button_pressed = value
	c.custom_minimum_size = Vector2(520, 34)
	c.focus_mode = Control.FOCUS_ALL
	c.add_theme_font_size_override("font_size", 20)
	c.add_theme_color_override("font_color", UiStyle.TEXT)
	c.add_theme_color_override("font_focus_color", UiStyle.GOLD)
	c.add_theme_color_override("font_hover_color", UiStyle.GOLD)
	c.add_theme_color_override("font_pressed_color", UiStyle.TEXT)
	c.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.PANEL, UiStyle.BORDER))
	c.add_theme_stylebox_override("hover", UiStyle.box(UiStyle.PANEL_HOVER, UiStyle.GOLD))
	c.add_theme_stylebox_override("focus", UiStyle.box(UiStyle.PANEL_HOVER, UiStyle.GOLD))
	c.add_theme_stylebox_override("pressed", UiStyle.box(UiStyle.PANEL, UiStyle.BORDER))
	c.toggled.connect(on_change)
	_rows.add_child(c)
	return c
