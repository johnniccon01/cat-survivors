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

var _xp_bar: HudBar
var _level_card: HudCard
var _inventory: InventoryBar
var _time_card: HudCard
var _kills_card: HudCard
var _gold_label: Label
var _bless_label: Label
var _debug_label: Label
var _pause_resume: Button
var _pause_overlay: Control
var _give_up: BoxButton
var _discard: Button
var _pause_stories: VBoxContainer
var _pause_stories_panel: BoxPanel
var _pause_language: Label
var _pause_sound: Label
var _pause_numbers: Label
var _pause_shake: Label
## The pause screen's side panels: weapon cards on the left, the quest now
## and the messages on the right (filled each time the game pauses).
var _pause_weapons: VBoxContainer
var _pause_log: VBoxContainer
var _discard_left: TapeTag
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
var _boss_bar: HudBar
var _boss_name: Label
var _banner_time := 0.0
## The banner's dark pill (the label sits inside it).
var _banner_box: PanelContainer
var _hp_bar: HudBar
var _hp_label: Label
var _night: NightBar
var _next_boss: Label
var _gold_row: HBoxContainer
var _extract_row: HBoxContainer


func _ready() -> void:
	# Top: the xp strip across the screen with an uneven end of the fill.
	_xp_bar = HudBar.make("xp", Color("f0a23a"))
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = XP_BAR_HEIGHT
	add_child(_xp_bar)

	# Top left: level card, heart and health bar with the numbers.
	_level_card = HudCard.make(19, 4, -2.0, "left", Vector2(12, 18), 70.0)
	add_child(_level_card)
	var heart := HudIcon.new()
	heart.position = Vector2(94, 20)
	add_child(heart)
	_hp_bar = HudBar.make("bar", Color("e0483f"), 5)
	_hp_bar.shine = false
	_hp_bar.position = Vector2(122, 21)
	_hp_bar.size = Vector2(176, 26)
	add_child(_hp_bar)
	_hp_label = BoxStyle.hud_label(17, HORIZONTAL_ALIGNMENT_CENTER)
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_bar.add_child(_hp_label)

	# The clock on a light card in the middle, the night's bar and "next boss" under it.
	_time_card = HudCard.make(32, 6, 0.8, "center", Vector2(0, 18), 128.0)
	add_child(_time_card)
	_night = NightBar.new()
	_night.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_night.offset_left = -85
	_night.offset_right = 85
	_night.offset_top = 80
	_night.offset_bottom = 87
	add_child(_night)
	_next_boss = BoxStyle.hud_label(15, HORIZONTAL_ALIGNMENT_CENTER)
	_next_boss.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_next_boss.offset_top = 92
	add_child(_next_boss)

	# Right: "Defeated" on a cream tag with a paw.
	_kills_card = HudCard.make(19, 8, 1.4, "right", Vector2(14, 18), 150.0, true)
	add_child(_kills_card)

	# Right column under the kills: quest, gold, blessings stacked so long
	# quest texts push the rest down instead of covering it.
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	column.offset_top = 64
	column.offset_right = -14
	column.offset_left = -400
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	_quest_title = BoxStyle.hud_label(21, HORIZONTAL_ALIGNMENT_RIGHT, Color("f2c14e"), true)
	_quest_text = BoxStyle.hud_label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_mission = BoxStyle.hud_label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_conquest = BoxStyle.hud_label(16, HORIZONTAL_ALIGNMENT_RIGHT, Color("ff9a8a"))
	_gold_label = BoxStyle.hud_label(19, HORIZONTAL_ALIGNMENT_RIGHT, Color("f2c14e"))
	_gold_row = _icon_row(_gold_label, "coin")
	_gold_row.visible = false
	# Shrine blessings still running, with the seconds left.
	_bless_label = BoxStyle.hud_label(16, HORIZONTAL_ALIGNMENT_RIGHT)
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

	_pause_overlay = _overlay([])
	(_pause_overlay as ColorRect).color = Color(0.1, 0.06, 0.03, 0.62)
	var pause_box := _pause_overlay.get_node("Box")
	pause_box.add_theme_constant_override("separation", 12)
	# The title on a piece of cardboard held with tape.
	var title_board := BoxPanel.make("board", 11, Vector4(56, 4, 56, 14), -1.4)
	title_board.add_decor(BoxBoard.make("tape", Vector2.ZERO, Vector2(84, 26), 12), Vector2(0.5, 0), Vector2(-42, -12), Vector2(84, 26), 3.0)
	title_board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_board.add_child(BoxStyle.label("PAUSE_TITLE", 62, BoxStyle.INK, true))
	pause_box.add_child(title_board)
	var resume := BoxButton.make("PAUSE_RESUME", 32, 41, -1.0, true, false, 420.0)
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	var open_settings := BoxButton.make("MENU_SETTINGS", 26, 42, 1.2, true, false, 420.0)
	open_settings.pressed.connect(func() -> void:
		_pause_overlay.visible = false
		settings.open())
	var give_up := BoxButton.make("PAUSE_GIVE_UP", 26, 44, -1.1, true, false, 420.0)
	_give_up = give_up
	# Asks once more first: a stray click or key must not end the night.
	give_up.pressed.connect(func() -> void:
		if give_up.text == "PAUSE_GIVE_UP_SURE":
			give_up_pressed.emit()
		else:
			give_up.relabel("PAUSE_GIVE_UP_SURE")
			resume.grab_focus())
	_discard = BoxButton.make("PAUSE_DISCARD_BUTTON", 26, 43, 0.9, true, false, 420.0)
	_discard.pressed.connect(func() -> void: discard_pressed.emit())
	# How many throws are left, on a strip of tape at the button's corner.
	_discard_left = TapeTag.new()
	_discard.add_child(_discard_left)
	# The buttons in a column of their own: all as wide as the widest.
	var pause_buttons := VBoxContainer.new()
	pause_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pause_buttons.add_theme_constant_override("separation", 10)
	for b: Button in [resume, open_settings, _discard, give_up]:
		pause_buttons.add_child(b)
	pause_box.add_child(pause_buttons)
	# This map's stories on a cream note, one row each with its steps.
	_pause_stories_panel = BoxPanel.make("light", 45, Vector4(24, 10, 24, 16), 0.7)
	_pause_stories_panel.custom_minimum_size.x = 420
	_pause_stories_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pause_stories = VBoxContainer.new()
	_pause_stories.add_theme_constant_override("separation", 2)
	_pause_stories_panel.add_child(_pause_stories)
	pause_box.add_child(_pause_stories_panel)
	_pause_resume = resume
	# Shortcuts as small cardboard chips, two in a row.
	var keys := GridContainer.new()
	keys.columns = 2
	keys.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	keys.add_theme_constant_override("h_separation", 14)
	keys.add_theme_constant_override("v_separation", 8)
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

	# Messages on a red piece of cardboard under the clock, small enough not to hide the fight.
	_banner_box = PanelContainer.new()
	var banner_sb := StyleBoxEmpty.new()
	banner_sb.content_margin_left = 26
	banner_sb.content_margin_right = 26
	banner_sb.content_margin_top = 8
	banner_sb.content_margin_bottom = 10
	_banner_box.add_theme_stylebox_override("panel", banner_sb)
	_banner_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner_box.offset_top = 114
	_banner_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_box.visible = false
	add_child(_banner_box)
	var banner_board := BoxBoard.make("red", Vector2.ZERO, Vector2(10, 10), 12, -1.0)
	_banner_box.add_child(banner_board)
	_banner = BoxStyle.hud_label(18, HORIZONTAL_ALIGNMENT_CENTER, BoxStyle.CREAM, false, Color("5a0f0b"))
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
	_extract_label = BoxStyle.hud_label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_extract_label.label_settings.font_color = Color("8ee07a")
	_extract_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_extract_row = _icon_row(_extract_label, "door")
	_extract_row.visible = false
	column.add_child(_extract_row)
	column.move_child(_extract_row, 1)

	_boss_bar = HudBar.make("bar", Color("e0483f"), 9)
	_boss_bar.paw = true
	_boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_bar.offset_left = -300
	_boss_bar.offset_right = 300
	_boss_bar.offset_top = -50
	_boss_bar.offset_bottom = -22
	_boss_bar.visible = false
	add_child(_boss_bar)
	_boss_name = BoxStyle.hud_label(26, HORIZONTAL_ALIGNMENT_CENTER, BoxStyle.CREAM, true)
	_boss_name.position = Vector2(0, -38)
	_boss_name.size = Vector2(600, 34)
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
		_hp_bar.value = cat.hp / maxf(cat.max_hp, 1.0)
		var hp_text := "%d / %d" % [ceili(cat.hp), roundi(cat.max_hp)]
		if _hp_label.text != hp_text:
			_hp_label.text = hp_text
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
	_boss_bar.value = boss.hp / boss.max_hp
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
		widest = maxf(widest, BoxStyle.bold_font().get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x)
	var bw := minf(widest + 12.0, 620.0)
	_banner.autowrap_mode = TextServer.AUTOWRAP_OFF if text.find("
") < 0 and widest + 12.0 <= 620.0 else TextServer.AUTOWRAP_WORD_SMART
	_banner.custom_minimum_size = Vector2(bw, BoxStyle.bold_font().get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, bw, 18).y + 4.0)
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

	_xp_bar.value = player.xp / player.xp_to_next()
	_level_card.set_text(tr("HUD_LEVEL") % player.level)


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
		_end.color = Color(0.1, 0.06, 0.03, 0.66)
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
	var width := minf(860.0, view.x - 150.0)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end.add_child(center)
	# One big sheet of light cardboard, taped down at the top corners.
	var sheet := BoxPanel.make("light", 31 + _end_page, Vector4(50, 30, 50, 32), [-0.5, 0.4, -0.3][_end_page % 3])
	sheet.add_corner_tapes(33 + _end_page * 5)
	center.add_child(sheet)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size.x = width
	sheet.add_child(box)
	# A paw for each page, filled up to this one.
	var dots := PawRating.new()
	dots.set_rating(_end_page + 1, _end_pages.size(), 15.0)
	dots.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(dots)
	# A won night gets a red paw stamp beside the title.
	var win := big and _end_endless
	var room := 170.0 if win else 0.0
	if win:
		var stamp := BoxBoard.make("stamp", Vector2.ZERO, Vector2(130, 130), 9)
		stamp.hole = Color("f7ecd0")
		sheet.add_decor(stamp, Vector2(1, 0), Vector2(-196, 30), Vector2(130, 130), 14.0)
	var title_text: String = page["title"]
	var title_size := 62 if big else 44
	var title := BoxStyle.label(title_text, title_size, BoxStyle.INK, true)
	(title.label_settings as LabelSettings).font_size = BoxStyle.fit_size(tr(title_text), BoxStyle.head_font(), title_size, width - room, 30)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = width - room
	box.add_child(title)
	if big:
		_end_numbers(box, page, width, room)
	else:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 8)
		scroll.add_child(list)
		var height := 0.0
		for text: String in page["lines"]:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			var paw := BoxBoard.make("paw", Vector2.ZERO, Vector2(18, 26), 1)
			paw.custom_minimum_size = Vector2(18, 26)
			paw.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			row.add_child(paw)
			var line := BoxStyle.label(text, 19, BoxStyle.INK)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.custom_minimum_size.x = width - 60.0
			row.add_child(line)
			list.add_child(row)
			height += 28.0 * (1 + floori(text.length() * 19.0 * 0.55 / (width - 60.0))) + 8.0
		var max_height := view.y * 0.46
		scroll.custom_minimum_size = Vector2(width, minf(height, max_height))
		box.add_child(scroll)
		_summary_scroll = scroll
		_fit_end_scroll(scroll, list, max_height)
		if page["total"] != "":
			var total := BoxStyle.label(page["total"], 34, Color("a81913"), true)
			(total.label_settings as LabelSettings).font_size = BoxStyle.fit_size(tr(page["total"]), BoxStyle.head_font(), 34, width, 20)
			total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(total)
	# Buttons with their keys, clickable too.
	var buttons := HFlowContainer.new()
	buttons.alignment = FlowContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("h_separation", 22)
	buttons.add_theme_constant_override("v_separation", 10)
	box.add_child(buttons)
	if _end_page < _end_pages.size() - 1:
		_end_button(buttons, "END_NEXT", "Enter", "next", true, 71, -1.2)
	else:
		_end_button(buttons, "END_AGAIN_BUTTON", "R", "again", true, 72, -1.0)
		_end_button(buttons, "END_BACK_BUTTON", "Esc", "back", false, 73, 1.0)
	if _end_page == 0 and _end_endless:
		_end_button(buttons, "END_ENDLESS_BUTTON", "E", "endless", false, 74, -0.8)
		var hint_text := tr("ENDLESS_HINT")
		if hint_text.begins_with("E") and "–" in hint_text.substr(0, 4):
			hint_text = hint_text.substr(hint_text.find("–") + 1).strip_edges()
		var hint := BoxStyle.label(hint_text.left(1).to_upper() + hint_text.substr(1), 15, Color(BoxStyle.INK, 0.65))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.custom_minimum_size.x = width
		box.add_child(hint)
	(buttons.get_child(0) as Button).grab_focus.call_deferred()


## The scroll box takes the list's real height once it is laid out (up to
## `max_height`), so a short list leaves no empty space.
func _fit_end_scroll(scroll: ScrollContainer, list: Control, max_height: float) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(scroll) and is_instance_valid(list):
		scroll.custom_minimum_size.y = minf(list.get_combined_minimum_size().y, max_height)


## The first end page: the cat's line, four numbers and which weapons did
## the most damage tonight.
func _end_numbers(box: VBoxContainer, page: Dictionary, width: float, room: float) -> void:
	var sub_text: String = page["lines"][0] if not (page["lines"] as Array).is_empty() else ""
	var sub := BoxStyle.label(sub_text, 20, BoxStyle.INK)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = width - room
	box.add_child(sub)
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 14)
	box.add_child(tiles)
	var tile_w := (width - 3.0 * 14.0) / 4.0
	_end_tile(tiles, "END_KILLS", Hud.thousands(int(end_facts.get("kills", 0))), BoxStyle.INK, tile_w, 41, -1.4)
	_end_tile(tiles, "END_TIME", _format_time(float(end_facts.get("time", 0.0))), BoxStyle.INK, tile_w, 42, 1.0)
	_end_tile(tiles, "END_LEVEL", str(int(end_facts.get("level", 1))), BoxStyle.INK, tile_w, 43, -0.8)
	_end_tile(tiles, "END_GOLD", Hud.thousands(int(end_facts.get("gold", 0))), Color("a81913"), tile_w, 44, 1.3)
	# Damage by weapon, the biggest four, as shares of all damage.
	var total := 0.0
	var ids: Array = []
	for id: String in Weapon.damage_log:
		total += float(Weapon.damage_log[id])
		ids.append(id)
	if total <= 0.0:
		return
	ids.sort_custom(func(a: String, b: String) -> bool: return float(Weapon.damage_log[a]) > float(Weapon.damage_log[b]))
	var head := BoxStyle.label(tr("END_DAMAGE"), 28, BoxStyle.INK, true)
	box.add_child(head)
	var best := float(Weapon.damage_log[ids[0]]) / total
	for id: String in ids.slice(0, 4):
		var share := float(Weapon.damage_log[id]) / total
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		if GameData.weapons.has(id):
			row.add_child(IconView.new("weapon", id, 28))
		var name_label := BoxStyle.label(Upgrades.item_name("weapon", id) if GameData.weapons.has(id) else id, 17)
		name_label.custom_minimum_size.x = 200
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(name_label)
		# The bar is a stroke of red marker, as long as the weapon's share.
		var area := Control.new()
		area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		area.custom_minimum_size = Vector2(0, 18)
		var stroke := BoxBoard.make("scribble", Vector2.ZERO, Vector2(10, 18), 11 + ids.find(id))
		area.add_child(stroke)
		area.resized.connect(func() -> void: stroke.size = Vector2(maxf(area.size.x * share / best, 40.0), 18.0))
		row.add_child(area)
		var pct := BoxStyle.label("%d %%" % roundi(share * 100.0), 17, BoxStyle.RED)
		pct.custom_minimum_size.x = 56
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pct)
		box.add_child(row)


func _end_tile(row: HBoxContainer, key: String, value: String, color: Color, w: float, seed_: int, tilt_: float) -> void:
	var tile := BoxPanel.make("board", seed_, Vector4(12, 8, 12, 12), tilt_)
	tile.custom_minimum_size.x = w
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	tile.add_child(col)
	var name_text := tr(key)
	var k := BoxStyle.label(name_text, 16, Color(BoxStyle.INK, 0.8))
	(k.label_settings as LabelSettings).font_size = BoxStyle.fit_size(name_text, BoxStyle.body_font(), 16, w - 24.0, 11)
	col.add_child(k)
	var v := BoxStyle.label(value, 44, color, true)
	(v.label_settings as LabelSettings).font_size = BoxStyle.fit_size(value, BoxStyle.head_font(), 44, w - 24.0, 22)
	col.add_child(v)
	row.add_child(tile)


func _end_button(row: Container, text: String, key: String, action: String, first: bool, seed_: int, tilt_: float) -> void:
	var b := BoxButton.make(text, 32 if first else 26, seed_, tilt_)
	b.set_hint(key)
	b.pressed.connect(func() -> void: end_action.emit(action))
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
	_time_card.set_text(_format_time(elapsed))
	_kills_card.set_text(tr("HUD_KILLS") % kills)
	if _debug_label.visible:
		_debug_label.text = "FPS %d · enemies %d%s" % [Engine.get_frames_per_second(), enemy_count, debug_extra]


func show_pause(on: bool) -> void:
	_pause_language.text = tr("LANGUAGE_NAME")
	_pause_sound.text = tr("PAUSE_KEY_SOUND") % tr("SOUND_OFF" if Settings.muted else "SOUND_ON")
	_pause_numbers.text = tr("PAUSE_KEY_NUMBERS") % tr("SOUND_ON" if Settings.damage_numbers else "SOUND_OFF")
	_pause_shake.text = tr("PAUSE_KEY_SHAKE") % tr("SOUND_ON" if Settings.screen_shake else "SOUND_OFF")
	_fill_stories()
	_give_up.relabel("PAUSE_GIVE_UP")
	var cat: Player = get_parent().get("player")
	_discard.visible = cat != null and cat.discard_left > 0
	if cat != null:
		_discard_left.set_tag(tr("PAUSE_LEFT") % cat.discard_left, BoxStyle.TAPE, 150.0, 15)
		_discard_left.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_discard_left.offset_left = -_discard_left.custom_minimum_size.x + 10.0
		_discard_left.offset_right = 10.0
		_discard_left.offset_top = -15.0
		_discard_left.offset_bottom = -15.0 + _discard_left.custom_minimum_size.y
	if on:
		_fill_weapons(cat)
		_fill_log()
		_fit_side(_pause_weapons)
		_fit_side(_pause_log)
	_pause_overlay.visible = on
	if on:
		_pause_resume.grab_focus.call_deferred()


## A key chip ("M  Sound on") in the pause screen's key grid: the key in red
## marker on a small cream note; returns the label of its setting.
func _key_item(row: Container, key: String) -> Label:
	var chip := BoxPanel.make("light", 50 + key.unicode_at(0) % 17, Vector4(14, 4, 16, 7), float(key.unicode_at(0) % 5 - 2) * 0.5)
	chip.size_flags_horizontal = Control.SIZE_FILL
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 8)
	chip.add_child(item)
	var cap := BoxStyle.label(key, 26, BoxStyle.RED, true)
	item.add_child(cap)
	var l := BoxStyle.label("", 15)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item.add_child(l)
	row.add_child(chip)
	return l


var _note_n := 0


## A small cream paper note for the pause panels, each a little crooked.
func _note(pad: Vector4 = Vector4(12, 8, 12, 9)) -> BoxPanel:
	_note_n += 1
	return BoxPanel.make("light", 60 + _note_n % 9, pad, float(_note_n % 5 - 2) * 0.4)


## The ink colour for a line on a paper note (the old light-on-dark colours
## become red or green marker).
func _ink_for(color: Color) -> Color:
	if color.is_equal_approx(Color("ff9a8a")):
		return Color("a81913")
	if color.is_equal_approx(UiStyle.GREEN):
		return Color("2f6b2a")
	return BoxStyle.INK


## Ink text on a paper note that wraps.
func _ink_line(text: String, size: int, color: Color) -> Label:
	var l := BoxStyle.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## The left pause panel: a note per weapon, then the skills and shrine bonuses.
func _fill_weapons(player: Player) -> void:
	for child in _pause_weapons.get_children():
		child.queue_free()
	if player == null:
		return
	var weapons: Array = player.weapons.get_children().filter(func(w: Node) -> bool: return w is Weapon)
	_pause_weapons.add_child(_side_head(tr("PAUSE_WEAPONS"), "%d / %d" % [weapons.size(), player.max_weapons()]))
	for w: Weapon in weapons:
		var card := _note()
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
		var name_label := BoxStyle.label(Upgrades.item_name("weapon", w.id), 17, BoxStyle.INK, true)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		top.add_child(name_label)
		var maxed := w.level >= w.max_level()
		top.add_child(BoxStyle.label(("★ " if maxed else "") + "%d/%d" % [w.level, w.max_level()], 14, BoxStyle.RED))
		if w.branch != "":
			col.add_child(BoxStyle.label("%s %d" % [tr("BRANCH_%s_NAME" % w.branch), w.branch_rank], 14, Color("2f6b2a")))
		var evolve: Dictionary = w.data.get("evolve", {})
		if not evolve.is_empty():
			var has: bool = player.passives.has(evolve["with"])
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 5)
			line.add_child(IconView.new("passive", evolve["with"], 16))
			var evolve_label := BoxStyle.label(tr("PAUSE_EVOLVE_WITH") % Upgrades.item_name("passive", evolve["with"]), 13, Color("2f6b2a") if has else Color(BoxStyle.INK, 0.6))
			evolve_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			evolve_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(evolve_label)
			col.add_child(line)
		_pause_weapons.add_child(card)
	if not player.passives.is_empty():
		_pause_weapons.add_child(_side_head(tr("PAUSE_SKILLS"), "%d / %d" % [player.passives.size(), Player.MAX_PASSIVES]))
		for id: String in player.passives:
			var card := _note()
			card.tooltip_text = tr("PASSIVE_%s_DESC" % id)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			card.add_child(row)
			row.add_child(IconView.new("passive", id, 28))
			var name_label := BoxStyle.label(Upgrades.item_name("passive", id), 16, BoxStyle.INK, true)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(name_label)
			var paws := PawRating.new()
			paws.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			paws.set_rating(int(player.passives[id]), (GameData.passives[id]["levels"] as Array).size(), 12.0)
			row.add_child(paws)
			_pause_weapons.add_child(card)
	var bless := blessings_text(true)
	if bless != "":
		var note := _note()
		var text := RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.scroll_active = false
		text.add_theme_font_override("normal_font", BoxStyle.body_font())
		text.add_theme_font_size_override("normal_font_size", 15)
		text.add_theme_color_override("default_color", BoxStyle.INK)
		text.text = bless.strip_edges()
		note.add_child(text)
		_pause_weapons.add_child(note)


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
		_pause_log.add_child(_ink_line(tr("PAUSE_LOG_EMPTY"), 15, Color(BoxStyle.INK, 0.6)))
	_pause_log.add_child(_side_head(tr("PAUSE_NEWS"), ""))
	if _log.is_empty():
		_pause_log.add_child(_ink_line(tr("PAUSE_LOG_EMPTY"), 15, Color(BoxStyle.INK, 0.6)))
		return
	var note := _note(Vector4(14, 10, 14, 11))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	note.add_child(grid)
	_pause_log.add_child(note)
	for entry: Array in _log:
		var t := BoxStyle.label(entry[0], 13, BoxStyle.RED)
		t.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		grid.add_child(t)
		var l := _ink_line(entry[1], 15, BoxStyle.INK)
		l.custom_minimum_size.x = 190
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(l)


## A small note in the right pause panel (the quest now, an open cat flap).
func _now_card(title: String, body: String, color: Color, _border: Color, glyph: String) -> BoxPanel:
	var card := _note()
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
	col.add_child(_ink_line(title, 16, _ink_for(color)))
	if body != "":
		col.add_child(_ink_line(body, 15, Color(BoxStyle.INK, 0.85)))
	return card


## A panel heading in marker with an optional count at its right ("Your
## weapons  4 / 6"), a red line under it.
func _side_head(title: String, count: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	var t := BoxStyle.label(title, 32, BoxStyle.INK, true)
	(t.label_settings as LabelSettings).font_size = BoxStyle.fit_size(title, BoxStyle.head_font(), 32, 230.0 if count != "" else 300.0, 18)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(t)
	if count != "":
		var c := BoxStyle.label(count, 16, BoxStyle.RED)
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(c)
	col.add_child(row)
	var line := BoxBoard.make("scribble", Vector2.ZERO, Vector2(10, 12), 7)
	line.custom_minimum_size = Vector2(0, 12)
	col.add_child(line)
	return col


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
		grid.add_theme_constant_override("v_separation", 4)
		for id: String in GameData.chains:
			if GameData.chains[id].get("stage", "any") != spawner.stage_id or (GameData.chains[id].has("secret") and ChainStep.progress_of(id) == 0):
				continue
			var n := ChainStep.steps(id).size()
			var done := ChainStep.progress_of(id)
			var name_label := BoxStyle.label(tr("CHAIN_%s_NAME" % id), 16, Color("2f6b2a") if done >= n else BoxStyle.INK)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(name_label)
			var paws := PawRating.new()
			paws.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			paws.set_rating(done, n, clampf(84.0 / maxf(n, 1.0), 6.0, 13.0))
			grid.add_child(paws)
			var count := BoxStyle.label("✓" if done >= n else "%d/%d" % [done, n], 14, Color(BoxStyle.INK, 0.7))
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count.custom_minimum_size.x = 34
			grid.add_child(count)
			rows += 1
		if rows > 0:
			_pause_stories.add_child(BoxStyle.label(tr("PAUSE_MAP_STORIES"), 26, BoxStyle.INK, true))
			_pause_stories.add_child(grid)
		else:
			grid.free()
	_pause_stories_panel.visible = rows > 0


## Shrine bonuses still running (what each gave, and for how long), as
## BBCode under the weapons in the pause screen.
func blessings_text(ink: bool = false) -> String:
	var cat: Variant = get_parent().get("player")
	if cat == null or not is_instance_valid(cat):
		return ""
	var lines: Array[String] = []
	for b in (cat as Player).blessings:
		if String(b.get("label", "")) == "":
			continue
		var left: String = tr("BLESS_ALL_NIGHT") if float(b["t"]) > 3600.0 else tr("CHAIN_TIME") % ceili(float(b["t"]))
		var line := "[color=#%s]%s[/color]  %s" % [((b["color"] as Color).darkened(0.45) if ink else (b["color"] as Color).lightened(0.3)).to_html(false), tr(b["label"]), left]
		if String(b.get("desc", "")) != "":
			line += "
" + String(b["desc"])
		lines.append(line)
	if lines.is_empty():
		return ""
	return "

[color=#%s]%s[/color]
%s" % [(BoxStyle.RED if ink else UiStyle.GOLD).to_html(false), tr("PAUSE_BLESSINGS"), "

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


## A framed, scrollable board at one side of the pause screen; returns the
## box the notes go into.
func _pause_side(_title_key: String, left: bool) -> VBoxContainer:
	var panel := BoxPanel.make("board", 21 if left else 22, Vector4(22, 28, 18, 24), -0.5 if left else 0.5)
	panel.add_decor(BoxBoard.make("tape", Vector2.ZERO, Vector2(84, 26), 23 if left else 24), Vector2(0.5, 0), Vector2(-42, -13), Vector2(84, 26), 2.0 if left else -2.0)
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
	box.add_theme_constant_override("separation", 10)
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
	var h := 54.0
	for child in box.get_children():
		if child is Control and (child as Control).visible:
			h = maxf(h, (child as Control).position.y + (child as Control).size.y + 54.0)
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
