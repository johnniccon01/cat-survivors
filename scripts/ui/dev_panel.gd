class_name DevPanel
extends CanvasLayer
## Development-only cheats (F1 to show/hide). Only created in debug builds,
## so exported release builds never contain it. Remove before release.

var main: Node

var _panel: PanelContainer
var _god_button: Button
## The list of bosses or quests to pick from (null when closed).
var _picker: PanelContainer
## The boss under test and, in a boss rush, the ones still to come.
var _test_boss: Enemy
var _testing := false
var _rush: Array[String] = []
var _rush_total := 0
var _rush_wait := 0.0
var _sandbox_label: Label
## --dev-quest-all: the quests still to start, one every few seconds.
var _quest_cycle: Array[String] = []
var _quest_cycle_t := 0.0


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.position = Vector2(12, 360)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.14, 0.85)
	sb.border_color = Color("e04646")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	_panel.visible = false
	var hint := Label.new()
	hint.text = "DEV: F1"
	hint.position = Vector2(12, 668)
	hint.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 0.6))
	hint.add_theme_font_size_override("font_size", 12)
	add_child(hint)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var title := Label.new()
	title.text = "DEV (F1)"
	title.add_theme_color_override("font_color", Color("e04646"))
	box.add_child(title)
	_button(box, "+1 min (+levels)", func() -> void: _skip(60.0))
	_button(box, "+5 min (+levels)", func() -> void: _skip(300.0))
	_god_button = _button(box, "God mode: OFF", _toggle_god)
	_button(box, "+5 levels", _levels)
	_button(box, "Heal", func() -> void: main.player.heal(9999.0))
	_button(box, "+1000 gold (saved)", func() -> void: Profile.add_gold(1000))
	_button(box, "Drop a charm", func() -> void: main._maybe_drop_charm(main.player.position + Vector2(30, 0), 1.0))
	_button(box, "Open cat flap", func() -> void: main._open_extraction(true))
	_button(box, "Kill all enemies", func() -> void: main.enemies.clear_all())
	_button(box, "Final boss now", _final_boss)
	_button(box, "Cat quest now", func() -> void: _quest("cat"))
	_button(box, "Side quest now", func() -> void: _quest("side"))
	_button(box, "Story step now", func() -> void: _quest("chain"))
	_button(box, "Angel cat now", func() -> void: main.summon_angel())
	_button(box, "Devil cat now", func() -> void: main.summon_devil())
	_button(box, "Strong build (test)", _strong_build)
	_button(box, "Boss test...", _open_boss_picker)
	_button(box, "Boss rush (all bosses)", _start_boss_rush)
	_button(box, "Quest test...", _open_quest_picker)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F1:
		_panel.visible = not _panel.visible
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE and _picker != null:
		_close_picker()
		get_viewport().set_input_as_handled()


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


func _open_boss_picker() -> void:
	var entries: Array = []
	for id in DevPanel.boss_ids():
		entries.append([id, "%s  (%s)" % [tr("ENEMY_%s_NAME" % id), id]])
	_open_picker("Boss test", entries, func(id: String) -> void:
		_rush.clear()
		_rush_total = 0
		_fight(id))


func _open_quest_picker() -> void:
	var entries: Array = []
	for id in DevPanel.quest_ids():
		var label := id
		if "#" in id:
			var parts := id.split("#")
			label = "%s  step %s: %s" % [parts[0], parts[1], ChainStep.steps(parts[0])[int(parts[1]) - 1]["type"]]
		entries.append([id, label])
	_open_picker("Quest test", entries, _test_quest)


func _open_picker(title_text: String, entries: Array, on_pick: Callable) -> void:
	_close_picker()
	get_tree().paused = true
	_picker = PanelContainer.new()
	_picker.position = Vector2(330, 40)
	_picker.custom_minimum_size = Vector2(620, 640)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.14, 0.95)
	sb.border_color = Color("e04646")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	_picker.add_theme_stylebox_override("panel", sb)
	add_child(_picker)
	var box := VBoxContainer.new()
	_picker.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := Label.new()
	title.text = "%s (%d)  ·  Esc closes" % [title_text, entries.size()]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color("e04646"))
	head.add_child(title)
	_button(head, "Close", _close_picker)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 590)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for e: Array in entries:
		var b := _button(list, e[1], func() -> void:
			_close_picker()
			on_pick.call(e[0]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _close_picker() -> void:
	if _picker == null:
		return
	_picker.queue_free()
	_picker = null
	get_tree().paused = false


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
	_test_boss = main.enemies.spawn(id, main.player.position + Vector2(0, -230), main.player.stat("curse") * spawner.hp_multiplier())
	if _test_boss == null:
		return
	_testing = true
	main.final_boss = _test_boss
	var where := "%d/%d  " % [_rush_total - _rush.size(), _rush_total] if _rush_total > 0 else ""
	main.hud.show_banner("DEV: %s%s" % [where, tr("ENEMY_%s_NAME" % id)], 3.0)
	print("DEV: boss test %s hp=%.0f" % [id, _test_boss.max_hp])


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


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_tick_quest_cycle(delta)
	# (A freed boss compares equal to null, so a flag says a test is on.)
	if not _testing:
		return
	if is_instance_valid(_test_boss) and not _test_boss.dead:
		return
	# The boss under test fell.
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
