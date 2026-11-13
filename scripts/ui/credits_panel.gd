class_name CreditsPanel
extends Control
## The end of the story: the night sky, the epilogue, everyone who helped,
## every cat that came along and your journey in numbers, rolling up the
## screen while the cats parade along the rooftops. Shown once the director
## falls, and from the main menu after that. Any key or click (after a
## moment) skips; it closes by itself at the end.

signal finished

const SPEED := 42.0
const FAST := 4.0
const WIDTH := 760.0

var _roll: VBoxContainer
var _parade: Array[CatPreview] = []
var _t := 0.0
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color("120b06")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var sky := MenuSky.new()
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	# The rooftops the cats walk on.
	var roof := ColorRect.new()
	roof.color = Color("2a1a0e")
	roof.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	roof.offset_top = -88
	roof.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(roof)
	var clip := Control.new()
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.offset_bottom = -176
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	_roll = VBoxContainer.new()
	_roll.add_theme_constant_override("separation", 10)
	_roll.custom_minimum_size.x = WIDTH
	_roll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_roll)
	_build()
	_roll.reset_size()
	_roll.position = Vector2((get_viewport_rect().size.x - WIDTH) / 2.0, get_viewport_rect().size.y - 190.0)
	_make_parade()
	var hint := UiStyle.plain(tr("CREDITS_SKIP"), 13, UiStyle.MUTED)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left = -260
	hint.offset_top = -26
	hint.offset_right = -14
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)


func _build() -> void:
	_line("Cat Survivors", 54, UiStyle.GOLD)
	_line(tr("CREDITS_THE_END"), 26, Color.WHITE)
	_gap(40)
	for key in ["ENDING_STORY", "CREDITS_EPILOGUE_1", "CREDITS_EPILOGUE_2"]:
		_line(tr(key), 18, Color("f4e8cb"), true)
		_gap(8)
	_gap(40)
	_head(tr("CREDITS_ALLIES"))
	for ally: String in FinaleAllies.roster():
		_line(tr("ENEMY_PARROT_NAME" if ally == "PARROT" else "CAT_%s_NAME" % ally), 20, Color.WHITE)
	_gap(40)
	_head(tr("CREDITS_CATS"))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for id in _cats():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		var cat := CatPreview.new()
		cat.cat_id = id
		cat.zoom = 1.7
		cat.custom_minimum_size = Vector2(130, 78)
		cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(cat)
		var name_label := UiStyle.plain(tr("CAT_%s_NAME" % id), 15)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(name_label)
		grid.add_child(col)
	_roll.add_child(grid)
	_gap(40)
	_head(tr("CREDITS_JOURNEY"))
	var wins := 0
	for key: String in Profile.stats:
		if key.begins_with("wins:"):
			wins += int(Profile.stats[key])
	_line(tr("CREDITS_STAT_NIGHTS") % Profile.get_stat("runs"), 18, Color.WHITE)
	_line(tr("CREDITS_STAT_WINS") % wins, 18, Color.WHITE)
	_line(tr("CREDITS_STAT_KILLS") % Hud.thousands(Profile.get_stat("kills")), 18, Color.WHITE)
	_line(tr("CREDITS_STAT_QUESTS") % Profile.get_stat("quests"), 18, Color.WHITE)
	_line(tr("CREDITS_STAT_MAPS") % [Profile.cleared_stages.size(), GameData.stages.size()], 18, Color.WHITE)
	_gap(80)
	_line(tr("CREDITS_THANKS"), 30, UiStyle.GOLD)
	_gap(120)


## Every cat you have, in the order of the game.
func _cats() -> Array[String]:
	var out: Array[String] = []
	for id: String in GameData.cats:
		if not GameData.cats[id].get("npc", false) and Profile.is_unlocked(id):
			out.append(id)
	return out


func _line(text: String, size: int, color: Color, wrap: bool = false) -> void:
	var l := UiStyle.label(text, size, color)
	l.custom_minimum_size.x = WIDTH
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_roll.add_child(l)


func _head(text: String) -> void:
	_line(text.to_upper(), 15, Color("d9bf94"))


func _gap(h: float) -> void:
	var c := Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll.add_child(c)


## The cats stroll along the rooftop at the bottom, as on the title screen.
func _make_parade() -> void:
	var ids := _cats()
	var gap := 1400.0 / maxf(ids.size(), 1)
	for i in ids.size():
		var cat := CatPreview.new()
		cat.cat_id = ids[i]
		cat.walking = true
		cat.size = Vector2(110, 110)
		cat.position = Vector2(-120 + i * gap, get_viewport_rect().size.y - 150.0)
		cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cat)
		_parade.append(cat)


func _process(delta: float) -> void:
	_t += delta
	var fast := Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_roll.position.y -= SPEED * delta * (FAST if fast else 1.0)
	for i in _parade.size():
		var cat := _parade[i]
		cat.position.x += (36.0 + float(i % 3) * 6.0) * delta
		if cat.position.x > size.x + 20.0:
			cat.position.x -= size.x + 160.0
	if _roll.position.y + _roll.size.y < 0.0:
		_finish()


func _input(event: InputEvent) -> void:
	if _done or _t < 1.0:
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_ENTER):
		get_viewport().set_input_as_handled()
		_finish()
	elif event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	Profile.set_flag("credits_seen")
	finished.emit()
	queue_free()
