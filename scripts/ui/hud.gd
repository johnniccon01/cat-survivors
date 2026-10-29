class_name Hud
extends CanvasLayer
## Run clock, kill counter, pause and game-over overlays. Built in code for
## now; will move to a proper scene once the UI grows.

const XP_BAR_HEIGHT := 14.0

signal resume_pressed
signal give_up_pressed
signal discard_pressed

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
var _pause_overlay: Control
var _give_up: Button
var _discard: Button
var _pause_stories: Label
var _pause_language: Label
var _pause_sound: Label
var _pause_numbers: Label
var _pause_shake: Label
var _pause_weapons: RichTextLabel
var _pause_log: RichTextLabel
## Recent banner texts (quest lines, shrines...), newest first.
var _log: Array[String] = []
const LOG_SIZE := 15
var _hurt_flash: ColorRect
var _over_overlay: Control
var _over_stats: Label
var _win_overlay: Control
var _win_stats: Label
var _banner: Label
var _quest_title: Label
var _quest_text: Label
var _quest_arrow: QuestArrow
var _extract_arrow: QuestArrow
var _page_arrow: QuestArrow
var _extract_label: Label
var _extract_overlay: Control
var _boss_bar: ColorRect
var _boss_fill: ColorRect
var _boss_name: Label
var _banner_time := 0.0


func _ready() -> void:
	var xp_bg := ColorRect.new()
	xp_bg.color = Color("2b1d14")
	xp_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	xp_bg.offset_bottom = XP_BAR_HEIGHT
	add_child(xp_bg)
	_xp_fill = ColorRect.new()
	_xp_fill.color = Color("5aa9e6")
	_xp_fill.position = Vector2(2, 2)
	_xp_fill.size = Vector2(0, XP_BAR_HEIGHT - 4)
	xp_bg.add_child(_xp_fill)

	_level_label = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_level_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_level_label.offset_top = -4
	_level_label.offset_right = -8
	add_child(_level_label)

	_time_label = _label(32, HORIZONTAL_ALIGNMENT_CENTER)
	_time_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_time_label.offset_top = 18
	add_child(_time_label)

	_kills_label = _label(22, HORIZONTAL_ALIGNMENT_RIGHT)
	_kills_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_kills_label.offset_top = 24
	_kills_label.offset_right = -20
	add_child(_kills_label)

	# Right column under the kills: quest, gold, blessings stacked so long
	# quest texts push the rest down instead of covering it.
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	column.offset_top = 58
	column.offset_right = -20
	column.offset_left = -400
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	_quest_title = _label(20, HORIZONTAL_ALIGNMENT_RIGHT)
	_quest_title.label_settings.font_color = Color("f2c14e")
	_quest_text = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_gold_label = _label(18, HORIZONTAL_ALIGNMENT_RIGHT)
	_gold_label.label_settings.font_color = Color("f2c14e")
	# Shrine blessings still running, with the seconds left.
	_bless_label = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	for line: Label in [_quest_title, _quest_text, _gold_label, _bless_label]:
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.visible = false
		column.add_child(line)

	_inventory = InventoryBar.new()
	add_child(_inventory)

	_debug_label = _label(14, HORIZONTAL_ALIGNMENT_LEFT)
	_debug_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_debug_label.offset_left = 10
	_debug_label.offset_top = -28
	_debug_label.visible = OS.is_debug_build()
	add_child(_debug_label)

	_pause_overlay = _overlay(["PAUSE_TITLE", "PAUSE_HINT", "", "", "", ""])
	var pause_box := _pause_overlay.get_node("Box")
	var resume := UiStyle.button("PAUSE_RESUME", 340)
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	var open_settings := UiStyle.button("MENU_SETTINGS", 340)
	open_settings.pressed.connect(func() -> void:
		_pause_overlay.visible = false
		settings.open())
	var give_up := UiStyle.button("PAUSE_GIVE_UP", 340)
	_give_up = give_up
	# Asks once more first: a stray click or key must not end the night.
	give_up.pressed.connect(func() -> void:
		if give_up.text == "PAUSE_GIVE_UP_SURE":
			give_up_pressed.emit()
		else:
			give_up.text = "PAUSE_GIVE_UP_SURE"
			resume.grab_focus())
	_discard = UiStyle.button("PAUSE_DISCARD", 340)
	_discard.pressed.connect(func() -> void: discard_pressed.emit())
	for i in 4:
		var b: Button = [resume, open_settings, _discard, give_up][i]
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pause_box.add_child(b)
		pause_box.move_child(b, 1 + i)
	_pause_language = _pause_overlay.get_node("Box").get_child(6)
	_pause_sound = _pause_overlay.get_node("Box").get_child(7)
	_pause_numbers = _pause_overlay.get_node("Box").get_child(8)
	_pause_shake = _pause_overlay.get_node("Box").get_child(9)
	for line: Label in [_pause_language, _pause_sound, _pause_numbers, _pause_shake]:
		line.label_settings.font_size = 16
		line.label_settings.font_color = UiStyle.MUTED
	_pause_stories = _label(17, HORIZONTAL_ALIGNMENT_CENTER)
	_pause_stories.label_settings.font_color = UiStyle.GOLD
	_pause_stories.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pause_stories.custom_minimum_size = Vector2(600, 0)
	pause_box.add_child(_pause_stories)
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

	_banner = _label(30, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_top = 90
	_banner.offset_left = 320
	_banner.offset_right = -320
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.label_settings.font_color = Color("ff7a6b")
	_banner.visible = false
	add_child(_banner)

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
	_extract_label = _label(18, HORIZONTAL_ALIGNMENT_RIGHT)
	_extract_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_extract_label.offset_top = 136
	_extract_label.offset_right = -20
	_extract_label.label_settings.font_color = Color("6cd48a")
	add_child(_extract_label)

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
		_banner.modulate.a = clampf(_banner_time, 0.0, 1.0)
		_banner.visible = _banner_time > 0.0


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
	_banner_time = maxf(seconds, 2.0 + text.length() * 0.06)
	_banner.visible = true
	if text != "" and (_log.is_empty() or _log[0] != text):
		_log.push_front(text)
		if _log.size() > LOG_SIZE:
			_log.pop_back()


## Hides the end screens (and their summary lines) when the night goes on.
func hide_end_screens() -> void:
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
	var bar_width := get_viewport().get_visible_rect().size.x - 4.0
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
	_gold_label.visible = true
	_gold_label.text = tr("HUD_GOLD") % amount
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
	_kills_label.text = tr("HUD_KILLS") % kills
	if _debug_label.visible:
		_debug_label.text = "FPS %d · enemies %d%s" % [Engine.get_frames_per_second(), enemy_count, debug_extra]


func show_pause(on: bool) -> void:
	_pause_language.text = tr("PAUSE_LANGUAGE") % tr("LANGUAGE_NAME")
	_pause_sound.text = tr("PAUSE_SOUND") % tr("SOUND_OFF" if Settings.muted else "SOUND_ON")
	_pause_numbers.text = tr("PAUSE_NUMBERS") % tr("SOUND_ON" if Settings.damage_numbers else "SOUND_OFF")
	_pause_shake.text = tr("PAUSE_SHAKE") % tr("SOUND_ON" if Settings.screen_shake else "SOUND_OFF")
	_pause_stories.text = _stories_text()
	_give_up.text = "PAUSE_GIVE_UP"
	var cat: Player = get_parent().get("player")
	_discard.visible = cat != null and cat.discard_left > 0
	if cat != null:
		_discard.text = tr("PAUSE_DISCARD") % cat.discard_left
	if on:
		_pause_weapons.text = weapons_text() + blessings_text()
		var log_text := "\n\n".join(_log) if not _log.is_empty() else tr("PAUSE_LOG_EMPTY")
		if _quest_title.visible:
			# The quest running now on top, then what was said lately.
			log_text = "[color=#%s]%s[/color]\n%s\n\n%s" % [UiStyle.GOLD.to_html(false), _quest_title.text, _quest_text.text, log_text]
		_pause_log.text = log_text
	_pause_overlay.visible = on
	if on:
		(_pause_overlay.get_node("Box").get_child(1) as Button).grab_focus.call_deferred()


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


## A framed, scrollable text box at one side of the pause screen.
func _pause_side(title_key: String, left: bool) -> RichTextLabel:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.box(Color(UiStyle.BG, 0.9), UiStyle.BORDER))
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE if left else Control.PRESET_RIGHT_WIDE)
	panel.offset_top = 40
	panel.offset_bottom = -40
	if left:
		panel.offset_left = 16
		panel.offset_right = 316
	else:
		panel.offset_left = -316
		panel.offset_right = -16
	var box := VBoxContainer.new()
	box.add_child(UiStyle.label(tr(title_key), 20, UiStyle.GOLD))
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.scroll_active = true
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(text)
	panel.add_child(box)
	_pause_overlay.add_child(panel)
	return text


## "This map's stories: The Kibble Thief 1/4 · ..." for the pause screen.
func _stories_text() -> String:
	var spawner: Variant = get_parent().get("spawner")
	if spawner == null:
		return ""
	var stage: String = spawner.stage_id
	var parts: Array[String] = []
	for id: String in GameData.chains:
		if GameData.chains[id].get("stage", "any") != stage or (GameData.chains[id].has("secret") and ChainStep.progress_of(id) == 0):
			continue
		var n := ChainStep.steps(id).size()
		var done := ChainStep.progress_of(id)
		parts.append("%s %s" % [tr("CHAIN_%s_NAME" % id), "✓" if done >= n else "%d/%d" % [done, n]])
	return "" if parts.is_empty() else tr("PAUSE_STORIES") % "  ·  ".join(parts)


## `title` is already translated (the cat's name, or the devil's line).
func show_game_over(elapsed: float, kills: int, title: String) -> void:
	(_over_overlay.get_node("Box").get_child(0) as Label).text = title
	_over_stats.text = tr("GAME_OVER_STATS") % [_format_time(elapsed), kills]
	_over_overlay.visible = true


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
