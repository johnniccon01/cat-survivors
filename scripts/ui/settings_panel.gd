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
var _first: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var box := UiStyle.overlay(self, 0.97)
	box.add_child(UiStyle.label("SETTINGS_TITLE", 40, UiStyle.GOLD))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
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
	_language = UiStyle.button("", 520, 20)
	_language.pressed.connect(func() -> void:
		Settings.cycle_language()
		_refresh_language())
	_rows.add_child(_language)
	_refresh_language()

	var back := UiStyle.button("SET_BACK", 520)
	back.pressed.connect(close)
	box.add_child(back)


func open() -> void:
	visible = true
	_sound.button_pressed = not Settings.muted
	_fullscreen.button_pressed = Settings.fullscreen
	_numbers.button_pressed = Settings.damage_numbers
	_shake.button_pressed = Settings.screen_shake
	_first.grab_focus.call_deferred()


func close() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _refresh_language() -> void:
	_language.text = "%s: %s" % [tr("SET_LANGUAGE"), tr("LANGUAGE_NAME")]


func _slider(title: String, value: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(520, 40)
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
	c.custom_minimum_size = Vector2(520, 40)
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
