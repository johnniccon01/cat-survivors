extends Control
## Title screen: play, upgrades shop, charms, goals, settings, quit.
## Any debug flag on the command line skips straight into a run.

const SELECT_SCENE := "res://scenes/character_select.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"
## Flags that keep the menu up instead of jumping into a run.
const PANEL_FLAGS := ["--shop", "--charms", "--goals", "--questbook", "--journal", "--settings", "--ui-test", "--no-save"]

var _shop: ShopPanel
var _charms: CharmPanel
var _journal: JournalPanel
var _settings: SettingsPanel
var _buttons: VBoxContainer
var _status: Label
var _cats: Array[CatPreview] = []
var _t := 0.0


func _ready() -> void:
	var args := GameData.args()
	for arg: String in args:
		if arg.begins_with("--") and arg not in PANEL_FLAGS:
			get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
			return
	_build()
	Audio.play_music("music_menu")
	if "--shop" in args:
		_open(_shop)
	elif "--charms" in args:
		_open(_charms)
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

	# A little parade of the cats you have unlocked, walking along the bottom.
	var ids: Array = GameData.cats.keys().filter(func(id: String) -> bool: return not GameData.cats[id].get("npc", false) and (not GameData.cats[id].get("hidden", false) or Profile.is_unlocked(id)))
	var gap := 1040.0 / maxf(ids.size() - 1, 1)
	var i := 0
	for id: String in ids:
		var cat := CatPreview.new()
		cat.cat_id = id
		cat.locked = not Profile.is_unlocked(id)
		cat.walking = not cat.locked
		cat.size = Vector2(120, 120)
		cat.position = Vector2(60 + i * gap, 560)
		cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cat)
		_cats.append(cat)
		i += 1

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.offset_top = 28
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.add_child(UiStyle.label("Cat Survivors", 64, UiStyle.GOLD))
	box.add_child(UiStyle.label("MENU_TAGLINE", 20, UiStyle.MUTED))
	_status = UiStyle.label("", 18, UiStyle.GOLD)
	box.add_child(_status)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 8)
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_buttons)
	_add_button("MENU_PLAY", func() -> void:
		Audio.play("select", -4.0, 0.0)
		get_tree().change_scene_to_file(SELECT_SCENE))
	_shop = ShopPanel.new()
	_charms = CharmPanel.new()
	_journal = JournalPanel.new()
	_settings = SettingsPanel.new()
	_add_button("MENU_UPGRADES", func() -> void: _open(_shop))
	_add_button("MENU_CHARMS", func() -> void: _open(_charms))
	_add_button("MENU_JOURNAL", func() -> void: _open(_journal))
	_add_button("MENU_SETTINGS", func() -> void: _open(_settings))
	_add_button("MENU_QUIT", func() -> void: get_tree().quit())
	for panel: Control in [_shop, _charms, _journal, _settings]:
		add_child(panel)
		panel.closed.connect(_on_panel_closed)
	_refresh()
	_wrap_focus()
	(_buttons.get_child(0) as Button).grab_focus.call_deferred()


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


func _add_button(text: String, action: Callable) -> void:
	var b := UiStyle.button(text, 340)
	b.pressed.connect(action)
	_buttons.add_child(b)


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
	_status.text = line


func _process(delta: float) -> void:
	_t += delta
	# Gentle bob so the parade feels alive.
	for i in _cats.size():
		_cats[i].position.y = 560 + sin(_t * 2.0 + i) * 4.0
