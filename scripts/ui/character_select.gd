extends Control
## Cat and map selection before a run: the neighbourhood at night with every
## map as a place in it (DistrictMap), the chosen place beside it (its story,
## final boss, difficulty, stories, record, darkness and stars), and the cats
## along the bottom with the chosen one's bonuses and Play. Locked cats and
## maps show as silhouettes with a hint on how to get them. Any debug flag on
## the command line skips this screen.

const MAIN_SCENE := "res://scenes/main.tscn"
const BG := Color("1d1626")
const CARD := Color("3b2a4a")
const BORDER := Color("6b5480")
const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")

var _ids: Array[String] = []
var _index := 0
var _cards: Array[PanelContainer] = []
var _previews: Array[CatPreview] = []
var _name: Label
var _desc: Label
var _stage_label: Label
var _stage_ids: Array[String] = []
var _stage_index := 0
var _shop: ShopPanel
var _charms: CharmPanel
var _items: ItemPanel
var _artifacts: ArtifactPanel
var _artifact_label: Label
var _journal: JournalPanel
var _challenges: ChallengePanel
var _challenge_label: Label
var _worn: Label
var _gold: Label
var _big: CatPreview
var _weapon_icon: IconView
var _weapon_label: Label
var _cat_stats: Label
var _district: DistrictMap
## A future map chosen on the town (not playable yet); "" for a real map.
var _place := ""
## The night report chosen on the town (index into Profile.reports), or -1.
var _report := -1
var _report_box: PanelContainer
var _report_win: Label
var _report_lose: Label
var _home_marks: Array[Control] = []
var _top_buttons: HBoxContainer
## The cat bar's fixed height: choosing a cat never resizes the map.
const BOTTOM_HEIGHT := 178.0
## The full moon is on show in the side panel.
var _moon_mode := false
## A resident on show in the side panel ("" if none).
var _resident := ""
var _service_box: PanelContainer
var _service_label: Label
var _service_buy: Button
var _moon_box: PanelContainer
var _moon_traps: Label
var _moon_guards: Label
var _moon_chip: Label
var _place_pic: TextureRect
var _place_badge: Label
var _place_story: Label
var _boss_pic: BossPortrait
var _boss_name: Label
var _boss_sub: Label
var _place_stats: Array[Label] = []
var _place_stars: Label
var _chips: HBoxContainer
var _play: Button
var _hover := -1
var _dark_label: Label
var _dark_minus: Button
var _dark_plus: Button
var _t := 0.0
## Cat bonus stat -> [translation key, multiplier for the shown number, colour].
const BONUS_TEXT := {
	"might": ["BONUS_MIGHT", 100.0, Color("ff7a6a")],
	"cooldown": ["BONUS_COOLDOWN", -100.0, Color("ffd36a")],
	"area": ["BONUS_AREA", 100.0, Color("8ee07a")],
	"speed": ["BONUS_SPEED", 100.0, Color("6cc8ff")],
	"magnet": ["BONUS_MAGNET", 1.0, Color("c7a0ff")],
	"max_hp": ["BONUS_MAX_HP", 1.0, Color("ff8aa8")],
	"luck": ["BONUS_LUCK", 100.0, Color("f2c14e")],
	"regen": ["BONUS_REGEN", 1.0, Color("8ee07a")],
	"proj_speed": ["BONUS_PROJ_SPEED", 100.0, Color("9ae0ff")],
	"growth": ["BONUS_GROWTH", 100.0, Color("b9e86a")],
	"weapon_slots": ["BONUS_WEAPON_SLOTS", 1.0, Color("ffb35a")],
}


func _ready() -> void:
	for arg: String in GameData.args():
		if arg.begins_with("--") and arg not in ["--shop", "--charms", "--artifacts", "--goals", "--journal", "--challenges", "--ui-test"]:
			get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
			return
	for id: String in GameData.cats:
		# Secret cats only show up once they are unlocked.
		if GameData.cats[id].get("npc", false):
			continue
		if not GameData.cats[id].get("hidden", false) or Profile.is_unlocked(id):
			_ids.append(id)
	_index = maxi(_ids.find(Profile.selected_cat), 0)
	for id: String in GameData.stages:
		_stage_ids.append(id)
	_stage_index = maxi(_stage_ids.find(Profile.selected_stage), 0)
	# New night reports come in whenever some are missing.
	Profile.make_reports()
	Profile.save()
	_build()
	_district.show_reports()
	_fit_top()
	_refresh()
	Audio.play_music("music_menu")
	if "--shop" in GameData.args():
		_shop.open()
	if "--charms" in GameData.args():
		_charms.open()
	if "--artifacts" in GameData.args():
		_artifacts.open()
	if "--goals" in GameData.args():
		_journal.open("goals")
	if "--journal" in GameData.args():
		_journal.open("bestiary")


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# The night city from the title screen, dimmed, with twinkling stars.
	var art := TextureRect.new()
	art.texture = load("res://assets/title.png")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.modulate = Color(0.55, 0.5, 0.65)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	add_child(MenuSky.new())
	var shade := ColorRect.new()
	shade.color = Color(BG, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14
	root.offset_right = -14
	root.offset_top = 10
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# Top bar: the title, everything you can do here, and your gold.
	var top_bar := PanelContainer.new()
	top_bar.add_theme_stylebox_override("panel", UiStyle.frame())
	root.add_child(top_bar)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	top_bar.add_child(top)
	var title := _label(28, GOLD)
	title.text = "DISTRICT_TITLE"
	top.add_child(title)
	var buttons := HBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 6)
	top.add_child(buttons)
	for entry: Array in [["MENU_UPGRADES", "U", func() -> void: _shop.open()],
			["MENU_CHARMS", "C", func() -> void: _charms.open()],
			["MENU_ITEMS", "I", func() -> void: _items.open()],
			["ARTIFACTS_TITLE", "V", func() -> void: _artifacts.open()],
			["CHALLENGES_TITLE", "X", func() -> void: _challenges.open()],
			["SELECT_BTN_DAILY", "T", _start_daily],
			["MENU_JOURNAL", "J", func() -> void: _journal.open("quests")],
			["SET_BACK", "Esc", func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn")]]:
		var b := UiStyle.click_button("%s (%s)" % [tr(entry[0]), entry[1]], 0, 15)
		b.pressed.connect(entry[2])
		buttons.add_child(b)
	_top_buttons = buttons
	_gold = _label(17, GOLD)
	top.add_child(_gold)

	# Middle: the neighbourhood, and the chosen place beside it.
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 10)
	root.add_child(middle)
	var map_frame := PanelContainer.new()
	map_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_frame.add_theme_stylebox_override("panel", UiStyle.frame(Color("3a2717"), Color("8a6236"), 5))
	middle.add_child(map_frame)
	_district = DistrictMap.new()
	_district.place_chosen.connect(_on_place_chosen)
	_district.report_chosen.connect(_on_report_chosen)
	_district.moon_chosen.connect(_on_moon_chosen)
	_district.resident_chosen.connect(_on_resident_chosen)
	map_frame.add_child(_district)
	# Badges in the map's top-left corner: the full moon and your nemesis.
	var badges := MarginContainer.new()
	badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side_name: String in ["margin_left", "margin_top"]:
		badges.add_theme_constant_override(side_name, 10)
	map_frame.add_child(badges)
	var badge_col := VBoxContainer.new()
	badge_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	badge_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	badge_col.add_theme_constant_override("separation", 6)
	badges.add_child(badge_col)
	var moon_chip := _badge(Color(0.08, 0.06, 0.12, 0.88), Color("6a5a7e"))
	badge_col.add_child(moon_chip)
	var moon_icon := Control.new()
	moon_icon.custom_minimum_size = Vector2(28, 28)
	moon_icon.draw.connect(func() -> void: DistrictMap.draw_moon(moon_icon, Vector2(14, 14), 10.0, Profile.nights_to_moon(), _t, false))
	moon_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon_chip.get_child(0).add_child(moon_icon)
	_moon_chip = _label(14, Color("f4ecd4"))
	_moon_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	moon_chip.get_child(0).add_child(_moon_chip)
	var nem := Profile.top_nemesis()
	if nem != "":
		var chip := _badge(Color(0.23, 0.08, 0.09, 0.9), Color("8a3030"))
		badge_col.add_child(chip)
		var face := BossPortrait.new()
		face.id = nem
		face.custom_minimum_size = Vector2(28, 28)
		chip.get_child(0).add_child(face)
		var nl := _label(14, Color("ffb3a8"))
		nl.text = "%s – %s" % [tr("ENEMY_%s_NAME" % nem), tr("NEMESIS_TITLE_%d" % Profile.nemesis_level(nem))]
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.get_child(0).add_child(nl)
	var side := PanelContainer.new()
	side.custom_minimum_size = Vector2(340, 0)
	side.add_theme_stylebox_override("panel", UiStyle.frame())
	middle.add_child(side)
	var side_scroll := ScrollContainer.new()
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(side_scroll)
	var place := VBoxContainer.new()
	place.add_theme_constant_override("separation", 5)
	place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_scroll.add_child(place)
	var pic_box := Control.new()
	pic_box.custom_minimum_size = Vector2(0, 100)
	pic_box.clip_contents = true
	place.add_child(pic_box)
	_place_pic = TextureRect.new()
	_place_pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_place_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_place_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_place_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_place_pic.modulate = Color(0.62, 0.66, 0.98)
	pic_box.add_child(_place_pic)
	_place_badge = _label(14, Color.WHITE)
	_place_badge.position = Vector2(8, 6)
	pic_box.add_child(_place_badge)
	_stage_label = _label(28, Color.WHITE)
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stage_label.position = Vector2(10, 58)
	pic_box.add_child(_stage_label)
	_place_story = _label(14, Color("ddd3e8"))
	_place_story.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_place_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_story.custom_minimum_size = Vector2(296, 0)
	place.add_child(_place_story)
	var boss_row := PanelContainer.new()
	boss_row.add_theme_stylebox_override("panel", UiStyle.box(Color(0.07, 0.05, 0.1, 0.8), Color("3a3148")))
	place.add_child(boss_row)
	var boss_h := HBoxContainer.new()
	boss_h.add_theme_constant_override("separation", 10)
	boss_row.add_child(boss_h)
	_boss_pic = BossPortrait.new()
	_boss_pic.custom_minimum_size = Vector2(44, 44)
	boss_h.add_child(_boss_pic)
	var boss_v := VBoxContainer.new()
	boss_v.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_h.add_child(boss_v)
	_boss_name = _label(17, Color("ffd0c4"))
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	boss_v.add_child(_boss_name)
	_boss_sub = _label(12, Color("a59cb4"))
	_boss_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	boss_v.add_child(_boss_sub)
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 6)
	stats.add_theme_constant_override("v_separation", 6)
	place.add_child(stats)
	_place_stats.clear()
	for key: String in ["DISTRICT_DIFFICULTY", "DISTRICT_LENGTH", "DISTRICT_STORIES", "DISTRICT_RECORD"]:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(146, 0)
		cell.add_theme_stylebox_override("panel", UiStyle.box(Color(0.07, 0.05, 0.1, 0.8), Color("3a3148")))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -2)
		cell.add_child(v)
		var k := _label(11, Color("a59cb4"))
		k.text = key
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(k)
		var val := _label(16, Color.WHITE)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(val)
		_place_stats.append(val)
		stats.add_child(cell)
	# A night report: what you win, and what happens if you don't go.
	_report_box = PanelContainer.new()
	_report_box.add_theme_stylebox_override("panel", UiStyle.box(Color(0.07, 0.05, 0.1, 0.8), Color("3a3148")))
	place.add_child(_report_box)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	_report_box.add_child(rv)
	_report_win = _label(14, Color("b8f0a0"))
	_report_lose = _label(14, Color("ffb0a0"))
	for l: Label in [_report_win, _report_lose]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(290, 0)
		rv.add_child(l)
	# Getting home ready for the full moon: traps and guard cats.
	_moon_box = PanelContainer.new()
	_moon_box.add_theme_stylebox_override("panel", UiStyle.box(Color(0.12, 0.1, 0.05, 0.85), Color("8a6a2a")))
	place.add_child(_moon_box)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 4)
	_moon_box.add_child(mv)
	for entry: Array in [["trap", Profile.MOON_TRAP_PRICE], ["guard", Profile.MOON_GUARD_PRICE]]:
		var mrow := HBoxContainer.new()
		mrow.add_theme_constant_override("separation", 6)
		mv.add_child(mrow)
		var info := _label(13, Color("f4e4c0"))
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mrow.add_child(info)
		var buy := UiStyle.click_button(tr("MOON_BUY") % entry[1], 0, 13)
		buy.pressed.connect(_buy_moon.bind(entry[0]))
		mrow.add_child(buy)
		if entry[0] == "trap":
			_moon_traps = info
		else:
			_moon_guards = info
	# A resident's service for the next night.
	_service_box = PanelContainer.new()
	_service_box.add_theme_stylebox_override("panel", UiStyle.box(Color(0.06, 0.1, 0.08, 0.85), Color("3f7a5a")))
	place.add_child(_service_box)
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 6)
	_service_box.add_child(srow)
	_service_label = _label(13, Color("d6f5c4"))
	_service_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_service_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_service_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	srow.add_child(_service_label)
	_service_buy = UiStyle.click_button("", 0, 13)
	_service_buy.pressed.connect(func() -> void:
		var ok := Profile.buy_service(_resident)
		Audio.play("chest" if ok else "hurt", -8.0, 0.0)
		_refresh())
	srow.add_child(_service_buy)
	# Darkness of the chosen map: - and + (or the keys).
	var dark_row := HBoxContainer.new()
	dark_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dark_row.add_theme_constant_override("separation", 8)
	place.add_child(dark_row)
	_dark_minus = UiStyle.click_button("-", 32, 18)
	_dark_minus.pressed.connect(_change_darkness.bind(-1))
	dark_row.add_child(_dark_minus)
	_dark_label = _label(13, Color("c79bff"))
	_dark_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dark_label.custom_minimum_size = Vector2(230, 0)
	dark_row.add_child(_dark_label)
	_dark_plus = UiStyle.click_button("+", 32, 18)
	_dark_plus.pressed.connect(_change_darkness.bind(1))
	dark_row.add_child(_dark_plus)
	_place_stars = _label(11, GOLD)
	_place_stars.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_stars.custom_minimum_size = Vector2(296, 0)
	place.add_child(_place_stars)

	# Bottom: the cats, the chosen one's details, what you take along, and Play.
	var bottom_bar := PanelContainer.new()
	bottom_bar.add_theme_stylebox_override("panel", UiStyle.frame())
	bottom_bar.custom_minimum_size = Vector2(0, BOTTOM_HEIGHT)
	root.add_child(bottom_bar)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	bottom_bar.add_child(bottom)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	bottom.add_child(left)
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 70)
	left.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	scroll.add_child(row)
	for i in _ids.size():
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(58, 66)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(i))
		card.mouse_entered.connect(_on_card_hover.bind(i, true))
		card.mouse_exited.connect(_on_card_hover.bind(i, false))
		var preview := CatPreview.new()
		preview.cat_id = _ids[i]
		preview.locked = not Profile.is_unlocked(_ids[i])
		preview.zoom = 1.6
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(preview)
		# A little gold house on the cats whose home is the chosen map.
		var home := Control.new()
		home.mouse_filter = Control.MOUSE_FILTER_IGNORE
		home.draw.connect(func() -> void:
			var at := Vector2(home.size.x - 12, 9)
			home.draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 0), at + Vector2(0, -7), at + Vector2(8, 0)]), OUTLINE)
			home.draw_rect(Rect2(at + Vector2(-6, -1), Vector2(12, 9)), OUTLINE)
			home.draw_colored_polygon(PackedVector2Array([at + Vector2(-6, -1), at + Vector2(0, -6), at + Vector2(6, -1)]), GOLD)
			home.draw_rect(Rect2(at + Vector2(-4, 0), Vector2(8, 6)), GOLD)
			home.draw_rect(Rect2(at + Vector2(-1, 2), Vector2(2, 4)), OUTLINE))
		card.add_child(home)
		_home_marks.append(home)
		row.add_child(card)
		_cards.append(card)
		_previews.append(preview)
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 10)
	info.custom_minimum_size = Vector2(0, 34)
	left.add_child(info)
	_big = CatPreview.new()
	_big.custom_minimum_size = Vector2(44, 34)
	_big.zoom = 1.3
	_big.gear = true
	_big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(_big)
	_name = _label(21, Color.WHITE)
	info.add_child(_name)
	# The bonus chips sit in a clipped strip: however many there are, the
	# bar never grows or pushes Play off the screen.
	var chips_clip := Control.new()
	chips_clip.clip_contents = true
	chips_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chips_clip.size_flags_stretch_ratio = 1.6
	chips_clip.custom_minimum_size = Vector2(0, 30)
	chips_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(chips_clip)
	_chips = HBoxContainer.new()
	_chips.add_theme_constant_override("separation", 6)
	_chips.position = Vector2(0, 2)
	chips_clip.add_child(_chips)
	_weapon_icon = IconView.new("weapon", "SCRATCH", 28.0)
	info.add_child(_weapon_icon)
	_weapon_label = _label(14, GOLD)
	_weapon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info.add_child(_weapon_label)
	_desc = _label(13, Color("cfc3dc"))
	left.add_child(_desc)
	# Two full-width lines: the cat's record and what you take along, then
	# challenges, streak and the daily night.
	var loadout := HBoxContainer.new()
	loadout.add_theme_constant_override("separation", 22)
	left.add_child(loadout)
	_cat_stats = _label(13, Color("8f7ea3"))
	loadout.add_child(_cat_stats)
	_worn = _label(13, Color("c77dff"))
	loadout.add_child(_worn)
	_artifact_label = _label(13, Color("8fd3ff"))
	loadout.add_child(_artifact_label)
	_challenge_label = _label(13, Color("ff7a6a"))
	left.add_child(_challenge_label)
	# Never cut off: these lines shrink their font to fit (see _fit_lines).
	for l: Label in [_weapon_label, _cat_stats, _worn, _artifact_label, _challenge_label, _desc]:
		l.clip_text = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.set_meta("base_size", l.label_settings.font_size)
	var play := Button.new()
	play.custom_minimum_size = Vector2(210, 0)
	play.focus_mode = Control.FOCUS_NONE
	play.add_theme_font_size_override("font_size", 30)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		play.add_theme_color_override(state, Color("3a2100"))
	play.add_theme_stylebox_override("normal", UiStyle.gold_button(false))
	play.add_theme_stylebox_override("hover", UiStyle.gold_button(true))
	play.add_theme_stylebox_override("pressed", UiStyle.gold_button(true))
	play.pressed.connect(_start)
	bottom.add_child(play)
	_play = play

	_shop = ShopPanel.new()
	add_child(_shop)
	_shop.closed.connect(_refresh)
	_charms = CharmPanel.new()
	add_child(_charms)
	_charms.closed.connect(_refresh)
	_items = ItemPanel.new()
	add_child(_items)
	_items.closed.connect(_refresh)
	_artifacts = ArtifactPanel.new()
	add_child(_artifacts)
	_artifacts.closed.connect(_refresh)
	_journal = JournalPanel.new()
	add_child(_journal)
	_journal.closed.connect(_refresh)
	_challenges = ChallengePanel.new()
	add_child(_challenges)
	_challenges.closed.connect(_refresh)


## A small rounded badge with a row inside (child 0) for its content.
func _badge(fill: Color, edge: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiStyle.box(fill, edge)
	sb.content_margin_left = 6
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	return chip


## The bottom lines shrink their font until all of their text fits.
func _fit_lines() -> void:
	for l: Label in [_weapon_label, _cat_stats, _worn, _artifact_label, _challenge_label, _desc]:
		var base: int = l.get_meta("base_size", 13)
		var font := l.get_theme_font("font")
		l.label_settings.font_size = UiStyle.fit_size(font, l.text, maxf(l.size.x - 2.0, 40.0), base, 9)


## Shrinks the top buttons until the bar fits the screen's real width.
func _fit_top() -> void:
	var room := get_viewport_rect().size.x - 28.0 - 20.0 - 28.0 * 2.0 - 260.0
	UiStyle.fit_row(_top_buttons, maxf(room, 400.0))


func _process(delta: float) -> void:
	_t += delta
	if _play != null and _place == "" and Profile.is_stage_unlocked(_stage_ids[_stage_index]) and not (_moon_mode and not Profile.moon_full()):
		_play.modulate = Color(1, 1, 1).lerp(Color(1.18, 1.12, 0.95), 0.5 + 0.5 * sin(_t * 3.0))


func _on_card_hover(i: int, inside: bool) -> void:
	if inside:
		_hover = i
	elif _hover == i:
		_hover = -1
	_style_cards()


## The cat cards: the chosen one glows gold, the one under the mouse lights up.
func _style_cards() -> void:
	for i in _cards.size():
		var chosen := i == _index
		var fill := Color("5b4470") if chosen else (Color("4a3860") if i == _hover else Color(CARD, 0.9))
		var edge := GOLD if chosen else (Color("b9a8c9") if i == _hover else BORDER)
		var sb := UiStyle.box(fill, edge)
		sb.set_corner_radius_all(10)
		if chosen:
			sb.set_border_width_all(3)
			sb.shadow_color = Color(GOLD, 0.35)
			sb.shadow_size = 8
		_cards[i].add_theme_stylebox_override("panel", sb)


func _fill_chips(id: String, unlocked: bool) -> void:
	for c in _chips.get_children():
		c.queue_free()
	if not unlocked:
		return
	var bonus: Dictionary = GameData.cats[id].get("bonus", {})
	if bonus.is_empty():
		_chips.add_child(_chip(tr("BONUS_NONE"), Color("b9a8c9")))
	for key: String in bonus:
		if not BONUS_TEXT.has(key):
			continue
		var spec: Array = BONUS_TEXT[key]
		var value := float(bonus[key]) * float(spec[1])
		var shown := str(roundi(value))
		if absf(value - roundf(value)) > 0.01:
			shown = ("%.1f" % value).replace(".", tr("DECIMAL_SEP"))
		_chips.add_child(_chip(tr(spec[0]) % shown, spec[2]))


func _chip(text: String, color: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	var sb := UiStyle.box(Color(color, 0.16), Color(color, 0.8))
	sb.set_corner_radius_all(9)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	chip.add_theme_stylebox_override("panel", sb)
	var l := _label(14, color.lightened(0.3))
	l.text = text
	chip.add_child(l)
	return chip


func _refresh() -> void:
	var id := _ids[_index]
	var unlocked := Profile.is_unlocked(id)
	_style_cards()
	_fill_chips(id, unlocked)
	for i in _cards.size():
		_previews[i].walking = i == _index and unlocked
	_big.cat_id = id
	_big.locked = not unlocked
	_big.walking = unlocked
	var weapon: String = GameData.cats[id]["weapon"]
	_weapon_icon.id = weapon
	_weapon_icon.visible = unlocked and weapon != ""
	_weapon_icon.queue_redraw()
	if unlocked:
		_name.text = tr("CAT_%s_NAME" % id)
		_desc.text = tr("CAT_%s_DESC" % id)
		_weapon_label.text = tr("SELECT_START_WEAPON") % tr("WEAPON_%s_NAME" % weapon) if weapon != "" else tr("SELECT_NO_WEAPON")
		_cat_stats.text = tr("SELECT_CAT_STATS") % [Profile.get_stat("wins_cat:" + id), Profile.get_stat("best_level_cat:" + id), Profile.get_stat("bosses_cat:" + id)]
	else:
		_name.text = tr("SELECT_LOCKED")
		_desc.text = tr("CAT_%s_HINT" % id)
		_weapon_label.text = ""
		_cat_stats.text = ""
	var worn: Array = Profile.equipped_charms.map(func(c: String) -> String: return tr("CHARM_%s_NAME" % c))
	_worn.text = tr("SELECT_CHARMS") % ("—" if worn.is_empty() else ", ".join(worn))
	var arts: Array = Profile.equipped_artifacts.map(func(a: String) -> String: return tr("ARTIFACT_%s_NAME" % a))
	_artifact_label.text = tr("SELECT_ARTIFACTS") % ("—" if arts.is_empty() else ", ".join(arts))
	var ch: Array = Profile.challenges.map(func(c: String) -> String: return tr("CHALLENGE_%s_NAME" % c))
	_challenge_label.text = tr("SELECT_CHALLENGES") % ["—" if ch.is_empty() else ", ".join(ch), Profile.challenge_gold()]
	var plan := Profile.daily_plan()
	var done := Profile.has_flag("daily_win:" + Profile.today())
	_challenge_label.text += "      " + tr("SELECT_DAILY") % [tr("STAGE_%s_NAME" % plan["stage"]), ", ".join((plan["challenges"] as Array).map(func(c: String) -> String: return tr("CHALLENGE_%s_NAME" % c)))] + (" ✓" if done else "")
	_gold.text = tr("SELECT_GOLD") % Profile.gold
	if Profile.streak > 0 or Profile.best_streak > 0:
		_challenge_label.text = tr("SELECT_STREAK") % [Profile.streak, Profile.best_streak, roundi((Profile.streak_multiplier() - 1.0) * 100.0)] + "      " + _challenge_label.text
	_refresh_darkness(_stage_ids[_stage_index])
	_refresh_place()


## The side panel: what the chosen place is, who rules it and how you did.
func _refresh_place() -> void:
	var id := _place if _place != "" else _stage_ids[_stage_index]
	_district.select(id, _district.selected == "")
	_district.refresh()
	var pic := AtlasTexture.new()
	pic.atlas = _district.town_texture()
	pic.region = _district.view_rect(id)
	_place_pic.texture = pic
	var real := GameData.stages.has(id)
	var state := DistrictMap.place_state(id)
	_moon_box.visible = false
	_service_box.visible = false
	_boss_name.get_parent().get_parent().get_parent().visible = true
	_place_stars.visible = true
	var moon_n := Profile.nights_to_moon()
	_moon_chip.text = tr("MOON_TONIGHT") if moon_n == 0 else tr("MOON_COUNTDOWN") % moon_n
	if _report >= Profile.reports.size() or (_report >= 0 and Profile.reports[_report]["stage"] != id):
		_report = -1
	_district.selected_report = _report
	var rep: Dictionary = Profile.reports[_report] if _report >= 0 else {}
	_report_box.visible = not rep.is_empty()
	_place_stats[0].get_parent().get_parent().get_parent().visible = rep.is_empty()
	_stage_label.text = DistrictMap.place_name(id)
	var badge: Array = [["DISTRICT_NEW_MAP", Color("b8b0c8")], ["DISTRICT_LOCKED", Color("c9c2d4")], ["DISTRICT_YOURS", Color("7cf0b8")], ["DISTRICT_BOSS_LAND", Color("ff9a88")]][0 if not real else {"locked": 1, "yours": 2, "boss": 3}[state]]
	_place_badge.text = tr(badge[0])
	_place_badge.label_settings.font_color = badge[1]
	var story := tr("DISTRICT_%s_STORY" % id)
	if not rep.is_empty():
		var kind: String = rep["kind"]
		_place_badge.text = tr("REPORT_%s_NAME" % kind.to_upper())
		_place_badge.label_settings.font_color = DistrictMap.REPORT_LOOK[kind][1].lightened(0.45)
		var place_name := DistrictMap.place_name(id)
		match kind:
			"defend":
				story = tr("REPORT_DEFEND_STORY") % place_name
				_report_win.text = tr("REPORT_WIN_DEFEND") % [Profile.REPORT_DEFEND_MINUTES, Profile.REPORT_DEFEND_GOLD]
				var theft := mini(floori(Profile.gold * Profile.REPORT_THEFT), Profile.REPORT_THEFT_MAX)
				var left := Profile.REPORT_DEFEND_NIGHTS - int(rep["nights"])
				_report_lose.text = tr("REPORT_LOSE_DEFEND") % theft if left <= 1 else tr("REPORT_LOSE_DEFEND_LATER") % [left, theft]
			"hunt":
				story = tr("REPORT_HUNT_STORY") % place_name
				_report_win.text = tr("REPORT_WIN_HUNT") % Profile.REPORT_HUNT_GOLD
				_report_lose.text = tr("REPORT_LOSE_HUNT") % (Profile.REPORT_HUNT_NIGHTS - int(rep["nights"]))
			"trip":
				story = tr("REPORT_TRIP_STORY") % place_name
				_report_win.text = tr("REPORT_WIN_TRIP") % Profile.TRIP_GOLD
				_report_lose.text = tr("REPORT_LOSE_TRIP")
			"rescue":
				var who := tr("CAT_%s_NAME" % Profile.kidnapped)
				story = tr("REPORT_RESCUE_STORY") % [who, place_name]
				_report_win.text = tr("REPORT_WIN_RESCUE") % [Profile.REPORT_DEFEND_MINUTES, who]
				_report_lose.text = tr("REPORT_LOSE_RESCUE") % who
			_:
				story = tr("REPORT_GOLD_STORY") % place_name
				_report_win.text = tr("REPORT_WIN_GOLD")
				_report_lose.text = tr("REPORT_LOSE_GOLD")
		if rep["challenge"] != "":
			story += "\n" + tr("REPORT_CHALLENGE") % tr("CHALLENGE_%s_NAME" % rep["challenge"])
	if real and state == "locked" and tr("STAGE_%s_HINT" % id) != "":
		story += "\n🔒 " + tr("STAGE_%s_HINT" % id)
	if real and rep.is_empty() and Profile.TERRITORY_BONUS.has(id):
		var bonus := DistrictMap.stats_text(Profile.TERRITORY_BONUS[id])
		story += "\n" + (tr("TERRITORY_OWNED") % bonus if id in Profile.territories else tr("TERRITORY_HOW") % [Profile.TERRITORY_FLAGS, bonus])
	_place_story.text = story
	var boss: String = GameData.stages[id].get("final_boss", "") if real else ""
	_boss_pic.id = boss
	_boss_pic.known = state != "locked"
	_boss_name.text = tr("ENEMY_%s_NAME" % boss) if boss != "" and state != "locked" else "???"
	var nem_level := Profile.nemesis_level(boss) if boss != "" else 0
	if nem_level > 0:
		_boss_sub.text = tr("NEMESIS_SUB") % [tr("NEMESIS_TITLE_%d" % nem_level), nem_level]
		_boss_sub.label_settings.font_color = Color("ff8a7a")
	else:
		_boss_sub.text = tr("DISTRICT_FINAL_BOSS")
		_boss_sub.label_settings.font_color = Color("a59cb4")
	_dark_minus.get_parent().visible = real
	if real:
		var stories := DistrictMap.place_stories(id)
		var minutes := tr("DISTRICT_MINUTES")
		_place_stats[0].text = "%d / 5" % MapCard.difficulty(id)
		_place_stats[1].text = minutes % int(GameData.stages[id].get("duration_minutes", 20))
		_place_stats[2].text = "%d / %d" % [stories.x, stories.y]
		_place_stats[3].text = minutes % Profile.get_stat("best_minutes:" + id) if state != "locked" else "—"
		var n := DistrictMap.place_stars(id)
		_place_stars.text = "★".repeat(n) + "☆".repeat(3 - n) + "   " + tr("DISTRICT_STARS_HELP")
	else:
		for l in _place_stats:
			l.text = "?"
		_place_stars.text = ""
	var open := real and state != "locked"
	_play.text = (tr("REPORT_GO_%s" % rep["kind"].to_upper()) if not rep.is_empty() else tr("MENU_PLAY")) if open else "🔒"
	_play.modulate = Color.WHITE if open else Color(0.6, 0.6, 0.7)
	for i in _home_marks.size():
		_home_marks[i].visible = GameData.cats[_ids[i]].get("home", "") == id and Profile.is_unlocked(_ids[i])
	_fill_home(id)
	_fit_lines.call_deferred()
	if _moon_mode:
		_show_moon()
	elif _resident != "":
		_show_resident()


## The side panel for a resident: who it is and what it offers tonight.
func _show_resident() -> void:
	var cat := _resident
	_stage_label.text = tr("CAT_%s_NAME" % cat)
	_place_badge.text = tr("RESIDENT_TITLE")
	_place_badge.label_settings.font_color = Color("9fe1cb")
	_place_stats[0].get_parent().get_parent().get_parent().visible = false
	_boss_name.get_parent().get_parent().get_parent().visible = false
	_dark_minus.get_parent().visible = false
	_place_stars.visible = false
	_report_box.visible = false
	if cat == Profile.kidnapped:
		_place_story.text = tr("RESIDENT_KIDNAPPED") % tr("CAT_%s_NAME" % cat)
		return
	_place_story.text = tr("RESIDENT_%s_DESC" % cat)
	_service_box.visible = true
	var price := int(Profile.RESIDENTS[cat][1])
	_service_label.text = tr("RESIDENT_%s_SERVICE" % cat)
	if cat in Profile.services:
		_service_buy.text = tr("RESIDENT_BOUGHT")
		_service_buy.disabled = true
	else:
		_service_buy.text = tr("MOON_BUY") % price
		_service_buy.disabled = false


func _on_resident_chosen(cat: String) -> void:
	Audio.play("click", -6.0, 0.0)
	_resident = cat
	_moon_mode = false
	_report = -1
	_refresh()


## The side panel for the full moon: what comes, how ready home is, and
## what winning or losing means.
func _show_moon() -> void:
	var n := Profile.nights_to_moon()
	_place_badge.text = tr("MOON_NAME")
	_place_badge.label_settings.font_color = Color("ffe08a")
	var bosses: Array[String] = []
	for sid: String in GameData.stages:
		var boss: String = GameData.stages[sid].get("final_boss", "")
		if sid != "LIVING_ROOM" and boss != "" and Profile.is_stage_unlocked(sid):
			bosses.append(tr("ENEMY_%s_NAME" % boss))
	_place_story.text = (tr("MOON_STORY_TONIGHT") if n == 0 else tr("MOON_STORY_SOON") % n) + "\n" + tr("MOON_COMING") % (", ".join(bosses) if not bosses.is_empty() else tr("ENEMY_RAT_KING_NAME"))
	_place_stats[0].get_parent().get_parent().get_parent().visible = false
	_report_box.visible = true
	_report_win.text = tr("MOON_WIN") % Profile.MOON_GOLD
	_report_lose.text = tr("MOON_LOSE") % mini(floori(Profile.gold * Profile.MOON_THEFT), Profile.MOON_THEFT_MAX)
	_moon_box.visible = true
	# The home's own boss, darkness and stars don't matter on the full moon.
	_boss_name.get_parent().get_parent().get_parent().visible = false
	_dark_minus.get_parent().visible = false
	_place_stars.visible = false
	_moon_traps.text = tr("MOON_TRAPS") % [Profile.moon_traps, Profile.MOON_TRAPS_MAX]
	var guards: Array = Profile.moon_guards.map(func(c: String) -> String: return tr("CAT_%s_NAME" % c))
	_moon_guards.text = tr("MOON_GUARDS") % ["—" if guards.is_empty() else ", ".join(guards)]
	_play.text = tr("MOON_GO") if n == 0 else tr("MOON_COUNTDOWN") % n
	_play.modulate = Color.WHITE if n == 0 else Color(0.6, 0.6, 0.7)


func _buy_moon(what: String) -> void:
	var ok := Profile.buy_moon_trap() if what == "trap" else Profile.buy_moon_guard() != ""
	Audio.play("chest" if ok else "hurt", -8.0, 0.0)
	_refresh()


func _on_moon_chosen() -> void:
	Audio.play("click", -6.0, 0.0)
	_resident = ""
	_moon_mode = true
	_report = -1
	_place = ""
	_stage_index = maxi(_stage_ids.find("LIVING_ROOM"), 0)
	_refresh()


## The chosen cat's home: its bonus here, or where its home is.
func _fill_home(id: String) -> void:
	var cat := _ids[_index]
	var home: String = GameData.cats[cat].get("home", "")
	if home == "" or not Profile.is_unlocked(cat):
		return
	if home == id:
		_chips.add_child(_chip(tr("HOME_HERE") % DistrictMap.home_text(cat), GOLD))
	else:
		_chips.add_child(_chip(tr("HOME_AT") % tr("STAGE_%s_NAME" % home), Color("b9a8c9")))


func _on_report_chosen(i: int) -> void:
	Audio.play("click", -6.0, 0.0)
	_resident = ""
	_moon_mode = false
	_report = i
	_place = ""
	_stage_index = _stage_ids.find(Profile.reports[i]["stage"])
	_refresh()


func _on_place_chosen(id: String) -> void:
	Audio.play("click", -6.0, 0.0)
	_resident = ""
	_moon_mode = false
	_report = -1
	if GameData.stages.has(id):
		_place = ""
		_stage_index = _stage_ids.find(id)
	else:
		_place = id
	_refresh()


func _change_darkness(step: int) -> void:
	var stage_id := _stage_ids[_stage_index]
	var top := Profile.max_darkness(stage_id)
	if top == 0:
		Audio.play("hurt", -12.0, 0.0)
		return
	Profile.set_darkness(stage_id, Profile.darkness_for(stage_id) + step)
	Audio.play("click", -6.0, 0.0)
	_refresh()


func _refresh_darkness(stage_id: String) -> void:
	var top := Profile.max_darkness(stage_id)
	var level := Profile.darkness_for(stage_id)
	_dark_minus.visible = top > 0
	_dark_plus.visible = top > 0
	if top == 0:
		_dark_label.text = tr("SELECT_DARKNESS_LOCKED")
	elif level == 0:
		_dark_label.text = tr("SELECT_DARKNESS_OFF") % top
	else:
		_dark_label.text = tr("SELECT_DARKNESS") % [level, roundi(Spawner.DARKNESS_HP * level * 100.0), roundi(Spawner.DARKNESS_GOLD * level * 100.0)]


func _unhandled_input(event: InputEvent) -> void:
	if _shop.visible or _charms.visible or _items.visible or _journal.visible or _challenges.visible or _artifacts.visible:
		return
	if event.is_action_pressed("challenges"):
		Audio.play("click", -6.0, 0.0)
		_challenges.open()
		return
	for entry: Array in [["questbook", "quests"], ["goals", "goals"], ["journal", "bestiary"]]:
		if event.is_action_pressed(entry[0]):
			Audio.play("click", -6.0, 0.0)
			_journal.open(entry[1])
			return
	if event.is_action_pressed("shop"):
		Audio.play("click", -6.0, 0.0)
		_shop.open()
	elif event.is_action_pressed("items"):
		Audio.play("click", -6.0, 0.0)
		_items.open()
	elif event.is_action_pressed("charms"):
		Audio.play("click", -6.0, 0.0)
		_charms.open()
	elif event.is_action_pressed("artifacts"):
		Audio.play("click", -6.0, 0.0)
		_artifacts.open()
	elif event.is_action_pressed("daily"):
		_start_daily()
	elif event.is_action_pressed("darkness_down"):
		_change_darkness(-1)
	elif event.is_action_pressed("darkness_up"):
		_change_darkness(1)
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_index = (_index - 1 + _ids.size()) % _ids.size()
		Audio.play("click", -6.0, 0.0)
		_refresh()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_index = (_index + 1) % _ids.size()
		Audio.play("click", -6.0, 0.0)
		_refresh()
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_place = ""
		_report = -1
		_moon_mode = false
		_resident = ""
		_stage_index = (_stage_index - 1 + _stage_ids.size()) % _stage_ids.size()
		Audio.play("click", -6.0, 0.0)
		_refresh()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_place = ""
		_report = -1
		_moon_mode = false
		_resident = ""
		_stage_index = (_stage_index + 1) % _stage_ids.size()
		Audio.play("click", -6.0, 0.0)
		_refresh()
	elif event.is_action_pressed("pause"):
		Audio.play("click", -6.0, 0.0)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	elif event.is_action_pressed("language"):
		Settings.cycle_language()
		_refresh()
	elif event.is_action_pressed("mute"):
		Settings.toggle_mute()
	elif event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		_start()


func _on_card_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if i == _index:
			_start()
		else:
			_index = i
			_refresh()


## The daily night with the chosen cat: today's map, challenges and seed.
func _start_daily() -> void:
	var id := _ids[_index]
	if not Profile.is_unlocked(id):
		Audio.play("hurt", -10.0, 0.0)
		return
	Profile.select(id)
	Profile.start_daily()
	# The same floor and the same luck for everyone today.
	seed(int(Profile.daily_plan()["seed"]))
	Audio.play("select", -4.0, 0.0)
	get_tree().change_scene_to_file(MAIN_SCENE)


func _start() -> void:
	var id := _ids[_index]
	var stage_id := _stage_ids[_stage_index]
	if _moon_mode and not Profile.moon_full():
		Audio.play("hurt", -10.0, 0.0)
		return
	if _place != "" or not Profile.is_unlocked(id) or not Profile.is_stage_unlocked(stage_id):
		Audio.play("hurt", -10.0, 0.0)
		return
	Profile.select_stage(stage_id)
	Profile.select(id)
	if _moon_mode:
		Profile.start_moon()
	elif _report >= 0:
		Profile.start_report(_report)
	Audio.play("select", -4.0, 0.0)
	get_tree().change_scene_to_file(MAIN_SCENE)


func _label(size: int, font_color: Color) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = font_color
	settings.outline_size = 5
	settings.outline_color = OUTLINE
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## The final boss of the chosen place, gently animated; a silhouette while
## the place is still locked.
class BossPortrait extends Control:
	var id := ""
	var known := true
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("2a1f2e"))
		var at := size * 0.5
		if id == "" or not GameData.enemies.has(id):
			draw_string(ThemeDB.fallback_font, Vector2(0, size.y * 0.68), "?", HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Color("8f7ea3"))
			return
		var data: Dictionary = GameData.enemies[id]
		var shade := Color.WHITE if known else Color(0.12, 0.09, 0.15)
		if data.get("shape", "") == "cat":
			var lk := CatArt.look(data.get("cat", "MICA")).duplicate()
			if not known:
				for key: String in ["fur", "dark", "belly", "eyes"]:
					lk[key] = shade
				lk["silhouette"] = true
			CatArt.draw(self, lk, 1, _t * 4.0, false, false, "angry", at + Vector2(0, 6), 1.3, false)
			return
		var sprite := Sprites.enemy(id)
		if sprite.is_empty():
			return
		draw_set_transform(at, 0.0, Vector2(1.6, 1.6))
		Sprites.draw_frame(self, sprite, int(_t * 3.0) % 2, 0, shade)
		draw_set_transform(Vector2.ZERO)
