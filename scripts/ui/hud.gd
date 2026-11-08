class_name Hud
extends CanvasLayer
## Run clock, kill counter, pause and game-over overlays. Built in code for
## now; will move to a proper scene once the UI grows.

const XP_BAR_HEIGHT := 7.0

signal resume_pressed
signal give_up_pressed
signal discard_pressed
## A button of the end screen: "next", "again", "back" or "endless".
signal end_action(action: String)

var level_up: LevelUpPanel
var settings: SettingsPanel
var treasure: TreasurePanel
var choice: ChoicePanel

var _xp_fill: ColorRect
var _level_label: Label
var _inventory: InventoryBar
var _time_label: Label
var _kills_label: Label
var _gold_label: Label
var _bless_label: Label
var _debug_label: Label
var _pause_resume: Button
var _pause_overlay: Control
var _give_up: Button
var _discard: Button
var _pause_stories: VBoxContainer
var _pause_stories_panel: PanelContainer
var _pause_language: Label
var _pause_sound: Label
var _pause_numbers: Label
var _pause_shake: Label
## The pause screen's side panels: weapon cards on the left, the quest now
## and the messages on the right (filled each time the game pauses).
var _pause_weapons: VBoxContainer
var _pause_log: VBoxContainer
var _discard_left: Label
## Recent banner texts (quest lines, shrines...), newest first, with the
## clock when they came: [time, text].
var _log: Array = []
const LOG_SIZE := 15
var _hurt_flash: ColorRect
var _over_overlay: Control
var _over_stats: Label
var _win_overlay: Control
var _win_stats: Label
var _banner: Label
var _quest_title: Label
var _quest_text: Label
## Tonight's conquest: the next flag, the one to take, or its keeper.
var _conquest: Label
## The night offer you took (defence, rescue...) and whether it is done.
var _mission: Label
var _quest_arrow: QuestArrow
var _extract_arrow: QuestArrow
var _page_arrow: QuestArrow
var _extract_label: Label
var _extract_overlay: Control
var _boss_bar: ColorRect
var _boss_fill: ColorRect
var _boss_name: Label
var _banner_time := 0.0
## The banner's dark pill (the label sits inside it).
var _banner_box: PanelContainer
var _hp_fill: ColorRect
var _hp_label: Label
var _night: NightBar
var _next_boss: Label
var _gold_row: HBoxContainer
var _extract_row: HBoxContainer


func _ready() -> void:
	var xp_bg := ColorRect.new()
	xp_bg.color = Color(0.05, 0.03, 0.07, 0.85)
	xp_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	xp_bg.offset_bottom = XP_BAR_HEIGHT
	add_child(xp_bg)
	_xp_fill = ColorRect.new()
	_xp_fill.color = Color("e9b445")
	_xp_fill.size = Vector2(0, XP_BAR_HEIGHT)
	xp_bg.add_child(_xp_fill)
	var xp_shine := ColorRect.new()
	xp_shine.color = Color("ffe08e")
	xp_shine.size = Vector2(0, 2)
	_xp_fill.add_child(xp_shine)
	_xp_fill.resized.connect(func() -> void: xp_shine.size.x = _xp_fill.size.x)

	# Top left: level plate, heart and health bar with the numbers.
	var top_left := HBoxContainer.new()
	top_left.position = Vector2(12, 14)
	top_left.add_theme_constant_override("separation", 9)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_left)
	var plate := PanelContainer.new()
	var plate_sb := StyleBoxFlat.new()
	plate_sb.bg_color = Color(0.055, 0.04, 0.08, 0.8)
	plate_sb.border_color = Color("6a5784")
	plate_sb.set_border_width_all(2)
	plate_sb.set_corner_radius_all(6)
	plate_sb.content_margin_left = 8
	plate_sb.content_margin_right = 8
	plate.add_theme_stylebox_override("panel", plate_sb)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_left.add_child(plate)
	_level_label = _label(15, HORIZONTAL_ALIGNMENT_CENTER)
	_level_label.label_settings.font_color = UiStyle.GOLD
	plate.add_child(_level_label)
	top_left.add_child(PixelGlyph.rect("heart", 2))
	var hp_bg := ColorRect.new()
	hp_bg.color = Color(0.05, 0.03, 0.07, 0.85)
	hp_bg.custom_minimum_size = Vector2(150, 10)
	hp_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_left.add_child(hp_bg)
	_hp_fill = ColorRect.new()
	_hp_fill.color = Color("dc4a40")
	_hp_fill.size = Vector2(150, 10)
	hp_bg.add_child(_hp_fill)
	_hp_label = _label(15, HORIZONTAL_ALIGNMENT_LEFT)
	top_left.add_child(_hp_label)

	_time_label = _label(34, HORIZONTAL_ALIGNMENT_CENTER)
	_time_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_time_label.offset_top = 8
	add_child(_time_label)
	# The night's progress under the clock: boss marks and the final boss.
	_night = NightBar.new()
	_night.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_night.offset_left = -85
	_night.offset_right = 85
	_night.offset_top = 56
	_night.offset_bottom = 62
	add_child(_night)
	_next_boss = _label(12, HORIZONTAL_ALIGNMENT_CENTER)
	_next_boss.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_next_boss.offset_top = 64
	_next_boss.label_settings.font_color = Color("d4c9e2")
	add_child(_next_boss)

	_kills_label = _label(18, HORIZONTAL_ALIGNMENT_RIGHT)
	var kills_row := _icon_row(_kills_label, "paw")
	kills_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	kills_row.offset_top = 12
	kills_row.offset_right = -14
	kills_row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(kills_row)

	# Right column under the kills: quest, gold, blessings stacked so long
	# quest texts push the rest down instead of covering it.
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	column.offset_top = 40
	column.offset_right = -14
	column.offset_left = -400
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	_quest_title = _label(20, HORIZONTAL_ALIGNMENT_RIGHT)
	_quest_title.label_settings.font_color = Color("f2c14e")
	_quest_text = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_mission = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_conquest = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_conquest.label_settings.font_color = Color("ff9a8a")
	_gold_label = _label(18, HORIZONTAL_ALIGNMENT_RIGHT)
	_gold_label.label_settings.font_color = Color("f2c14e")
	_gold_row = _icon_row(_gold_label, "coin")
	_gold_row.visible = false
	# Shrine blessings still running, with the seconds left.
	_bless_label = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	for line: Label in [_quest_title, _quest_text, _mission, _conquest, _bless_label]:
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.visible = false
		column.add_child(line)
	column.add_child(_gold_row)
	column.move_child(_gold_row, 0)

	_inventory = InventoryBar.new()
	add_child(_inventory)

	_debug_label = _label(14, HORIZONTAL_ALIGNMENT_LEFT)
	_debug_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_debug_label.offset_left = 10
	_debug_label.offset_top = -28
	_debug_label.visible = OS.is_debug_build()
	add_child(_debug_label)

	_pause_overlay = _overlay(["PAUSE_TITLE"])
	var pause_box := _pause_overlay.get_node("Box")
	var resume := UiStyle.button("PAUSE_RESUME", 400)
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	var open_settings := UiStyle.button("MENU_SETTINGS", 400)
	open_settings.pressed.connect(func() -> void:
		_pause_overlay.visible = false
		settings.open())
	var give_up := UiStyle.button("PAUSE_GIVE_UP", 400, 20)
	_give_up = give_up
	# Asks once more first: a stray click or key must not end the night.
	give_up.pressed.connect(func() -> void:
		if give_up.text == "PAUSE_GIVE_UP_SURE":
			give_up_pressed.emit()
		else:
			give_up.text = "PAUSE_GIVE_UP_SURE"
			resume.grab_focus())
	_discard = UiStyle.button("PAUSE_DISCARD_BUTTON", 400, 20)
	_discard.pressed.connect(func() -> void: discard_pressed.emit())
	# How many throws are left, quietly at the button's right end.
	_discard_left = UiStyle.side_note(_discard, "")
	# The buttons in a column of their own: all as wide as the widest.
	var pause_buttons := VBoxContainer.new()
	pause_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pause_buttons.add_theme_constant_override("separation", 9)
	for b: Button in [resume, open_settings, _discard, give_up]:
		pause_buttons.add_child(b)
	pause_box.add_child(pause_buttons)
	# This map's stories, one row each with its steps.
	_pause_stories_panel = PanelContainer.new()
	var stories_sb := UiStyle.frame(Color(0.13, 0.1, 0.17, 0.96), Color("4b3d61"), 2)
	stories_sb.set_content_margin_all(14)
	_pause_stories_panel.add_theme_stylebox_override("panel", stories_sb)
	_pause_stories_panel.custom_minimum_size.x = 400
	_pause_stories_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pause_stories = VBoxContainer.new()
	_pause_stories.add_theme_constant_override("separation", 6)
	_pause_stories_panel.add_child(_pause_stories)
	pause_box.add_child(_pause_stories_panel)
	_pause_resume = resume
	# Shortcuts as key caps in one quiet row at the bottom.
	var keys := HBoxContainer.new()
	keys.alignment = BoxContainer.ALIGNMENT_CENTER
	keys.add_theme_constant_override("separation", 14)
	pause_box.add_child(keys)
	_pause_language = _key_item(keys, "L")
	_pause_sound = _key_item(keys, "M")
	_pause_numbers = _key_item(keys, "N")
	_pause_shake = _key_item(keys, "K")
	_pause_weapons = _pause_side("PAUSE_WEAPONS", true)
	_pause_log = _pause_side("PAUSE_LOG", false)

	settings = SettingsPanel.new()
	add_child(settings)
	settings.closed.connect(func() -> void: show_pause(true))

	# Red edges when the cat gets hurt.
	_hurt_flash = ColorRect.new()
	_hurt_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float strength = 0.0;
void fragment() {
	float d = distance(UV, vec2(0.5));
	COLOR = vec4(0.85, 0.05, 0.05, smoothstep(0.35, 0.75, d) * strength);
}
"""
	mat.shader = shader
	_hurt_flash.material = mat
	add_child(_hurt_flash)
	move_child(_hurt_flash, 0)
	_over_overlay = _overlay(["GAME_OVER_TITLE", "", "GAME_OVER_HINT", "GAME_OVER_MENU"])
	_over_stats = _over_overlay.get_node("Box").get_child(1)

	_win_overlay = _overlay(["VICTORY_TITLE", "", "ENDLESS_HINT", "VICTORY_HINT", "GAME_OVER_MENU"])
	var endless_hint := _win_overlay.get_node("Box").get_child(2) as Label
	endless_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	endless_hint.custom_minimum_size = Vector2(900, 0)
	endless_hint.label_settings.font_size = 20
	_extract_overlay = _overlay(["EXTRACT_TITLE", "", "VICTORY_HINT", "GAME_OVER_MENU"])
	_win_stats = _win_overlay.get_node("Box").get_child(1)

	# Messages in a dark pill under the clock, small enough not to hide the fight.
	_banner_box = PanelContainer.new()
	var banner_sb := StyleBoxFlat.new()
	banner_sb.bg_color = Color(0.07, 0.04, 0.08, 0.8)
	banner_sb.border_color = Color("9c4a44")
	banner_sb.set_border_width_all(1)
	banner_sb.set_corner_radius_all(8)
	banner_sb.content_margin_left = 14
	banner_sb.content_margin_right = 14
	banner_sb.content_margin_top = 3
	banner_sb.content_margin_bottom = 4
	_banner_box.add_theme_stylebox_override("panel", banner_sb)
	_banner_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner_box.offset_top = 86
	_banner_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_box.visible = false
	add_child(_banner_box)
	_banner = _label(17, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.label_settings.font_color = Color("ffc2bb")
	_banner.label_settings.outline_size = 0
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_box.add_child(_banner)

	_quest_arrow = QuestArrow.new()
	add_child(_quest_arrow)
	move_child(_quest_arrow, 0)
	var boss_arrows := BossArrows.new()
	add_child(boss_arrows)
	move_child(boss_arrows, 0)
	_extract_arrow = QuestArrow.new()
	_extract_arrow.color = Color("6cd48a")
	add_child(_extract_arrow)
	move_child(_extract_arrow, 0)
	_page_arrow = QuestArrow.new()
	_page_arrow.color = Color("efe2c0")
	add_child(_page_arrow)
	move_child(_page_arrow, 0)
	# In the right column, so a long quest or blessing line pushes it down
	# instead of running under it.
	_extract_label = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_extract_label.label_settings.font_color = Color("8ee07a")
	_extract_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_extract_row = _icon_row(_extract_label, "door")
	_extract_row.visible = false
	column.add_child(_extract_row)
	column.move_child(_extract_row, 1)

	_boss_bar = ColorRect.new()
	_boss_bar.color = Color("2b1d14")
	_boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_bar.offset_left = -300
	_boss_bar.offset_right = 300
	_boss_bar.offset_top = -46
	_boss_bar.offset_bottom = -26
	_boss_bar.visible = false
	add_child(_boss_bar)
	_boss_fill = ColorRect.new()
	_boss_fill.color = Color("c94f4f")
	_boss_fill.position = Vector2(3, 3)
	_boss_fill.size = Vector2(594, 14)
	_boss_bar.add_child(_boss_fill)
	_boss_name = _label(20, HORIZONTAL_ALIGNMENT_CENTER)
	_boss_name.position = Vector2(0, -30)
	_boss_name.size = Vector2(600, 26)
	_boss_bar.add_child(_boss_name)

	level_up = LevelUpPanel.new()
	add_child(level_up)
	treasure = TreasurePanel.new()
	add_child(treasure)
	choice = ChoicePanel.new()
	add_child(choice)


var _hurt := 0.0


## Below this share of health the screen edge keeps pulsing red.
const LOW_HP := 0.3
var _low_t := 0.0


func flash_hurt() -> void:
	_hurt = 0.7


func _process(delta: float) -> void:
	_scroll_summary(delta)
	_low_t += delta
	# Low health: the red edge pulses until the cat is out of danger.
	var low := 0.0
	var cat: Variant = get_parent().get("player")
	if cat != null and is_instance_valid(cat) and not cat.is_dead and cat.hp < cat.max_hp * LOW_HP:
		low = 0.25 + 0.15 * sin(_low_t * 6.0)
	if _hurt > 0.0 or low > 0.0 or (_hurt_flash.material as ShaderMaterial).get_shader_parameter("strength") != 0.0:
		_hurt = maxf(_hurt - delta * 2.5, 0.0)
		(_hurt_flash.material as ShaderMaterial).set_shader_parameter("strength", maxf(_hurt, low))
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner_box.modulate.a = clampf(_banner_time, 0.0, 1.0)
	# Hidden while paused: it would sit on the pause title.
	_banner_box.visible = _banner_time > 0.0 and not _pause_overlay.visible and not get_tree().paused
	if cat != null and is_instance_valid(cat):
		_hp_fill.size.x = 150.0 * clampf(cat.hp / maxf(cat.max_hp, 1.0), 0.0, 1.0)
		_hp_label.text = "%d / %d" % [ceili(cat.hp), roundi(cat.max_hp)]
	_update_night()


## Shows the active quest (or hides the tracker when `quest` is null).
func update_quest(quest: Quest) -> void:
	if quest == null:
		_quest_title.visible = false
		_quest_text.visible = false
		_quest_arrow.target = null
		return
	_quest_title.text = quest.title()
	_quest_text.text = quest.objective()
	_quest_title.visible = _quest_title.text != ""
	_quest_text.visible = _quest_text.text != ""
	_quest_arrow.target = quest.target_position()


## The night offer's line ("" hides it): gold while it is still to do,
## green once it is done.
func set_mission(text: String, done: bool) -> void:
	_mission.text = text
	_mission.visible = text != ""
	_mission.label_settings.font_color = Color("8fe08a") if done else Color("f2c14e")


## The conquest line under the quest ("" hides it).
func set_conquest(text: String) -> void:
	_conquest.text = text
	_conquest.visible = text != ""


## Big health bar for the final boss (null hides it).
func update_boss(boss: Enemy) -> void:
	_boss_bar.visible = boss != null
	if boss == null:
		return
	_boss_fill.size.x = 594.0 * clampf(boss.hp / boss.max_hp, 0.0, 1.0)
	_boss_name.text = tr("ENEMY_%s_NAME" % boss.id)
	if boss.has_meta("nemesis"):
		_boss_name.text += "  –  " + tr("NEMESIS_TITLE_%d" % int(boss.get_meta("nemesis")))


## Big warning text below the clock that fades out after `seconds`.
## Long texts stay up longer, and every text goes to the pause log.
func show_banner(text: String, seconds: float = 3.0) -> void:
	_banner.text = text
	# Short lines stay one line; long ones wrap at a readable width.
	var widest := 0.0
	for line in text.split("\n"):
		widest = maxf(widest, ThemeDB.fallback_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x)
	_banner.custom_minimum_size.x = minf(widest + 6.0, 620.0)
	_banner_box.reset_size()
	_center_banner.call_deferred()
	_banner_time = maxf(seconds, 2.0 + text.length() * 0.06)
	if text != "" and (_log.is_empty() or _log[0][1] != text):
		var spawner: Variant = get_parent().get("spawner")
		_log.push_front([_format_time(spawner.elapsed) if spawner != null and is_instance_valid(spawner) else "", text])
		if _log.size() > LOG_SIZE:
			_log.pop_back()


## Hides the end screens (and their summary lines) when the night goes on.
func hide_end_screens() -> void:
	if _end != null:
		_end.visible = false
	for overlay: Control in [_over_overlay, _win_overlay, _extract_overlay]:
		overlay.visible = false
		var box := overlay.get_node("Box")
		for child in box.get_children():
			if child.has_meta("summary"):
				child.queue_free()


func show_victory(kills: int, cat_name: String = "") -> void:
	_win_stats.text = tr("VICTORY_STATS") % [cat_name, kills]
	_win_overlay.visible = true


func update_xp(player: Player) -> void:
	var bar_width := get_viewport().get_visible_rect().size.x
	_xp_fill.size.x = bar_width * clampf(player.xp / player.xp_to_next(), 0.0, 1.0)
	_level_label.text = tr("HUD_LEVEL") % player.level


func update_inventory(player: Player) -> void:
	_inventory.player = player
	_inventory.refresh()


func update_blessings(player: Player) -> void:
	var parts: Array[String] = []
	var color := Color.WHITE
	for b in player.blessings:
		if String(b.get("label", "")) == "":
			continue
		# Bonuses for the rest of the night show no countdown.
		if float(b["t"]) > 3600.0:
			parts.append(tr(b["label"]))
		else:
			parts.append("%s %s" % [tr(b["label"]), tr("CHAIN_TIME") % ceili(float(b["t"]))])
		color = b["color"]
	_bless_label.text = "  ·  ".join(parts)
	_bless_label.visible = not parts.is_empty()
	_bless_label.label_settings.font_color = color.lightened(0.3)


func update_gold(amount: int, charms: int = 0) -> void:
	_gold_row.visible = true
	_gold_label.text = Hud.thousands(amount)
	if charms > 0:
		_gold_label.text += "  ·  " + tr("HUD_CHARMS") % charms


## Gold and streak lines on whichever end screen is showing. A long list
## (many goals and stories done in one night) goes into a scrolling box so
## the rest of the screen stays readable; the last line (total gold) stays
## outside it.
func show_summary(lines: Array[String]) -> void:
	for overlay: Control in [_over_overlay, _win_overlay, _extract_overlay]:
		if not overlay.visible:
			continue
		var box := overlay.get_node("Box")
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.set_meta("summary", true)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 4)
		scroll.add_child(list)
		var width := minf(get_viewport().get_visible_rect().size.x - 80.0, 1000.0)
		var height := 0.0
		for i in lines.size() - 1:
			var line := _label(20, HORIZONTAL_ALIGNMENT_CENTER)
			line.text = lines[i]
			line.label_settings.font_color = Color("f2c14e")
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.custom_minimum_size = Vector2(width, 0)
			list.add_child(line)
			height += 30.0 * (1 + floori(lines[i].length() * 11.0 / width))
		scroll.custom_minimum_size = Vector2(width + 16.0, minf(height, get_viewport().get_visible_rect().size.y * 0.38))
		box.add_child(scroll)
		box.move_child(scroll, 2)
		_summary_scroll = scroll
		if not lines.is_empty():
			var total := _label(24, HORIZONTAL_ALIGNMENT_CENTER)
			total.text = lines[-1]
			total.label_settings.font_color = Color("f2c14e")
			total.set_meta("summary", true)
			box.add_child(total)
			box.move_child(total, 3)


## The end screen's summary box, scrolled with up/down or the wheel.
var _summary_scroll: ScrollContainer

## The end of a night, one page at a time: the title and the night's numbers,
## then what you achieved, then what you take home. Each page is
## {"title", "lines", "total", "color"}.
var _end: ColorRect
var _end_pages: Array = []
var _end_page := 0
var _end_endless := false
## The night in numbers for the end screen's first page, set by main before
## show_end: kills, time (s), level, gold found, and the cat's line.
var end_facts := {}


## Shows the end of the night from its first page (see _end_pages).
func show_end(title: String, stats: String, deeds: Array[String], loot: Array[String], total: String, endless: bool) -> void:
	_banner_time = 0.0
	_banner_box.visible = false
	_end_endless = endless
	_end_pages = [{"title": title, "lines": [stats], "total": "", "big": true}]
	if not deeds.is_empty():
		_end_pages.append({"title": tr("END_DEEDS"), "lines": deeds, "total": ""})
	_end_pages.append({"title": tr("END_LOOT"), "lines": loot, "total": total})
	_end_page = 0
	if _end == null:
		_end = ColorRect.new()
		_end.color = Color(0.08, 0.05, 0.1, 0.92)
		_end.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_end.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_end)
	_end.visible = true
	_show_end_page()


func end_showing() -> bool:
	return _end != null and _end.visible


## Turns to the next page; false when this already is the last one.
func next_end_page() -> bool:
	if not end_showing() or _end_page >= _end_pages.size() - 1:
		return false
	_end_page += 1
	_show_end_page()
	return true


func end_page() -> int:
	return _end_page


func _show_end_page() -> void:
	for child in _end.get_children():
		child.queue_free()
	var page: Dictionary = _end_pages[_end_page]
	var big: bool = page.get("big", false)
	var view := get_viewport().get_visible_rect().size
	var panel := PanelContainer.new()
	var sb := UiStyle.frame(Color(0.13, 0.1, 0.17, 0.97), Color("4b3d61"), 2)
	sb.set_content_margin_all(26)
	sb.content_margin_top = 18
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size.x = minf(780.0, view.x - 60.0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var width := panel.custom_minimum_size.x - 52.0
	# Page dots.
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 7)
	for i in _end_pages.size():
		var dot := Panel.new()
		var dsb := StyleBoxFlat.new()
		dsb.set_corner_radius_all(4)
		dsb.bg_color = UiStyle.GOLD if i == _end_page else Color(0, 0, 0, 0)
		dsb.border_color = UiStyle.GOLD if i == _end_page else Color("7a6a93")
		dsb.set_border_width_all(2)
		dot.add_theme_stylebox_override("panel", dsb)
		dot.custom_minimum_size = Vector2(9, 9)
		dots.add_child(dot)
	box.add_child(dots)
	var title := _label(42 if big else 30, HORIZONTAL_ALIGNMENT_CENTER)
	title.text = page["title"]
	title.label_settings.font_color = UiStyle.GOLD if big else Color.WHITE
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = width
	box.add_child(title)
	if big:
		_end_numbers(box, page, width)
	else:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 6)
		scroll.add_child(list)
		var height := 0.0
		for text: String in page["lines"]:
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UiStyle.card())
			var line := UiStyle.plain(text, 16, Color("f1e6c8"), true)
			line.custom_minimum_size.x = width - 40.0
			card.add_child(line)
			list.add_child(card)
			height += 18.0 * (1 + floori(text.length() * 16.0 * 0.55 / (width - 40.0))) + 26.0
		scroll.custom_minimum_size = Vector2(width, minf(height, view.y * 0.48))
		box.add_child(scroll)
		_summary_scroll = scroll
		if page["total"] != "":
			var total := UiStyle.plain(page["total"], 22, UiStyle.GOLD)
			total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(total)
	# Buttons with their keys, clickable too.
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	if _end_page < _end_pages.size() - 1:
		_end_button(buttons, "END_NEXT", "Enter", "next", true)
	else:
		_end_button(buttons, "END_AGAIN_BUTTON", "R", "again", true)
		_end_button(buttons, "END_BACK_BUTTON", "Esc", "back", false)
	if _end_page == 0 and _end_endless:
		_end_button(buttons, "END_ENDLESS_BUTTON", "E", "endless", false)
		var hint_text := tr("ENDLESS_HINT")
		if hint_text.begins_with("E") and "–" in hint_text.substr(0, 4):
			hint_text = hint_text.substr(hint_text.find("–") + 1).strip_edges()
		var hint := UiStyle.plain(hint_text.left(1).to_upper() + hint_text.substr(1), 13, UiStyle.MUTED, true)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.custom_minimum_size.x = width
		box.add_child(hint)
	(buttons.get_child(0) as Button).grab_focus.call_deferred()


## The first end page: the cat's line, four numbers and which weapons did
## the most damage tonight.
func _end_numbers(box: VBoxContainer, page: Dictionary, width: float) -> void:
	var sub := UiStyle.plain(page["lines"][0] if not (page["lines"] as Array).is_empty() else "", 16, Color("cfc3dd"), true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.custom_minimum_size.x = width
	box.add_child(sub)
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 10)
	box.add_child(tiles)
	_end_tile(tiles, "END_KILLS", Hud.thousands(int(end_facts.get("kills", 0))), UiStyle.TEXT)
	_end_tile(tiles, "END_TIME", _format_time(float(end_facts.get("time", 0.0))), UiStyle.TEXT)
	_end_tile(tiles, "END_LEVEL", str(int(end_facts.get("level", 1))), UiStyle.TEXT)
	_end_tile(tiles, "END_GOLD", Hud.thousands(int(end_facts.get("gold", 0))), UiStyle.GOLD)
	# Damage by weapon, the biggest four, as shares of all damage.
	var total := 0.0
	var ids: Array = []
	for id: String in Weapon.damage_log:
		total += float(Weapon.damage_log[id])
		ids.append(id)
	if total <= 0.0:
		return
	ids.sort_custom(func(a: String, b: String) -> bool: return float(Weapon.damage_log[a]) > float(Weapon.damage_log[b]))
	box.add_child(UiStyle.plain(tr("END_DAMAGE"), 15, UiStyle.GOLD))
	var best := float(Weapon.damage_log[ids[0]]) / total
	for id: String in ids.slice(0, 4):
		var share := float(Weapon.damage_log[id]) / total
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		if GameData.weapons.has(id):
			row.add_child(IconView.new("weapon", id, 26))
		var name_label := UiStyle.plain(Upgrades.item_name("weapon", id) if GameData.weapons.has(id) else id, 15)
		name_label.custom_minimum_size.x = 190
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(name_label)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.max_value = best
		bar.value = share
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("2c2338")
		bg.set_corner_radius_all(4)
		var fill := StyleBoxFlat.new()
		fill.bg_color = UiStyle.GOLD
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fill)
		row.add_child(bar)
		var pct := UiStyle.plain("%d %%" % roundi(share * 100.0), 14)
		pct.custom_minimum_size.x = 48
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(pct)
		box.add_child(row)


func _end_tile(row: HBoxContainer, key: String, value: String, color: Color) -> void:
	var tile := PanelContainer.new()
	tile.add_theme_stylebox_override("panel", UiStyle.card())
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	tile.add_child(col)
	col.add_child(UiStyle.plain(tr(key).to_upper(), 12, UiStyle.MUTED))
	col.add_child(UiStyle.plain(value, 28, color))
	row.add_child(tile)


func _end_button(row: HBoxContainer, text: String, key: String, action: String, first: bool) -> void:
	var b := UiStyle.button(text, 0, 19)
	b.custom_minimum_size = Vector2(200, 46)
	UiStyle.add_key(b, key)
	b.pressed.connect(func() -> void: end_action.emit(action))
	if first:
		b.add_theme_color_override("font_color", UiStyle.GOLD)
	row.add_child(b)


func _scroll_summary(delta: float) -> void:
	if not is_instance_valid(_summary_scroll) or not _summary_scroll.is_visible_in_tree():
		return
	var axis := Input.get_axis("ui_up", "ui_down")
	if axis != 0.0:
		_summary_scroll.scroll_vertical += roundi(axis * 500.0 * delta)


func show_extracted(elapsed: float, kills: int) -> void:
	(_extract_overlay.get_node("Box").get_child(1) as Label).text = tr("EXTRACT_STATS") % [_format_time(elapsed), kills]
	_extract_overlay.visible = true


## Arrow to the diary page lying on the map (null hides it).
func update_page(pos: Variant) -> void:
	_page_arrow.target = pos


## Countdown and arrow for an open cat flap (null hides them).
func update_extraction(flap: Extraction) -> void:
	_extract_row.visible = flap != null
	if flap == null:
		_extract_label.text = ""
		_extract_arrow.target = null
		return
	_extract_label.text = tr("EXTRACT_TRACKER") % ceili(flap.time_left)
	_extract_arrow.target = flap.position


## Extra line for the debug label (spawn budget), set by main.
var debug_extra := ""


func update_stats(elapsed: float, kills: int, enemy_count: int) -> void:
	_time_label.text = _format_time(elapsed)
	_kills_label.text = Hud.thousands(kills)
	if _debug_label.visible:
		_debug_label.text = "FPS %d · enemies %d%s" % [Engine.get_frames_per_second(), enemy_count, debug_extra]


func show_pause(on: bool) -> void:
	_pause_language.text = tr("LANGUAGE_NAME")
	_pause_sound.text = tr("PAUSE_KEY_SOUND") % tr("SOUND_OFF" if Settings.muted else "SOUND_ON")
	_pause_numbers.text = tr("PAUSE_KEY_NUMBERS") % tr("SOUND_ON" if Settings.damage_numbers else "SOUND_OFF")
	_pause_shake.text = tr("PAUSE_KEY_SHAKE") % tr("SOUND_ON" if Settings.screen_shake else "SOUND_OFF")
	_fill_stories()
	_give_up.text = "PAUSE_GIVE_UP"
	var cat: Player = get_parent().get("player")
	_discard.visible = cat != null and cat.discard_left > 0
	if cat != null:
		_discard_left.text = tr("PAUSE_LEFT") % cat.discard_left
	if on:
		_fill_weapons(cat)
		_fill_log()
		_fit_side(_pause_weapons)
		_fit_side(_pause_log)
	_pause_overlay.visible = on
	if on:
		_pause_resume.grab_focus.call_deferred()


## A key cap and its setting ("M  Sound on") in the pause screen's key row.
func _key_item(row: HBoxContainer, key: String) -> Label:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 6)
	item.add_child(UiStyle.key_cap(key))
	var l := UiStyle.plain("", 14, UiStyle.MUTED)
	item.add_child(l)
	row.add_child(item)
	return l


## The left pause panel: a card per weapon, then the skills and shrine bonuses.
func _fill_weapons(player: Player) -> void:
	for child in _pause_weapons.get_children():
		child.queue_free()
	if player == null:
		return
	var weapons: Array = player.weapons.get_children().filter(func(w: Node) -> bool: return w is Weapon)
	_pause_weapons.add_child(_side_head(tr("PAUSE_WEAPONS"), "%d / %d" % [weapons.size(), player.max_weapons()]))
	for w: Weapon in weapons:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyle.card())
		card.tooltip_text = tr("WEAPON_%s_DESC" % w.id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		row.add_child(IconView.new("weapon", w.id, 44))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		var top := HBoxContainer.new()
		col.add_child(top)
		var name_label := UiStyle.plain(Upgrades.item_name("weapon", w.id), 16, UiStyle.GOLD)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		top.add_child(name_label)
		var maxed := w.level >= w.max_level()
		top.add_child(UiStyle.plain(("★ " if maxed else "") + "%d/%d" % [w.level, w.max_level()], 12, UiStyle.GOLD if maxed else UiStyle.MUTED))
		if w.branch != "":
			col.add_child(UiStyle.plain("%s %d" % [tr("BRANCH_%s_NAME" % w.branch), w.branch_rank], 13, Color("a6dc98")))
		var evolve: Dictionary = w.data.get("evolve", {})
		if not evolve.is_empty():
			var has: bool = player.passives.has(evolve["with"])
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 5)
			line.add_child(IconView.new("passive", evolve["with"], 16))
			line.add_child(UiStyle.plain(tr("PAUSE_EVOLVE_WITH") % Upgrades.item_name("passive", evolve["with"]), 12, Color("a6dc98") if has else UiStyle.MUTED))
			col.add_child(line)
		_pause_weapons.add_child(card)
	if not player.passives.is_empty():
		_pause_weapons.add_child(_side_head(tr("PAUSE_SKILLS"), "%d / %d" % [player.passives.size(), Player.MAX_PASSIVES]))
		for id: String in player.passives:
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UiStyle.card())
			card.tooltip_text = tr("PASSIVE_%s_DESC" % id)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			card.add_child(row)
			row.add_child(IconView.new("passive", id, 28))
			var name_label := UiStyle.plain(Upgrades.item_name("passive", id), 15)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			row.add_child(name_label)
			row.add_child(UiStyle.segments((GameData.passives[id]["levels"] as Array).size(), int(player.passives[id]), 12, 6))
			_pause_weapons.add_child(card)
	var bless := blessings_text()
	if bless != "":
		var text := RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.scroll_active = false
		text.add_theme_font_size_override("normal_font_size", 14)
		text.text = bless.strip_edges()
		_pause_weapons.add_child(text)


## The right pause panel: what is going on now, then the messages with times.
func _fill_log() -> void:
	for child in _pause_log.get_children():
		child.queue_free()
	_pause_log.add_child(_side_head(tr("PAUSE_NOW"), ""))
	var now := 0
	if _quest_title.visible:
		_pause_log.add_child(_now_card(_quest_title.text, _quest_text.text, UiStyle.GOLD, Color("6a5784"), ""))
		now += 1
	if _mission.visible:
		_pause_log.add_child(_now_card(_mission.text, "", _mission.label_settings.font_color, Color("6a5784"), ""))
		now += 1
	if _conquest.visible:
		_pause_log.add_child(_now_card(_conquest.text, "", Color("ff9a8a"), Color("7a4a4a"), ""))
		now += 1
	if _extract_row.visible:
		_pause_log.add_child(_now_card(_extract_label.text, "", UiStyle.GREEN, Color("4c7a43"), "door"))
		now += 1
	if now == 0:
		_pause_log.add_child(UiStyle.plain(tr("PAUSE_LOG_EMPTY"), 14, UiStyle.MUTED))
	_pause_log.add_child(_side_head(tr("PAUSE_NEWS"), ""))
	if _log.is_empty():
		_pause_log.add_child(UiStyle.plain(tr("PAUSE_LOG_EMPTY"), 14, UiStyle.MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	_pause_log.add_child(grid)
	for entry: Array in _log:
		var t := UiStyle.plain(entry[0], 12, UiStyle.MUTED)
		t.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		grid.add_child(t)
		var l := UiStyle.plain(entry[1], 14, UiStyle.TEXT, true)
		l.custom_minimum_size.x = 260
		grid.add_child(l)


## A small card in the right pause panel (the quest now, an open cat flap).
func _now_card(title: String, body: String, color: Color, border: Color, glyph: String) -> PanelContainer:
	var card := PanelContainer.new()
	var sb := UiStyle.card()
	sb.border_color = border
	card.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	if glyph != "":
		var g := PixelGlyph.rect(glyph, 3)
		g.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(g)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var head := UiStyle.plain(title, 15, color, true)
	col.add_child(head)
	if body != "":
		col.add_child(UiStyle.plain(body, 14, Color("cfc3dd"), true))
	return card


## A panel heading with an optional count at its right ("Your weapons  4 / 6").
func _side_head(title: String, count: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var t := UiStyle.plain(title, 18, UiStyle.GOLD)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	if count != "":
		row.add_child(UiStyle.plain(count, 13, UiStyle.MUTED))
	return row


## The middle panel under the pause buttons: this map's stories with their steps.
func _fill_stories() -> void:
	for child in _pause_stories.get_children():
		child.queue_free()
	var spawner: Variant = get_parent().get("spawner")
	var rows := 0
	if spawner != null:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 6)
		for id: String in GameData.chains:
			if GameData.chains[id].get("stage", "any") != spawner.stage_id or (GameData.chains[id].has("secret") and ChainStep.progress_of(id) == 0):
				continue
			var n := ChainStep.steps(id).size()
			var done := ChainStep.progress_of(id)
			var name_label := UiStyle.plain(tr("CHAIN_%s_NAME" % id), 15, UiStyle.GREEN if done >= n else UiStyle.TEXT)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(name_label)
			grid.add_child(UiStyle.segments(n, done, 14, 6))
			var count := UiStyle.plain("✓" if done >= n else "%d/%d" % [done, n], 13, UiStyle.MUTED)
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count.custom_minimum_size.x = 30
			grid.add_child(count)
			rows += 1
		if rows > 0:
			_pause_stories.add_child(UiStyle.plain(tr("PAUSE_MAP_STORIES"), 15, UiStyle.GOLD))
			_pause_stories.add_child(grid)
		else:
			grid.free()
	_pause_stories_panel.visible = rows > 0


## Shrine bonuses still running (what each gave, and for how long), as
## BBCode under the weapons in the pause screen.
func blessings_text() -> String:
	var cat: Variant = get_parent().get("player")
	if cat == null or not is_instance_valid(cat):
		return ""
	var lines: Array[String] = []
	for b in (cat as Player).blessings:
		if String(b.get("label", "")) == "":
			continue
		var left: String = tr("BLESS_ALL_NIGHT") if float(b["t"]) > 3600.0 else tr("CHAIN_TIME") % ceili(float(b["t"]))
		var line := "[color=#%s]%s[/color]  %s" % [(b["color"] as Color).lightened(0.3).to_html(false), tr(b["label"]), left]
		if String(b.get("desc", "")) != "":
			line += "
" + String(b["desc"])
		lines.append(line)
	if lines.is_empty():
		return ""
	return "

[color=#%s]%s[/color]
%s" % [UiStyle.GOLD.to_html(false), tr("PAUSE_BLESSINGS"), "

".join(lines)]


## The cat's weapons (level, branch, what they do, which passive evolves
## them) and passives, as BBCode. `columns` lays the weapons out in a table
## (the level-up screen has little height); ids in `highlight` (what a
## card or chest touches) are marked.
func weapons_text(columns: int = 1, highlight: Array = []) -> String:
	var cat: Variant = get_parent().get("player")
	if cat == null or not is_instance_valid(cat):
		return ""
	var player := cat as Player
	var gold := UiStyle.GOLD.to_html(false)
	var muted := UiStyle.MUTED.to_html(false)
	var parts: Array[String] = []
	var marked := 0
	for w in player.weapons.get_children():
		if not w is Weapon:
			continue
		var line := "[color=#%s]%s%s[/color]  %s" % [gold, "» " if w.id in highlight else "", Upgrades.item_name("weapon", w.id), tr("HUD_WEAPON_LEVEL") % [w.level, w.max_level()]]
		line += "\n" + tr("WEAPON_%s_DESC" % w.id)
		if w.branch != "":
			line += "\n[color=#%s]%s %d: %s[/color]" % [muted, tr("BRANCH_%s_NAME" % w.branch), w.branch_rank, tr("BRANCH_%s_DESC" % w.branch)]
		var evolve: Dictionary = w.data.get("evolve", {})
		if not evolve.is_empty():
			var has: bool = player.passives.has(evolve["with"])
			line += "\n[color=#%s]%s[/color]" % ["8fdc8f" if has else muted, tr("INV_EVOLVE_HAVE" if has else "INV_EVOLVE_NEED") % Upgrades.item_name("passive", evolve["with"])]
		# What the card or chest touches goes first, so it is seen without scrolling.
		if w.id in highlight:
			parts.insert(marked, line)
			marked += 1
		else:
			parts.append(line)
	var passives: Array[String] = []
	for id: String in player.passives:
		var text := "%s %d" % [Upgrades.item_name("passive", id), player.passives[id]]
		passives.append("[color=#%s]» %s[/color]" % [gold, text] if id in highlight else text)
	var passive_line := "[color=#%s]%s[/color]" % [muted, ", ".join(passives)] if not passives.is_empty() else ""
	if columns > 1 and not parts.is_empty():
		var cells := ""
		for p in parts:
			cells += "[cell padding=0,0,16,8]%s[/cell]" % p
		for i in (columns - parts.size() % columns) % columns:
			cells += "[cell][/cell]"
		return "%s[table=%d]%s[/table]" % [passive_line + "\n" if passive_line != "" else "", columns, cells]
	if passive_line != "":
		parts.append(passive_line)
	return "\n\n".join(parts)


## A framed, scrollable column at one side of the pause screen; returns
## the box the cards go into.
func _pause_side(_title_key: String, left: bool) -> VBoxContainer:
	var panel := PanelContainer.new()
	var sb := UiStyle.frame(Color(0.13, 0.1, 0.17, 0.96), Color("4b3d61"), 2)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE if left else Control.PRESET_RIGHT_WIDE)
	panel.offset_top = 36
	panel.offset_bottom = -36
	if left:
		panel.offset_left = 20
		panel.offset_right = 370
	else:
		panel.offset_left = -370
		panel.offset_right = -20
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	_pause_overlay.add_child(panel)
	return box


## `title` is already translated (the cat's name, or the devil's line).
func show_game_over(elapsed: float, kills: int, title: String) -> void:
	(_over_overlay.get_node("Box").get_child(0) as Label).text = title
	_over_stats.text = tr("GAME_OVER_STATS") % [_format_time(elapsed), kills]
	_over_overlay.visible = true


## Keeps the banner pill centred under the clock whatever its width.
func _center_banner() -> void:
	_banner_box.reset_size()
	var w := _banner_box.size.x
	_banner_box.offset_left = -w / 2.0
	_banner_box.offset_right = w / 2.0


## Shrinks a pause side panel to its content (up to the full height), deferred
## so wrapped lines have their size.
func _fit_side(box: VBoxContainer) -> void:
	# Two frames: the old cards are gone and the new ones are laid out.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(box):
		return
	var panel := box.get_parent().get_parent() as PanelContainer
	var view := get_viewport().get_visible_rect().size.y
	var h := 28.0
	for child in box.get_children():
		if child is Control and (child as Control).visible:
			h = maxf(h, (child as Control).position.y + (child as Control).size.y + 28.0)
	panel.offset_bottom = -maxf(view - 36.0 - h, 36.0)


## A label with a small pixel icon after it, right aligned (kills, gold...).
func _icon_row(label: Label, glyph: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 7)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	row.add_child(PixelGlyph.rect(glyph, 2))
	return row


## 1874 -> "1 874" (a gap between thousands, as in the menus).
static func thousands(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


## The night bar and "next boss in" under the clock (hidden past the night's end).
func _update_night() -> void:
	var spawner: Variant = get_parent().get("spawner")
	if spawner == null or not is_instance_valid(spawner) or _pause_overlay.visible or end_showing():
		_night.visible = false
		_next_boss.visible = false
		return
	var length: float = spawner.duration_minutes() * 60.0
	var t: float = spawner.elapsed
	_night.visible = t < length
	_next_boss.visible = _night.visible
	if not _night.visible:
		return
	if _night.marks.is_empty():
		for w: Dictionary in spawner.stage()["waves"]:
			if not (w.get("bosses", []) as Array).is_empty():
				_night.marks.append(float(w["minute"]) * 60.0 / length)
	_night.progress = t / length
	var next := length
	for m: float in _night.marks:
		if m * length > t + 0.5:
			next = minf(next, m * length)
	var left := ceili(next - t)
	_next_boss.text = tr("HUD_NEXT_BOSS" if next < length else "HUD_FINAL_BOSS") % ("%d:%02d" % [left / 60, left % 60])


func _format_time(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [floori(s / 60.0), s % 60]


func _label(size: int, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.outline_size = maxi(size / 4, 4)
	settings.outline_color = Color("2b1d14")
	label.label_settings = settings
	label.horizontal_alignment = align
	return label


func _overlay(lines: Array[String]) -> Control:
	var root := ColorRect.new()
	root.color = Color(0.08, 0.05, 0.1, 0.6)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	var box := VBoxContainer.new()
	box.name = "Box"
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 12)
	for i in lines.size():
		var label := _label(48 if i == 0 else 24, HORIZONTAL_ALIGNMENT_CENTER)
		label.text = lines[i]
		box.add_child(label)
	root.add_child(box)
	add_child(root)
	return root
