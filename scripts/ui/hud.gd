class_name Hud
extends CanvasLayer
## Run clock, kill counter, pause and game-over overlays. Built in code for
## now; will move to a proper scene once the UI grows.

const XP_BAR_HEIGHT := 14.0

var level_up: LevelUpPanel
var treasure: TreasurePanel

var _xp_fill: ColorRect
var _level_label: Label
var _inventory: InventoryBar
var _time_label: Label
var _kills_label: Label
var _gold_label: Label
var _debug_label: Label
var _pause_overlay: Control
var _pause_language: Label
var _pause_sound: Label
var _pause_numbers: Label
var _pause_shake: Label
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

	_gold_label = _label(18, HORIZONTAL_ALIGNMENT_RIGHT)
	_gold_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_gold_label.offset_top = 112
	_gold_label.offset_right = -20
	_gold_label.label_settings.font_color = Color("f2c14e")
	add_child(_gold_label)

	_inventory = InventoryBar.new()
	add_child(_inventory)

	_debug_label = _label(14, HORIZONTAL_ALIGNMENT_LEFT)
	_debug_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_debug_label.offset_left = 10
	_debug_label.offset_top = -28
	_debug_label.visible = OS.is_debug_build()
	add_child(_debug_label)

	_pause_overlay = _overlay(["PAUSE_TITLE", "PAUSE_HINT", "", "", "", ""])
	_pause_language = _pause_overlay.get_node("Box").get_child(2)
	_pause_sound = _pause_overlay.get_node("Box").get_child(3)
	_pause_numbers = _pause_overlay.get_node("Box").get_child(4)
	_pause_shake = _pause_overlay.get_node("Box").get_child(5)

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

	_win_overlay = _overlay(["VICTORY_TITLE", "", "VICTORY_HINT", "GAME_OVER_MENU"])
	_extract_overlay = _overlay(["EXTRACT_TITLE", "", "VICTORY_HINT", "GAME_OVER_MENU"])
	_win_stats = _win_overlay.get_node("Box").get_child(1)

	_banner = _label(30, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_top = 90
	_banner.label_settings.font_color = Color("ff7a6b")
	_banner.visible = false
	add_child(_banner)

	_quest_title = _label(20, HORIZONTAL_ALIGNMENT_RIGHT)
	_quest_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_quest_title.offset_top = 58
	_quest_title.offset_right = -20
	_quest_title.label_settings.font_color = Color("f2c14e")
	add_child(_quest_title)
	_quest_text = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_quest_text.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_quest_text.offset_top = 84
	_quest_text.offset_right = -20
	add_child(_quest_text)
	_quest_arrow = QuestArrow.new()
	add_child(_quest_arrow)
	move_child(_quest_arrow, 0)
	_extract_arrow = QuestArrow.new()
	_extract_arrow.color = Color("6cd48a")
	add_child(_extract_arrow)
	move_child(_extract_arrow, 0)
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


var _hurt := 0.0


func flash_hurt() -> void:
	_hurt = 0.7


func _process(delta: float) -> void:
	if _hurt > 0.0 or (_hurt_flash.material as ShaderMaterial).get_shader_parameter("strength") != 0.0:
		_hurt = maxf(_hurt - delta * 2.5, 0.0)
		(_hurt_flash.material as ShaderMaterial).set_shader_parameter("strength", _hurt)
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner.modulate.a = clampf(_banner_time, 0.0, 1.0)
		_banner.visible = _banner_time > 0.0


## Shows the active quest (or hides the tracker when `quest` is null).
func update_quest(quest: Quest) -> void:
	if quest == null:
		_quest_title.text = ""
		_quest_text.text = ""
		_quest_arrow.target = null
		return
	_quest_title.text = quest.title()
	_quest_text.text = quest.objective()
	_quest_arrow.target = quest.target_position()


## Big health bar for the final boss (null hides it).
func update_boss(boss: Enemy) -> void:
	_boss_bar.visible = boss != null
	if boss == null:
		return
	_boss_fill.size.x = 594.0 * clampf(boss.hp / boss.max_hp, 0.0, 1.0)
	_boss_name.text = tr("ENEMY_%s_NAME" % boss.id)


## Big warning text below the clock that fades out after `seconds`.
func show_banner(text: String, seconds: float = 3.0) -> void:
	_banner.text = text
	_banner_time = seconds
	_banner.visible = true


func show_victory(kills: int) -> void:
	_win_stats.text = tr("VICTORY_STATS") % kills
	_win_overlay.visible = true


func update_xp(player: Player) -> void:
	var bar_width := get_viewport().get_visible_rect().size.x - 4.0
	_xp_fill.size.x = bar_width * clampf(player.xp / player.xp_to_next(), 0.0, 1.0)
	_level_label.text = "Lv %d" % player.level


func update_inventory(player: Player) -> void:
	_inventory.player = player
	_inventory.refresh()


func update_gold(amount: int, charms: int = 0) -> void:
	_gold_label.text = tr("HUD_GOLD") % amount
	if charms > 0:
		_gold_label.text += "  ·  " + tr("HUD_CHARMS") % charms


## Gold and streak lines on whichever end screen is showing.
func show_summary(lines: Array[String]) -> void:
	for overlay: Control in [_over_overlay, _win_overlay, _extract_overlay]:
		if not overlay.visible:
			continue
		var box := overlay.get_node("Box")
		for i in lines.size():
			var line := _label(22, HORIZONTAL_ALIGNMENT_CENTER)
			line.text = lines[i]
			line.label_settings.font_color = Color("f2c14e")
			box.add_child(line)
			box.move_child(line, 2 + i)


func show_extracted(elapsed: float, kills: int) -> void:
	(_extract_overlay.get_node("Box").get_child(1) as Label).text = tr("EXTRACT_STATS") % [_format_time(elapsed), kills]
	_extract_overlay.visible = true


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
	_pause_overlay.visible = on


func show_game_over(elapsed: float, kills: int) -> void:
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
