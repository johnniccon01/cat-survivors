class_name DevPanel
extends CanvasLayer
## Development-only cheats (F1 to show/hide; the game pauses while it is
## open). Only created in debug builds, so exported release builds never
## contain it. Remove before release.
## Tabs: Run (time, cat, world), Build (every weapon, passive, evolution and
## branch at any level), Enemies (spawn any enemy, training dummies, DPS
## meter), Bosses and Quests (start any of them right here). The tick boxes
## are a checklist of what has been tried (saved apart from the profile in
## CHECKLIST); a boss beaten or a quest finished in a test ticks itself.
## Runs from the dev launcher (DevLauncher) start with these set up.

const CHECKLIST := "user://dev_checklist.json"
## The build saved with "Save as my build" (the launcher can start with it).
const BUILD_FILE := "user://dev_build.json"
const TABS := ["Run", "Build", "Enemies", "Bosses", "Quests"]
const RED := Color("e04646")
const DIM := Color(0.62, 0.56, 0.7)

var main: Node

var _panel: PanelContainer
var _revive_button: Button
var _god_button: Button
var _terrain_button: Button
var _search: LineEdit
var _boss_head: Label
var _quest_head: Label
## Rows of the two lists: {"key", "text", "node", "box"}.
var _rows: Array[Dictionary] = []
## "BOSS:id" / "QUEST:id" -> true for everything already tried.
var _checks := {}
## Whether the game was already paused when the panel opened.
var _was_paused := false
## The boss under test and, in a boss rush, the ones still to come.
var _test_boss: Enemy
var _test_id := ""
var _testing := false
var _rush: Array[String] = []
var _rush_total := 0
var _rush_wait := 0.0
var _sandbox_label: Label
## The quest started from the list, ticked off when it is done.
var _test_quest_id := ""
## --dev-quest-all: the quests still to start, one every few seconds.
var _quest_cycle: Array[String] = []
var _quest_cycle_t := 0.0
var _tabs: TabContainer
## Build tab: id -> {"level": Label, "extra": Control...} for refreshing.
var _weapon_rows := {}
var _passive_rows := {}
var _build_info: Label
## Rows of the plain lists (build, enemies): {"text", "node"} for the search.
var _plain_rows: Array[Dictionary] = []
var _calm_button: Button
var _speed_button: Button
var _spawn_count := 1
var _dummies := false
var _dummy_button: Button
var _count_button: Button
var _dps_label: Label
var _dps_on := false
var _dps_t := 0.0
## Damage per weapon a second ago, and the last few seconds' gains.
var _dps_last := {}
var _dps_window: Array[Dictionary] = []


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_checks()
	var hint := Label.new()
	hint.text = "DEV: F1"
	hint.position = Vector2(12, 668)
	hint.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 0.6))
	hint.add_theme_font_size_override("font_size", 12)
	add_child(hint)
	_panel = PanelContainer.new()
	_panel.position = Vector2(16, 16)
	_panel.custom_minimum_size = Vector2(1248, 688)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.11, 0.96)
	sb.border_color = RED
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	_panel.visible = false
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	_panel.add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	var title := Label.new()
	title.text = "DEV  ·  game paused  ·  F1 / Esc closes"
	title.add_theme_color_override("font_color", RED)
	head.add_child(title)
	_search = LineEdit.new()
	_search.placeholder_text = "Search (weapons, passives, enemies, bosses, quests)..."
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.clear_button_enabled = true
	_search.text_changed.connect(func(_t: String) -> void: _filter())
	head.add_child(_search)
	_button(head, "Close", _close)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.focus_mode = Control.FOCUS_NONE
	root.add_child(_tabs)
	_build_actions(_tab("Run"))
	_build_build_tab(_tab("Build"))
	_build_enemies_tab(_tab("Enemies"))
	var bosses := _tab("Bosses")
	_boss_head = _list_head(bosses, "Boss rush (all)", _start_boss_rush)
	_build_bosses(_scroll(bosses))
	var quests := _tab("Quests")
	_quest_head = _list_head(quests, "", Callable())
	_build_quests(_scroll(quests))
	_count()
	_dps_label = Label.new()
	_dps_label.position = Vector2(980, 90)
	_dps_label.add_theme_font_size_override("font_size", 13)
	_dps_label.add_theme_color_override("font_color", Color("ffe9a8"))
	_dps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_dps_label.add_theme_constant_override("outline_size", 4)
	_dps_label.visible = false
	add_child(_dps_label)


func _build_actions(col: VBoxContainer) -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(cols)
	var list := _scroll(_column(cols, 300))
	_section(list, "Time")
	_button(list, "+1 min (+levels)", func() -> void: _skip(60.0))
	_button(list, "+5 min (+levels)", func() -> void: _skip(300.0))
	_button(list, "+5 min (time only)", func() -> void: _act(func() -> void: _skip_time(300.0)))
	for minute in [10, 15, 20]:
		_button(list, "Go to minute %d (as played)" % minute, func() -> void: _act(func() -> void: _go_to_minute(minute)))
	_revive_button = _button(list, "Revive on death: ON", _toggle_revive)
	_button(list, "Final boss now", func() -> void: _act(_final_boss))
	_button(list, "Endless night now", func() -> void: _act(_endless_now))
	_speed_button = _button(list, "Game speed: 1x", _next_speed)
	list = _scroll(_column(cols, 300))
	_section(list, "Cat")
	_god_button = _button(list, "God mode: %s" % ("ON" if "--god" in GameData.args() or "--dev-lab" in GameData.args() else "OFF"), _toggle_god)
	_button(list, "+5 levels", _levels)
	_button(list, "Strong build (test)", _strong_build)
	_button(list, "Heal", func() -> void: main.player.heal(9999.0))
	_button(list, "+1000 gold (saved)", func() -> void: Profile.add_gold(1000))
	_button(list, "Drop a charm", func() -> void: main._maybe_drop_charm(main.player.position + Vector2(30, 0), 1.0))
	_button(list, "Find an item (rare)", func() -> void: main._find_item(Items.roll(main.player.stat("luck"), "rare")))
	_button(list, "Find this map's legendary", _find_legendary)
	_button(list, "Unlock angel + devil cats (saved)", func() -> void:
		for id: String in ["ANGEL", "DEVIL"]:
			Profile.unlock(id))
	_button(list, "Level up (choose a card)", func() -> void: _act(func() -> void: main.player.add_xp(main.player.xp_to_next() - main.player.xp + 0.1)))
	_button(list, "Treasure chest (as in the run)", func() -> void: _act(func() -> void: main._queue_modal("boss_chest")))
	list = _scroll(_column(cols, 300))
	_section(list, "World")
	_button(list, "Kill all enemies", func() -> void: main.enemies.clear_all())
	_button(list, "Open cat flap", func() -> void: _act(func() -> void: main._open_extraction(true)))
	_terrain_button = _button(list, "Terrain: %s" % (Terrain.current.kind if Terrain.current != null else "none"), _next_terrain)
	_button(list, "Angel cat now", func() -> void: _act(main.summon_angel))
	_button(list, "Death (devil cat) now", func() -> void: _act(main.summon_devil))
	_section(list, "Weather")
	var weather := HFlowContainer.new()
	list.add_child(weather)
	for kind: String in Weather.KINDS:
		_button(weather, kind.capitalize(), func() -> void: _set_weather(kind))
	_section(list, "Shrine next to the cat")
	var shrines := HFlowContainer.new()
	list.add_child(shrines)
	for kind: String in Shrine.KINDS:
		_button(shrines, kind.capitalize(), func() -> void: _act(func() -> void: _shrine(kind)))
	_section(list, "Trap next to the cat")
	var traps := HFlowContainer.new()
	list.add_child(traps)
	for id: String in GameData.traps:
		_button(traps, id.capitalize(), func() -> void: _act(func() -> void: _trap(id)))
	list = _scroll(_column(cols, 300))
	_section(list, "Random quest")
	_button(list, "Cat quest now", func() -> void: _act(func() -> void: _quest("cat")))
	_button(list, "Side quest now", func() -> void: _act(func() -> void: _quest("side")))
	_button(list, "Story step now", func() -> void: _act(func() -> void: _quest("chain")))


## Bosses grouped by the map you meet them on; the rest at the end.
func _build_bosses(list: VBoxContainer) -> void:
	var seen: Array[String] = []
	for stage_id: String in GameData.stages:
		var stage: Dictionary = GameData.stages[stage_id]
		var ids: Array[String] = []
		for w: Dictionary in stage["waves"]:
			for b: String in w.get("bosses", []):
				if b not in seen and GameData.enemies.has(b):
					ids.append(b)
					seen.append(b)
		var final_id: String = stage.get("final_boss", "")
		if final_id != "" and final_id not in seen:
			ids.append(final_id)
			seen.append(final_id)
		if ids.is_empty():
			continue
		_section(list, tr("STAGE_%s_NAME" % stage_id))
		for id in ids:
			_boss_row(list, id, "  ★ final" if id == final_id else "")
	var rest: Array[String] = []
	for id in DevPanel.boss_ids():
		if id not in seen:
			rest.append(id)
	if not rest.is_empty():
		_section(list, "Quests, events, secrets")
		for id in rest:
			_boss_row(list, id, "")


func _boss_row(list: VBoxContainer, id: String, note: String) -> void:
	_row(list, "BOSS:" + id, tr("ENEMY_%s_NAME" % id) + note, id, func() -> void: _act(func() -> void:
		_rush.clear()
		_rush_total = 0
		_fight(id)))


func _build_quests(list: VBoxContainer) -> void:
	var groups := {"cat_quests": "Cat quests", "side_quests": "Side quests", "story": "Story quests"}
	for group: String in groups:
		_section(list, groups[group])
		for id: String in GameData.quests[group]:
			var name := tr("CAT_%s_NAME" % id) if group == "cat_quests" else _quest_name(id)
			_quest_row(list, id, name, id)
	for chain_id: String in GameData.chains:
		var steps: Array = ChainStep.steps(chain_id)
		_section(list, "Story: " + tr("CHAIN_%s_NAME" % chain_id))
		for n in steps.size():
			if steps[n]["type"] == "final":
				continue
			_quest_row(list, "%s#%d" % [chain_id, n + 1], "%d. %s" % [n + 1, tr("CHAIN_%s_%d" % [chain_id, n + 1])], steps[n]["type"])


func _quest_row(list: VBoxContainer, id: String, text: String, tag: String) -> void:
	_row(list, "QUEST:" + id, text, tag, func() -> void: _act(func() -> void: _test_quest(id)))


func _quest_name(id: String) -> String:
	for key in ["QUEST_%s_TITLE" % id, "STORY_%s_NAME" % id, "QUEST_%s_NAME" % id]:
		if tr(key) != key:
			return tr(key)
	return id.capitalize()


func _column(parent: Node, width: float) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = width
	if width > 400.0:
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)
	return col


func _scroll(col: VBoxContainer) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	return list


func _list_head(col: VBoxContainer, button_text: String, action: Callable) -> Label:
	var head := HBoxContainer.new()
	col.add_child(head)
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", RED)
	head.add_child(label)
	if button_text != "":
		_button(head, button_text, func() -> void: _act(action))
	return label


func _section(list: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("f2c14e"))
	label.add_theme_font_size_override("font_size", 14)
	list.add_child(label)


## One boss or quest: a tick box (tried or not), its name to start the test,
## and its id in grey.
func _row(list: VBoxContainer, key: String, text: String, tag: String, action: Callable) -> void:
	var row := HBoxContainer.new()
	list.add_child(row)
	var box := CheckBox.new()
	box.focus_mode = Control.FOCUS_NONE
	box.button_pressed = _checks.has(key)
	box.toggled.connect(func(on: bool) -> void: _set_check(key, on))
	box.tooltip_text = "Tried"
	row.add_child(box)
	var b := _button(row, text, action)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.custom_minimum_size.x = 120
	b.tooltip_text = "%s\n%s" % [text, tag]
	var id_label := Label.new()
	id_label.text = tag
	id_label.add_theme_color_override("font_color", DIM)
	id_label.add_theme_font_size_override("font_size", 12)
	row.add_child(id_label)
	_rows.append({"key": key, "text": (text + " " + tag).to_lower(), "node": row, "box": box})


func _filter() -> void:
	var q := _search.text.strip_edges().to_lower()
	for r in _rows + _plain_rows:
		(r["node"] as Control).visible = q == "" or q in (r["text"] as String)


func _count() -> void:
	if _boss_head == null:
		return
	var counts := {"BOSS": [0, 0], "QUEST": [0, 0]}
	for r in _rows:
		var kind: String = (r["key"] as String).get_slice(":", 0)
		counts[kind][1] += 1
		if _checks.has(r["key"]):
			counts[kind][0] += 1
	_boss_head.text = "Bosses  %d/%d tried" % counts["BOSS"]
	_quest_head.text = "Quests  %d/%d tried" % counts["QUEST"]


func _set_check(key: String, on: bool) -> void:
	if on:
		_checks[key] = true
	else:
		_checks.erase(key)
	for r in _rows:
		if r["key"] == key:
			(r["box"] as CheckBox).set_pressed_no_signal(on)
	_count()
	# Test runs never touch the checklist.
	if "--bot" in GameData.args():
		return
	var file := FileAccess.open(CHECKLIST, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_checks.keys()))


func _load_checks() -> void:
	if not FileAccess.file_exists(CHECKLIST):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHECKLIST))
	if data is Array:
		for key: String in data:
			_checks[key] = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F1:
		if _panel.visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	# Esc closes the panel before the game sees it (it would open the pause
	# menu); F1 too, since the search box would swallow it.
	if _panel.visible and event is InputEventKey and event.pressed and event.physical_keycode in [KEY_ESCAPE, KEY_F1]:
		_close()
		get_viewport().set_input_as_handled()


func _open() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true
	_panel.visible = true
	_dps_label.visible = false
	_refresh_build()


func _close() -> void:
	if not _panel.visible:
		return
	_panel.visible = false
	_dps_label.visible = _dps_on
	_search.release_focus()
	get_tree().paused = _was_paused


## Closes the panel (so the game runs again), then does `action`.
func _act(action: Callable) -> void:
	_close()
	action.call()


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b


## Jumps forward in time and catches the cat up as if it had played those
## minutes: levels to the expected level, sensible upgrade picks, and one
## chest per boss that was skipped.
func _skip(seconds: float) -> void:
	var spawner: Spawner = main.spawner
	var from := spawner.elapsed
	var to := _skip_target(from + seconds)
	spawner.skip_to(to)
	var player: Player = main.player
	var target := DevPanel.expected_level(to / 60.0)
	while player.level < target:
		player.level += 1
		Upgrades.apply(player, DevPanel.smart_pick(player))
	for w: Dictionary in spawner.stage()["waves"]:
		var at := float(w["minute"]) * 60.0
		if at > from and at <= to and not (w.get("bosses", []) as Array).is_empty():
			Upgrades.open_chest(player, 3)
	player.xp = 0.0
	player.heal(player.max_hp)
	main.hud.update_xp(player)


## Rough level a decent player has at this minute (from test runs).
static func expected_level(minute: float) -> int:
	if minute <= 8.0:
		return 1 + roundi(minute * 3.4)
	return 28 + roundi((minute - 8.0) * 3.0)


## Picks like a sensible player: upgrade weapons you have, collect a few
## more weapons, then passives that unlock evolutions.
static func smart_pick(player: Player) -> Dictionary:
	var offers := Upgrades.roll(player, 4)
	var best: Dictionary = offers[0]
	var best_score := -1.0
	for o in offers:
		var score := 1.0
		if o["kind"] == "weapon":
			score = 3.0 if o["level"] > 1 else (2.5 if player.weapon_count() < 4 else 0.5)
		elif o["kind"] == "passive":
			for w: Weapon in player.weapons.get_children():
				if w.data.get("evolve", {}).get("with", "") == o["id"]:
					score = 2.8
		if score > best_score:
			best_score = score
			best = o
	return best


## Where a jump lands: just before the night's end (so it still ends
## normally), but once past the end (endless night, final boss) on from there.
func _skip_target(to: float) -> float:
	var spawner: Spawner = main.spawner
	var last := spawner.duration_minutes() * 60.0 - 5.0
	return to if spawner.elapsed >= last else minf(to, last)


## Only the clock moves on: enemies get as strong as at that minute, the cat stays.
func _skip_time(seconds: float) -> void:
	var spawner: Spawner = main.spawner
	spawner.skip_to(_skip_target(spawner.elapsed + seconds))


## Jumps to `minute` with the level, weapons and chests a player would have
## by then (an earlier minute stays where it is).
func _go_to_minute(minute: float) -> void:
	var left: float = minute * 60.0 - main.spawner.elapsed
	if left > 0.0:
		_skip(left)
		main.hud.update_inventory(main.player)


func _toggle_revive() -> void:
	main.dev_revive = not main.dev_revive
	_revive_button.text = "Revive on death: %s" % ("ON" if main.dev_revive else "OFF")


func _toggle_god() -> void:
	main.player.god = not main.player.god
	_god_button.text = "God mode: %s" % ("ON" if main.player.god else "OFF")


func _levels() -> void:
	for i in 5:
		main.player.level += 1
		Upgrades.apply(main.player, DevPanel.smart_pick(main.player))
	main.hud.update_xp(main.player)


## Skips the rest of the night (catching the cat up) and goes straight on
## into the endless night, as if the final boss had fallen.
func _endless_now() -> void:
	if main._endless:
		return
	_skip(main.spawner.duration_minutes() * 60.0)
	main.spawner.skip_to(main.spawner.duration_minutes() * 60.0)
	main.enemies.clear_all()
	main._start_endless()


func _final_boss() -> void:
	_skip(main.spawner.duration_minutes() * 60.0)
	main.spawner.skip_to(main.spawner.duration_minutes() * 60.0 - 1.0)


func _quest(kind: String) -> void:
	var director: QuestDirector = main.quests
	if director.active != null:
		director.active.fail()
	if kind == "cat":
		var id := director._pick_cat()
		if id != "":
			director.force(id)
	elif kind == "chain":
		# The next story step on this map (later-in-the-night steps wait).
		var id := director._pick_chain()
		if id != "":
			director.force(id)
	else:
		director.force((GameData.quests["side_quests"] as Dictionary).keys().pick_random())


## Every base weapon (as many as fit) and 40 sensible level-ups: enough to
## see a boss or a late quest without playing up to it.
func _strong_build() -> void:
	var player: Player = main.player
	for id: String in GameData.weapons:
		if player.weapon_count() >= player.max_weapons():
			break
		if not GameData.weapons[id].get("evolved", false) and not GameData.weapons[id].has("requires_stage") and player.get_weapon(id) == null:
			player.add_weapon(id)
	for i in 40:
		player.level += 1
		Upgrades.apply(player, DevPanel.smart_pick(player))
	player.xp = 0.0
	player.heal(player.max_hp)
	main.hud.update_xp(player)
	main.hud.update_inventory(player)


## The legendary of this map's final boss goes into the bag (it is kept
## like any found item: leave through the cat flap to see it at home).
func _find_legendary() -> void:
	var legend := Items.legendary_of(GameData.stages[main.spawner.stage_id].get("final_boss", ""))
	if legend != "":
		main._find_item(Items.legendary(legend))


## From the first test on, nothing is saved until the game restarts.
func _sandbox() -> void:
	GameData.dev_sandbox = true
	main.dev_test = true
	if _sandbox_label == null:
		_sandbox_label = Label.new()
		_sandbox_label.text = "DEV TEST: progress is not saved"
		_sandbox_label.position = Vector2(12, 646)
		_sandbox_label.add_theme_color_override("font_color", Color("e04646"))
		_sandbox_label.add_theme_font_size_override("font_size", 13)
		add_child(_sandbox_label)


## Bosses in the order you meet them: each map's wave bosses and its final
## boss, then the ones that turn up elsewhere (quests, events, the devil).
static func boss_ids() -> Array[String]:
	var ids: Array[String] = []
	for stage_id: String in GameData.stages:
		var stage: Dictionary = GameData.stages[stage_id]
		for w: Dictionary in stage["waves"]:
			for b: String in w.get("bosses", []):
				if b not in ids and GameData.enemies.has(b):
					ids.append(b)
		var final_id: String = stage.get("final_boss", "")
		if final_id != "" and final_id not in ids:
			ids.append(final_id)
	for id: String in GameData.enemies:
		if GameData.enemies[id].get("boss", false) and id not in ids:
			ids.append(id)
	return ids


## Every quest the director can start: cat quests, side quests, story quests
## and each step of every story chain ("CHAIN#step").
static func quest_ids() -> Array[String]:
	var ids: Array[String] = []
	for group in ["cat_quests", "side_quests", "story"]:
		for id: String in GameData.quests[group]:
			ids.append(id)
	for chain_id: String in GameData.chains:
		var steps: Array = ChainStep.steps(chain_id)
		for n in steps.size():
			if steps[n]["type"] != "final":
				ids.append("%s#%d" % [chain_id, n + 1])
	return ids


## Clears the field, stops the waves and puts the boss in front of the cat.
func fight(id: String) -> void:
	_fight(id)


func _fight(id: String) -> void:
	_sandbox()
	var spawner: Spawner = main.spawner
	spawner.paused = true
	main.enemies.clear_all()
	if main.quests.active != null:
		main.quests.active.fail()
	main.player.heal(9999.0)
	# As strong as where it comes in a run, whatever minute the test starts at.
	_test_boss = spawner.spawn_boss_as_in_run(id, main.player.position + Vector2(0, -230))
	_test_id = id
	if _test_boss == null:
		return
	spawner.start_arena(_test_boss)
	# Test runs can start the fight already part won (--boss-hp=0.4).
	_test_boss.hp = _test_boss.max_hp * float(main._arg("--boss-hp=", "1"))
	_testing = true
	main.final_boss = _test_boss
	var where := "%d/%d  " % [_rush_total - _rush.size(), _rush_total] if _rush_total > 0 else ""
	main.hud.show_banner("DEV: %s%s" % [where, tr("ENEMY_%s_NAME" % id)], 3.0)
	print("DEV: boss test %s hp=%.0f damage=%.1f speed=%.0f" % [id, _test_boss.max_hp, _test_boss.damage, _test_boss.speed])


## Every boss one after another; the next comes 2 s after one falls.
func start_boss_rush() -> void:
	_start_boss_rush()


func _start_boss_rush() -> void:
	_rush = DevPanel.boss_ids()
	_rush_total = _rush.size()
	_fight(_rush.pop_front())


func _test_quest(id: String) -> void:
	_sandbox()
	var director: QuestDirector = main.quests
	if director.active != null:
		director.active.fail()
	if "#" in id:
		var parts := id.split("#")
		director.force_step(parts[0], int(parts[1]))
	else:
		director.force(id)
	_test_quest_id = id
	if not director.finished_quest.is_connected(_on_quest_finished):
		director.finished_quest.connect(_on_quest_finished)


func _on_quest_finished(success: bool) -> void:
	if success and _test_quest_id != "":
		_set_check("QUEST:" + _test_quest_id, true)
	_test_quest_id = ""


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_tick_dps(delta)
	_tick_quest_cycle(delta)
	# (A freed boss compares equal to null, so a flag says a test is on.)
	if not _testing:
		return
	if is_instance_valid(_test_boss) and not _test_boss.dead:
		return
	# The boss under test fell: tick it off.
	_set_check("BOSS:" + _test_id, true)
	main.final_boss = null
	if _rush.is_empty():
		_testing = false
		_rush_total = 0
		main.spawner.paused = false
		main.hud.show_banner("DEV: boss down", 2.0)
		return
	_rush_wait += delta
	if _rush_wait < 2.0:
		return
	_rush_wait = 0.0
	main.player.heal(9999.0)
	_fight(_rush.pop_front())


## Starts every quest and story step in turn (a check that each one sets
## itself up wherever and whenever it is started).
func cycle_quests() -> void:
	_quest_cycle = DevPanel.quest_ids()
	_quest_cycle_t = 0.0


func _tick_quest_cycle(delta: float) -> void:
	if _quest_cycle.is_empty():
		return
	_quest_cycle_t -= delta
	if _quest_cycle_t > 0.0:
		return
	_quest_cycle_t = 5.0
	var id: String = _quest_cycle.pop_front()
	print("DEV: quest test %s (%d left)" % [id, _quest_cycle.size()])
	_test_quest(id)


## Tries the next kind of terrain on this map (none → trees → walls → ...).
func _next_terrain() -> void:
	var kinds := ["", "trees", "walls", "rooms", "aisles", "tide", "belts"]
	var now: String = Terrain.current.kind if Terrain.current != null else ""
	var next: String = kinds[(kinds.find(now) + 1) % kinds.size()]
	if Terrain.current != null:
		Terrain.current.queue_free()
		Terrain.current = null
	if next != "":
		var terrain := Terrain.new()
		terrain.setup(next, main)
		main.add_child(terrain)
		main.move_child(terrain, main.get_node("Floor").get_index() + 1)
	_terrain_button.text = "Terrain: %s" % (next if next != "" else "none")


func _tab(title: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.name = title
	col.add_theme_constant_override("separation", 6)
	_tabs.add_child(col)
	return col


## Opens the panel on a tab ("Build", "Enemies"...; the launcher's lab).
func show_tab(title: String) -> void:
	for i in _tabs.get_tab_count():
		if _tabs.get_tab_title(i).to_lower() == title.to_lower():
			_tabs.current_tab = i


# --- Build: every weapon, passive, evolution and branch at any level --------

func _build_build_tab(col: VBoxContainer) -> void:
	var top := HFlowContainer.new()
	col.add_child(top)
	_button(top, "Clear build", func() -> void: apply_build([]))
	_button(top, "Max everything", _max_all)
	_button(top, "Evolve all ready", _evolve_ready)
	_button(top, "Save as my build", _save_build)
	_button(top, "Load my build", func() -> void: apply_build(DevPanel.saved_build()))
	_button(top, "Cat's own weapon only", func() -> void: apply_build([{"kind": "weapon", "id": DevPanel.cat_weapon(main.player.cat_id), "level": 1}]))
	_build_info = Label.new()
	_build_info.add_theme_color_override("font_color", Color("9ae0ff"))
	col.add_child(_build_info)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(cols)
	var weapons := _scroll(_column(cols, 700))
	_section(weapons, "Weapons (+/- level, x remove, Evo = evolve now, branches at the right)")
	var base: Array[String] = []
	var evolved: Array[String] = []
	for id: String in GameData.weapons:
		if GameData.weapons[id].get("evolved", false):
			evolved.append(id)
		else:
			base.append(id)
	for id in base:
		_weapon_row(weapons, id)
	_section(weapons, "Evolved weapons")
	for id in evolved:
		_weapon_row(weapons, id)
	var passives := _scroll(_column(cols, 420))
	_section(passives, "Passives")
	for id: String in GameData.passives:
		_passive_row(passives, id)


static func cat_weapon(cat_id: String) -> String:
	return GameData.cats.get(cat_id, {}).get("weapon", "SCRATCH")


func _weapon_row(list: VBoxContainer, id: String) -> void:
	var data: Dictionary = GameData.weapons[id]
	var row := HBoxContainer.new()
	list.add_child(row)
	var name_label := Label.new()
	name_label.text = Upgrades.item_name("weapon", id)
	name_label.custom_minimum_size.x = 180
	name_label.clip_text = true
	row.add_child(name_label)
	var lv := Label.new()
	lv.custom_minimum_size.x = 64
	row.add_child(lv)
	_button(row, "-", func() -> void: _weapon_step(id, -1))
	_button(row, "+", func() -> void: _weapon_step(id, 1))
	_button(row, "Max", func() -> void: set_weapon_level(id, (data["levels"] as Array).size()))
	_button(row, "x", func() -> void: set_weapon_level(id, 0))
	var evolve: Dictionary = data.get("evolve", {})
	if not evolve.is_empty():
		var evo := _button(row, "Evo", func() -> void: _evolve(id))
		evo.tooltip_text = "%s + %s -> %s" % [Upgrades.item_name("weapon", id), Upgrades.item_name("passive", evolve["with"]), Upgrades.item_name("weapon", evolve["into"])]
	var branches := HBoxContainer.new()
	row.add_child(branches)
	for b: String in GameData.branches.get(Icons.base_weapon(id), {}):
		var bb := _button(branches, tr("BRANCH_%s_NAME" % b).left(10), func() -> void: _branch(id, b))
		bb.tooltip_text = "%s (click again: rank 2)" % tr("BRANCH_%s_NAME" % b)
		bb.add_theme_font_size_override("font_size", 12)
	var tag := Label.new()
	tag.text = id + ("  [%s]" % data["requires_stage"] if data.has("requires_stage") else "")
	tag.add_theme_color_override("font_color", DIM)
	tag.add_theme_font_size_override("font_size", 11)
	row.add_child(tag)
	_weapon_rows[id] = {"level": lv, "branches": branches, "name": name_label}
	_plain_rows.append({"text": (name_label.text + " " + id).to_lower(), "node": row})


func _passive_row(list: VBoxContainer, id: String) -> void:
	var row := HBoxContainer.new()
	list.add_child(row)
	var name_label := Label.new()
	name_label.text = Upgrades.item_name("passive", id)
	name_label.custom_minimum_size.x = 170
	name_label.clip_text = true
	row.add_child(name_label)
	var lv := Label.new()
	lv.custom_minimum_size.x = 48
	row.add_child(lv)
	_button(row, "-", func() -> void: set_passive_level(id, int(main.player.passives.get(id, 0)) - 1))
	_button(row, "+", func() -> void: set_passive_level(id, int(main.player.passives.get(id, 0)) + 1))
	_button(row, "Max", func() -> void: set_passive_level(id, DevPanel.passive_max(id)))
	var tag := Label.new()
	tag.text = id
	tag.add_theme_color_override("font_color", DIM)
	tag.add_theme_font_size_override("font_size", 11)
	row.add_child(tag)
	_passive_rows[id] = {"level": lv, "name": name_label}
	_plain_rows.append({"text": (name_label.text + " " + id).to_lower(), "node": row})


static func passive_max(id: String) -> int:
	return (GameData.passives[id]["levels"] as Array).size()


func _weapon_step(id: String, step: int) -> void:
	var w: Weapon = main.player.get_weapon(id)
	set_weapon_level(id, (w.level if w != null else 0) + step)


## Gives the cat weapon `id` at `level` (0 takes it away), keeping its branch.
## Slots don't count here: a test build may hold more weapons than a run.
func set_weapon_level(id: String, level: int) -> void:
	var player: Player = main.player
	level = clampi(level, 0, (GameData.weapons[id]["levels"] as Array).size())
	var w := player.get_weapon(id)
	var branch := ""
	var rank := 0
	var index := -1
	if w != null:
		if w.level == level:
			return
		branch = w.branch
		rank = w.branch_rank
		index = w.get_index()
		if level < w.level:
			player.weapons.remove_child(w)
			w.queue_free()
			w = null
	if level > 0:
		if w == null:
			w = player.add_weapon(id)
			w.branch = branch
			w.branch_rank = rank
			if index >= 0:
				player.weapons.move_child(w, index)
		while w.level < level:
			w.level_up()
	player.inventory_changed.emit()
	_build_changed()


func set_passive_level(id: String, level: int) -> void:
	var player: Player = main.player
	level = clampi(level, 0, DevPanel.passive_max(id))
	if level == 0:
		player.passives.erase(id)
	else:
		player.passives[id] = level
	player._recalc_stats()
	player.inventory_changed.emit()
	_build_changed()


## Evolves the weapon now, whatever its level or passives (owned or not).
func _evolve(id: String) -> void:
	var into: String = GameData.weapons[id]["evolve"]["into"]
	if main.player.get_weapon(into) != null:
		return
	if main.player.get_weapon(id) == null:
		set_weapon_level(id, 1)
	main.player.evolve_weapon(id, into)
	_build_changed()


func _branch(id: String, branch: String) -> void:
	if main.player.get_weapon(id) == null:
		set_weapon_level(id, 1)
	main.player.choose_branch(id, branch)
	_build_changed()


func _max_all() -> void:
	for w: Weapon in main.player.weapons.get_children():
		set_weapon_level(w.id, w.max_level())
	for id: String in main.player.passives.keys():
		set_passive_level(id, DevPanel.passive_max(id))


func _evolve_ready() -> void:
	var evo := Upgrades.find_evolution(main.player)
	while not evo.is_empty():
		main.player.evolve_weapon(evo["from"], evo["into"])
		evo = Upgrades.find_evolution(main.player)
	_build_changed()


## The cat's build as a list: weapons (level, branch, rank) and passives.
func current_build() -> Array:
	var build: Array = []
	for w: Weapon in main.player.weapons.get_children():
		if w.is_queued_for_deletion():
			continue
		build.append({"kind": "weapon", "id": w.id, "level": w.level, "branch": w.branch, "rank": w.branch_rank})
	for id: String in main.player.passives:
		build.append({"kind": "passive", "id": id, "level": main.player.passives[id]})
	return build


## Replaces the cat's weapons and passives with `build` (see current_build).
func apply_build(build: Array) -> void:
	var player: Player = main.player
	for w: Weapon in player.weapons.get_children():
		player.weapons.remove_child(w)
		w.queue_free()
	player.passives.clear()
	for item: Dictionary in build:
		var id: String = item.get("id", "")
		if item.get("kind", "") == "weapon" and GameData.weapons.has(id) and player.get_weapon(id) == null:
			var w := player.add_weapon(id)
			while w.level < int(item.get("level", 1)) and w.level < w.max_level():
				w.level_up()
			w.branch = item.get("branch", "")
			w.branch_rank = int(item.get("rank", 0))
		elif item.get("kind", "") == "passive" and GameData.passives.has(id):
			player.passives[id] = clampi(int(item.get("level", 1)), 1, DevPanel.passive_max(id))
	player._recalc_stats()
	player.inventory_changed.emit()
	_build_changed()


func _save_build() -> void:
	DevPanel.store_build(current_build())
	main.hud.show_banner("DEV: build saved (launcher: \"My build\")", 2.5)


static func store_build(build: Array) -> void:
	var file := FileAccess.open(BUILD_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(build))


static func saved_build() -> Array:
	if not FileAccess.file_exists(BUILD_FILE):
		return []
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(BUILD_FILE))
	return data if data is Array else []


func _build_changed() -> void:
	main.hud.update_inventory(main.player)
	main.hud.update_xp(main.player)
	_refresh_build()


func _refresh_build() -> void:
	if _build_info == null or main == null or main.player == null:
		return
	var player: Player = main.player
	var owned_w := 0
	for id: String in _weapon_rows:
		var r: Dictionary = _weapon_rows[id]
		var w := player.get_weapon(id)
		if w != null and w.is_queued_for_deletion():
			w = null
		var max_level := (GameData.weapons[id]["levels"] as Array).size()
		(r["level"] as Label).text = "%d/%d" % [w.level, max_level] if w != null else "-"
		(r["name"] as Label).add_theme_color_override("font_color", Color("8ee07a") if w != null else Color.WHITE)
		var row_branches: Array = (r["branches"] as HBoxContainer).get_children()
		for b: Button in row_branches:
			b.modulate = Color.WHITE
		if w != null:
			owned_w += 1
			if w.branch != "":
				var i := (GameData.branches.get(w.base_id(), {}) as Dictionary).keys().find(w.branch)
				if i >= 0 and i < row_branches.size():
					(row_branches[i] as Button).modulate = Color("8ee07a") if w.branch_rank >= 2 else Color("f2c14e")
	for id: String in _passive_rows:
		var r: Dictionary = _passive_rows[id]
		var n := int(player.passives.get(id, 0))
		(r["level"] as Label).text = "%d/%d" % [n, DevPanel.passive_max(id)] if n > 0 else "-"
		(r["name"] as Label).add_theme_color_override("font_color", Color("8ee07a") if n > 0 else Color.WHITE)
	_build_info.text = "Level %d  ·  weapons %d (slots %d)  ·  passives %d  ·  green = owned; branch: yellow rank 1, green rank 2" % [player.level, owned_w, player.max_weapons(), player.passives.size()]


# --- Enemies: spawn any of them, training dummies, DPS meter ----------------

func _build_enemies_tab(col: VBoxContainer) -> void:
	var top := HFlowContainer.new()
	col.add_child(top)
	_calm_button = _button(top, "Waves: ON", func() -> void: set_calm(not main.spawner.paused))
	_count_button = _button(top, "Spawn x1", _next_count)
	_dummy_button = _button(top, "Dummies: OFF", _toggle_dummies)
	_dummy_button.tooltip_text = "Spawned enemies stand still, never hit and have 30x health"
	_button(top, "Kill all enemies", func() -> void: main.enemies.clear_all())
	_button(top, "DPS meter on/off", _toggle_dps)
	_button(top, "Reset DPS", _reset_dps)
	var note := Label.new()
	note.text = "Click an enemy to spawn it around the cat. Bosses come as strong as in a run (the Bosses tab = full fight with arena)."
	note.add_theme_color_override("font_color", DIM)
	col.add_child(note)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(cols)
	var normal := _scroll(_column(cols, 560))
	var bosses := _scroll(_column(cols, 560))
	_section(normal, "Enemies")
	_section(bosses, "Bosses")
	var ids: Array = GameData.enemies.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return tr("ENEMY_%s_NAME" % a) < tr("ENEMY_%s_NAME" % b))
	for id: String in ids:
		var e: Dictionary = GameData.enemies[id]
		if e.get("prop", false):
			continue
		var list := bosses if e.get("boss", false) else normal
		var row := HBoxContainer.new()
		list.add_child(row)
		var b := _button(row, tr("ENEMY_%s_NAME" % id), func() -> void: _spawn_enemy(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.custom_minimum_size.x = 120
		var tag := Label.new()
		tag.text = "%s  hp %s  dmg %s  %s" % [id, str(e.get("hp", "?")), str(e.get("damage", "?")), e.get("behavior", "chase")]
		tag.add_theme_color_override("font_color", DIM)
		tag.add_theme_font_size_override("font_size", 11)
		row.add_child(tag)
		_plain_rows.append({"text": (b.text + " " + id).to_lower(), "node": row})


func _spawn_enemy(id: String) -> void:
	var player: Player = main.player
	for i in _spawn_count:
		var angle := TAU * float(i) / float(_spawn_count) + randf() * 0.3
		var pos: Vector2 = player.position + Vector2.from_angle(angle) * ((100.0 if _dummies else 150.0) + 20.0 * float(i % 4))
		var e: Enemy
		if GameData.enemies[id].get("boss", false):
			e = main.spawner.spawn_boss_as_in_run(id, pos)
		else:
			e = main.enemies.spawn(id, pos)
		if e != null and _dummies:
			e.max_hp *= 30.0
			e.hp = e.max_hp
			e.speed = 0.0
			e.damage = 0.0
	if main.hud != null:
		main.hud.show_banner("DEV: %d x %s" % [_spawn_count, tr("ENEMY_%s_NAME" % id)], 1.5)


func _next_count() -> void:
	var counts := [1, 5, 20, 100]
	_spawn_count = counts[(counts.find(_spawn_count) + 1) % counts.size()]
	_count_button.text = "Spawn x%d" % _spawn_count


func _toggle_dummies() -> void:
	_dummies = not _dummies
	_dummy_button.text = "Dummies: %s" % ("ON" if _dummies else "OFF")


## Waves off (true): only what the dev panel spawns comes.
func set_calm(on: bool) -> void:
	main.spawner.paused = on
	if _calm_button != null:
		_calm_button.text = "Waves: %s" % ("OFF" if on else "ON")


## The test lab: no waves, the cat can't die, a ring of dummies to hit and
## the DPS meter on; the panel opens on the Build tab.
func start_lab() -> void:
	_sandbox()
	set_calm(true)
	main.player.god = true
	if _god_button != null:
		_god_button.text = "God mode: ON"
	main.enemies.clear_all()
	var was := _dummies
	var count := _spawn_count
	_dummies = true
	_spawn_count = 8
	_spawn_enemy(DevPanel.dummy_enemy())
	_dummies = was
	_spawn_count = count
	if not _dps_on:
		_toggle_dps()
	show_tab("Build")


## A plain enemy for the dummies (the first one of the first map).
static func dummy_enemy() -> String:
	for w: Dictionary in GameData.stages[GameData.stages.keys()[0]]["waves"]:
		for id: String in w.get("enemies", []):
			if GameData.enemies.has(id):
				return id
	return GameData.enemies.keys()[0]


func _toggle_dps() -> void:
	_dps_on = not _dps_on
	_dps_label.visible = _dps_on and not _panel.visible
	_reset_dps()


func _reset_dps() -> void:
	_dps_last = Weapon.damage_log.duplicate()
	_dps_window.clear()
	_dps_label.text = "DPS: ..."


## Once a second: damage per weapon over the last 5 s.
func _tick_dps(delta: float) -> void:
	if not _dps_on:
		return
	_dps_t -= delta
	if _dps_t > 0.0:
		return
	_dps_t = 1.0
	var gain := {}
	for id: String in Weapon.damage_log:
		var d := float(Weapon.damage_log[id]) - float(_dps_last.get(id, 0.0))
		if d > 0.0:
			gain[id] = d
	_dps_last = Weapon.damage_log.duplicate()
	_dps_window.append(gain)
	if _dps_window.size() > 5:
		_dps_window.pop_front()
	var sums := {}
	for g: Dictionary in _dps_window:
		for id: String in g:
			sums[id] = float(sums.get(id, 0.0)) + float(g[id])
	var seconds := float(_dps_window.size())
	var ids: Array = sums.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return float(sums[a]) > float(sums[b]))
	var total := 0.0
	var lines: Array[String] = []
	for id: String in ids:
		total += float(sums[id])
		lines.append("%s  %.0f" % [Upgrades.item_name("weapon", id) if GameData.weapons.has(id) else id, float(sums[id]) / seconds])
	_dps_label.text = "DPS (5 s): %.0f\n%s" % [total / seconds, "\n".join(lines)]


# --- Run tab extras ---------------------------------------------------------

func _next_speed() -> void:
	var speeds := [1.0, 2.0, 4.0, 0.5, 0.25]
	var now := Engine.time_scale / maxf(main._base_time_scale, 0.01)
	var i := 0
	for n in speeds.size():
		if is_equal_approx(speeds[n], now):
			i = n
	var next: float = speeds[(i + 1) % speeds.size()]
	Engine.time_scale = main._base_time_scale * next
	_speed_button.text = "Game speed: %sx" % str(next)


## Swaps tonight's weather for `kind` (CLEAR: none).
func _set_weather(kind: String) -> void:
	for child in main.get_children():
		if child is Weather:
			child.queue_free()
	var player: Player = main.player
	for i in range(player.blessings.size() - 1, -1, -1):
		if String(player.blessings[i].get("label", "")).begins_with("WEATHER_"):
			player.blessings.remove_at(i)
	player._recalc_stats()
	if kind == "CLEAR":
		return
	var w := Weather.new()
	w.kind = kind
	w.player = player
	w.enemies = main.enemies
	main.add_child(w)


func _shrine(kind: String) -> void:
	if is_instance_valid(main.shrine):
		main.shrine.queue_free()
	var shrine := Shrine.new()
	shrine.main = main
	shrine.kind = kind
	shrine.position = Terrain.fix(main.player.position + Vector2(80, 0), 34.0)
	main.add_child(shrine)
	main.shrine = shrine


func _trap(id: String) -> void:
	var trap := Trap.new()
	trap.position = main.player.position + Vector2(0, 70)
	trap.setup(id, main)
	main.add_child(trap)
