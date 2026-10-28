class_name DevPanel
extends CanvasLayer
## Development-only cheats (F1 to show/hide; the game pauses while it is
## open). Only created in debug builds, so exported release builds never
## contain it. Remove before release.
## Three columns: cheats for the run, every boss and every quest to test.
## The tick boxes are a checklist of what has been tried (saved apart from
## the profile in CHECKLIST); a boss beaten or a quest finished in a test
## ticks itself.

const CHECKLIST := "user://dev_checklist.json"
const RED := Color("e04646")
const DIM := Color(0.62, 0.56, 0.7)

var main: Node

var _panel: PanelContainer
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
	_search.placeholder_text = "Search bosses and quests..."
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.clear_button_enabled = true
	_search.text_changed.connect(func(_t: String) -> void: _filter())
	head.add_child(_search)
	_button(head, "Close", _close)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	_build_actions(_column(cols, 300))
	var bosses := _column(cols, 450)
	_boss_head = _list_head(bosses, "Boss rush (all)", _start_boss_rush)
	_build_bosses(_scroll(bosses))
	var quests := _column(cols, 450)
	_quest_head = _list_head(quests, "", Callable())
	_build_quests(_scroll(quests))
	_count()


func _build_actions(col: VBoxContainer) -> void:
	var list := _scroll(col)
	_section(list, "Time")
	_button(list, "+1 min (+levels)", func() -> void: _skip(60.0))
	_button(list, "+5 min (+levels)", func() -> void: _skip(300.0))
	_button(list, "Final boss now", func() -> void: _act(_final_boss))
	_button(list, "Endless night now", func() -> void: _act(_endless_now))
	_section(list, "Cat")
	_god_button = _button(list, "God mode: OFF", _toggle_god)
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
	_section(list, "World")
	_button(list, "Kill all enemies", func() -> void: main.enemies.clear_all())
	_button(list, "Open cat flap", func() -> void: _act(func() -> void: main._open_extraction(true)))
	_terrain_button = _button(list, "Terrain: %s" % (Terrain.current.kind if Terrain.current != null else "none"), _next_terrain)
	_button(list, "Angel cat now", func() -> void: _act(main.summon_angel))
	_button(list, "Death (devil cat) now", func() -> void: _act(main.summon_devil))
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
	for r in _rows:
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


func _close() -> void:
	if not _panel.visible:
		return
	_panel.visible = false
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
	var to := minf(from + seconds, spawner.duration_minutes() * 60.0 - 5.0)
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
	var kinds := ["", "trees", "walls", "aisles", "tide", "belts"]
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
