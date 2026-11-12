extends Control
## Title screen: play, upgrades shop, goals, settings, quit.
## Any debug flag on the command line skips straight into a run.

const SELECT_SCENE := "res://scenes/character_select.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"
## Flags that keep the menu up instead of jumping into a run.
const PANEL_FLAGS := ["--shop", "--goals", "--questbook", "--journal", "--settings", "--ui-test", "--no-save", "--open-all", "--dev-launcher"]

var _shop: ShopPanel
var _journal: JournalPanel
var _settings: SettingsPanel
var _buttons: VBoxContainer
var _status: Label
var _cats: Array[CatPreview] = []
var _cat_speed: Array[float] = []
var _title: BoxBoard
var _status_board: BoxBoard
var _t := 0.0
const TIPS := 10


func _ready() -> void:
	GameData.dev_args.clear()
	var args := GameData.args()
	if "--dev-launcher" in args and not DevLauncher.opened_once:
		get_tree().change_scene_to_file.call_deferred(DevLauncher.SCENE)
		return
	for arg: String in args:
		if arg.begins_with("--") and arg not in PANEL_FLAGS:
			get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
			return
	_build()
	Audio.play_music("music_menu")
	if "--shop" in args:
		_open(_shop)
	elif "--goals" in args:
		_open(_journal, "goals")
	elif "--questbook" in args:
		_open(_journal, "quests")
	elif "--journal" in args:
		_open(_journal, "bestiary")
	elif "--settings" in args:
		_open(_settings)


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiStyle.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Night over the city (tools/gen_title.py), pixel-sharp at any size.
	var art := TextureRect.new()
	art.texture = load("res://assets/title.png")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	add_child(MenuSky.new())

	# A parade along the bottom: the cats you have unlocked stroll across
	# the rooftops (the rest follow as shadows).
	var ids: Array = GameData.cats.keys().filter(func(id: String) -> bool: return not GameData.cats[id].get("npc", false) and (not GameData.cats[id].get("hidden", false) or Profile.is_unlocked(id)))
	var gap := 1400.0 / maxf(ids.size(), 1)
	var i := 0
	for id: String in ids:
		var cat := CatPreview.new()
		cat.cat_id = id
		cat.locked = not Profile.is_unlocked(id)
		cat.walking = true
		cat.size = Vector2(120, 120)
		cat.position = Vector2(-120 + i * gap, 560)
		cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cat)
		_cats.append(cat)
		_cat_speed.append(38.0 + float(i % 3) * 6.0)
		i += 1

	_build_title()
	_buttons = VBoxContainer.new()
	_buttons.position = Vector2(70, 298)
	_buttons.add_theme_constant_override("separation", 12)
	add_child(_buttons)
	_status_board = BoxBoard.make("light", Vector2(700, 128), Vector2(486, 110), 31, 1.0)
	add_child(_status_board)
	_status = BoxStyle.label("", 20)
	_status.position = Vector2(46, 14)
	_status_board.add_child(_status)
	add_child(BoxBoard.make("tape", Vector2(662, 112), Vector2(90, 33), 5, -8.0))
	_build_tip()
	var play := func() -> void:
		Audio.play("select", -4.0, 0.0)
		get_tree().change_scene_to_file(SELECT_SCENE)
	_add_button("MENU_PLAY", play, 44, 11, -1.2, 300)
	_shop = ShopPanel.new()
	_journal = JournalPanel.new()
	_settings = SettingsPanel.new()
	_add_button("MENU_UPGRADES", func() -> void: _open(_shop), 34, 22, 0.9, 270)
	_add_button("MENU_JOURNAL", func() -> void: _open(_journal), 34, 33, -0.6, 240)
	_add_button("MENU_SETTINGS", func() -> void: _open(_settings), 34, 44, 1.4, 280)
	# After the end of the story: its titles again.
	if Profile.has_flag("game_won"):
		var show_credits := func() -> void:
			var credits := CreditsPanel.new()
			add_child(credits)
			credits.finished.connect(func() -> void: (_buttons.get_child(0) as Control).grab_focus())
		_add_button("MENU_CREDITS", show_credits, 34, 77, -1.0, 260)
	_add_button("MENU_QUIT", func() -> void: get_tree().quit(), 30, 55, -1.6, 180)
	# Dev builds only (the editor, the launchers): the test launcher.
	if OS.is_debug_build():
		var dev := BoxButton.make("DEV", 20, 66, -2.0, false, true, 70.0)
		dev.position = Vector2(1280 - 12 - dev.custom_minimum_size.x, 70)
		dev.pressed.connect(func() -> void: get_tree().change_scene_to_file(DevLauncher.SCENE))
		add_child(dev)
	# The language in the corner, so a new player finds it right away; a
	# click switches to the next one (the menu is rebuilt in it).
	var lang := BoxButton.make("%s: %s" % [tr("SET_LANGUAGE"), tr("LANGUAGE_NAME")], 20, 88, 1.5, false, true, 190.0)
	lang.position = Vector2(1280 - 14 - lang.custom_minimum_size.x, 14)
	lang.pressed.connect(func() -> void:
		Settings.cycle_language()
		get_tree().reload_current_scene())
	add_child(lang)
	for panel: Control in [_shop, _journal, _settings]:
		add_child(panel)
		panel.closed.connect(_on_panel_closed)
	_refresh()
	_wrap_focus()
	(_buttons.get_child(0) as Button).grab_focus.call_deferred()
	# After an update: what's new, once.
	if NewsPanel.should_show():
		var news := NewsPanel.new()
		add_child(news)
		news.closed.connect(_on_panel_closed)
		_open.call_deferred(news)


## The name on a cardboard sign (turned a little), a red marker line under
## it, a paw stamp in the corner, tape over a corner and the tagline on tape.
func _build_title() -> void:
	_title = BoxBoard.make("board", Vector2(58, 32), Vector2(589, 192), 2, -2.0)
	add_child(_title)
	var head := BoxStyle.head_font()
	var name_label := BoxStyle.label("Cat Survivors", BoxStyle.fit_size("Cat Survivors", head, 106, 520.0), BoxStyle.INK, true)
	name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_label.offset_top = 8
	name_label.offset_bottom = 150
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_child(name_label)
	_title.add_child(BoxBoard.make("scribble", Vector2(64, 144), Vector2(461, 26), 9))
	_title.add_child(BoxBoard.make("stamp", Vector2(470, -32), Vector2(102, 102), 4, 16.0))
	_title.add_child(BoxBoard.make("tape", Vector2(-12, 6), Vector2(102, 36), 3, -38.0))
	var tag := tr("MENU_TAGLINE")
	var tag_size := 24
	var body := BoxStyle.body_font()
	var tag_w := minf(body.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size).x + 64.0, 560.0)
	tag_size = BoxStyle.fit_size(tag, body, tag_size, tag_w - 64.0)
	var tape := BoxBoard.make("tape", Vector2(90, 246), Vector2(maxf(tag_w, 300.0), 44), 7, 1.2)
	add_child(tape)
	var tag_label := BoxStyle.label("MENU_TAGLINE", tag_size)
	tag_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tape.add_child(tag_label)


## The tip on tape at the bottom right (two lines when it is long).
func _build_tip() -> void:
	var text := tr("MENU_TIP") % tr("MENU_TIP_%d" % randi_range(1, TIPS))
	var body := BoxStyle.body_font()
	var tip_size := 19
	var inner := minf(body.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, tip_size).x, 680.0)
	var h := body.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, inner + 4.0, tip_size).y
	var tape := BoxBoard.make("tape", Vector2(1280.0 - 40.0 - inner - 64.0, 720.0 - 34.0 - h - 20.0), Vector2(inner + 64.0, h + 20.0), 8, -0.8)
	add_child(tape)
	var l := BoxStyle.label(text, tip_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.position = Vector2(32, 10)
	l.size = Vector2(inner + 4.0, h)
	tape.add_child(l)


## Up from the first button goes to the last and down from the last to the
## first.
func _wrap_focus() -> void:
	var list := _buttons.get_children()
	for i in list.size():
		var b: Button = list[i]
		b.focus_neighbor_top = b.get_path_to(list[(i - 1 + list.size()) % list.size()])
		b.focus_neighbor_bottom = b.get_path_to(list[(i + 1) % list.size()])


## W and S move through the menu too.
func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null or focus.get_parent() != _buttons:
		return
	var key := (event as InputEventKey).physical_keycode
	if key == KEY_W or key == KEY_S:
		var next := focus.get_node(focus.focus_neighbor_top if key == KEY_W else focus.focus_neighbor_bottom) as Control
		if next != null:
			next.grab_focus()
			get_viewport().set_input_as_handled()


func _add_button(text: String, action: Callable, size_px: int, look: int, tilt: float, min_width: float) -> void:
	var b := BoxButton.make(text, size_px, look, tilt, true, false, min_width)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(action)
	_buttons.add_child(b)
	# The focused / hovered button grows a little.
	var grow := func(big: bool) -> void:
		b.pivot_offset = b.size * 0.5
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(1.06, 1.06) if big else Vector2.ONE, 0.08)
	b.focus_entered.connect(grow.bind(true))
	b.focus_exited.connect(grow.bind(false))


func _open(panel: Control, tab: String = "") -> void:
	Audio.play("click", -6.0, 0.0)
	# Otherwise the arrows and Enter would still drive the menu buttons hidden
	# behind the panel (Enter could even press Quit).
	get_viewport().gui_release_focus()
	_set_menu_focusable(false)
	if panel is JournalPanel:
		(panel as JournalPanel).open(tab)
	else:
		panel.call("open")


func _on_panel_closed() -> void:
	_set_menu_focusable(true)
	_refresh()
	(_buttons.get_child(0) as Button).grab_focus.call_deferred()


## While a panel is open the menu buttons can't take focus, so arrow keys in
## the panel can never wander onto them.
func _set_menu_focusable(on: bool) -> void:
	for b: Button in _buttons.get_children():
		b.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE


func _refresh() -> void:
	var line := tr("SELECT_GOLD") % Profile.gold
	if Profile.best_streak > 0:
		line += "   ·   " + tr("SELECT_STREAK") % [Profile.streak, Profile.best_streak, roundi((Profile.streak_multiplier() - 1.0) * 100.0)]
	var stories: int = GameData.chains.keys().filter(func(c: String) -> bool: return ChainStep.is_done(c)).size()
	line += "\n" + tr("MENU_PROGRESS") % [stories, GameData.chains.size(), Profile.achievements.size(), GameData.achievements.size()]
	var font := BoxStyle.body_font()
	var size_px := 20
	var lines := line.split("\n")
	for l: String in lines:
		size_px = mini(size_px, BoxStyle.fit_size(l, font, 20, 520.0))
	_status.label_settings.font_size = size_px
	_status.text = line
	var widest := 0.0
	for l: String in lines:
		widest = maxf(widest, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x)
	var line_h := font.get_height(size_px)
	_status.size = Vector2(widest, line_h * lines.size())
	_status_board.size = Vector2(widest + 72.0, line_h * lines.size() + 30.0)
	_status_board.position.x = 1280.0 - 45.0 - _status_board.size.x
	_status_board.bullets.clear()
	for i in lines.size():
		_status_board.bullets.append(Vector2(28.0, 14.0 + line_h * (i + 0.5)))
	_status_board.bullet_size = size_px * 0.95
	_status_board.queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _title != null:
		_title.position.y = 32.0 + sin(_t * 1.6) * 3.0
	# The parade strolls to the right and comes round again.
	for i in _cats.size():
		var cat := _cats[i]
		cat.position.x += _cat_speed[i] * delta
		if cat.position.x > size.x + 20.0:
			cat.position.x -= size.x + 160.0
		cat.position.y = 560 + sin(_t * 2.0 + i) * 2.0
