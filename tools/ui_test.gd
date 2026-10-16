extends SceneTree
## Keyboard walk through every menu, checking that the arrows and Enter only
## ever drive the screen in front (never a hidden one behind it) and that
## nothing closes the game. Never saves the profile or settings.
##   godot --headless --path . -s res://tools/ui_test.gd -- --ui-test
## Prints "UI: FAIL ..." for each problem and "UI: done, N failures" at the end.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file("res://scenes/main_menu.tscn")
	await _frames(10)
	await _main_menu()
	await _character_select()
	await _in_game()
	print("UI: done, %d failures" % _failures)
	quit(1 if _failures > 0 else 0)


# --- main menu ------------------------------------------------------------------

func _main_menu() -> void:
	_expect(_focus_text() == "MENU_PLAY", "menu starts on Play, got %s" % _focus_text())
	# Each panel: walk down to its button, open it, mash keys, close it.
	for entry: Array in [[1, "_shop"], [2, "_charms"], [3, "_journal"]]:
		for i in entry[0]:
			await _press(KEY_DOWN)
		var panel: Control = current_scene.get(entry[1])
		await _press(KEY_ENTER)
		_expect(panel.visible, "%s opens" % entry[1])
		for key: Key in [KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_RIGHT, KEY_UP, KEY_LEFT, KEY_ENTER, KEY_ENTER]:
			await _press(key)
			_expect(current_scene.name == "MainMenu" and panel.visible, "%s stays open after %s" % [entry[1], OS.get_keycode_string(key)])
			_expect(_focus_text() == "-", "%s: menu behind has no focus after %s (got %s)" % [entry[1], OS.get_keycode_string(key), _focus_text()])
		await _press(KEY_ESCAPE)
		_expect(not panel.visible, "%s closes on Esc" % entry[1])
		_expect(_focus_text() == "MENU_PLAY", "%s: focus back on Play (got %s)" % [entry[1], _focus_text()])

	# Journal: left/right switch tabs (wrapping), up/down scroll.
	for i in 3:
		await _press(KEY_DOWN)
	var journal: Control = current_scene.get("_journal")
	await _press(KEY_ENTER)
	_expect(journal.visible and journal.get("tab") == "quests", "journal opens on quests")
	for step: Array in [[KEY_RIGHT, "goals"], [KEY_RIGHT, "bestiary"], [KEY_RIGHT, "quests"], [KEY_LEFT, "bestiary"], [KEY_D, "quests"], [KEY_A, "bestiary"]]:
		await _press(step[0])
		_expect(journal.get("tab") == step[1], "journal %s -> %s (got %s)" % [OS.get_keycode_string(step[0]), step[1], journal.get("tab")])
	var scroll: ScrollContainer = journal.get("_scroll")
	for i in 6:
		await _press(KEY_DOWN)
	_expect(scroll.scroll_vertical > 0, "journal scrolls down")
	for i in 10:
		await _press(KEY_UP)
	_expect(scroll.scroll_vertical == 0, "journal scrolls back up")
	await _press(KEY_ESCAPE)
	_expect(not journal.visible and _focus_text() == "MENU_PLAY", "journal closes on Esc")

	# Settings: focus has to stay inside the panel whichever way you go.
	for i in 4:
		await _press(KEY_DOWN)
	var settings: Control = current_scene.get("_settings")
	await _press(KEY_ENTER)
	_expect(settings.visible, "settings open")
	await _check_trapped(settings, "menu settings")
	await _press(KEY_ESCAPE)
	_expect(not settings.visible, "settings close on Esc")
	_expect(_focus_text() == "MENU_PLAY", "after settings focus back on Play (got %s)" % _focus_text())

	# Left / right do nothing on the menu; then Play.
	await _press(KEY_LEFT)
	await _press(KEY_RIGHT)
	_expect(current_scene.name == "MainMenu", "still on the menu")
	await _press(KEY_ENTER)
	await _frames(5)
	_expect(current_scene.name == "CharacterSelect", "Play opens character select (got %s)" % current_scene.name)


# --- character select -------------------------------------------------------------

func _character_select() -> void:
	var sel := current_scene
	var count: int = (sel.get("_ids") as Array).size()
	var start: int = sel.get("_index")
	await _press(KEY_RIGHT)
	_expect(sel.get("_index") == (start + 1) % count, "Right moves one cat")
	await _press(KEY_RIGHT)
	await _press(KEY_LEFT)
	await _press(KEY_LEFT)
	_expect(sel.get("_index") == start, "Left moves back one cat each")
	var stage: int = sel.get("_stage_index")
	await _press(KEY_DOWN)
	await _press(KEY_UP)
	_expect(sel.get("_stage_index") == stage, "Down/Up move the stage and back")
	# Panels opened from here: keys go to the panel, Esc closes only the panel.
	for entry: Array in [[KEY_C, "_charms"], [KEY_U, "_shop"], [KEY_G, "_journal"], [KEY_Q, "_journal"], [KEY_J, "_journal"]]:
		var panel: Control = sel.get(entry[1])
		await _press(entry[0])
		_expect(panel.visible, "select: %s opens" % entry[1])
		var before: int = sel.get("_index")
		for key: Key in [KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_UP]:
			await _press(key)
		_expect(sel.get("_index") == before, "select: %s doesn't move the cat behind it" % entry[1])
		await _press(KEY_ESCAPE)
		_expect(not panel.visible, "select: %s closes on Esc" % entry[1])
		_expect(current_scene == sel, "select: Esc in %s stays on character select" % entry[1])
	# Make sure an unlocked cat on an open stage is picked, then start.
	var profile := root.get_node("Profile")
	var ids: Array = sel.get("_ids")
	while not profile.is_unlocked(ids[sel.get("_index")]):
		await _press(KEY_RIGHT)
	sel.set("_stage_index", 0)
	await _press(KEY_ENTER)
	await _frames(10)
	_expect(current_scene.name == "Main", "Enter starts the run (got %s)" % current_scene.name)


# --- in game -------------------------------------------------------------------------

func _in_game() -> void:
	var main := current_scene
	var hud: Node = main.get("hud")
	var cat: Node2D = main.get("player")
	cat.set("god", true)
	await _frames(30)
	# Movement: WASD and arrows, diagonals not faster, nothing while paused.
	var single := 0.0
	for entry: Array in [[[KEY_D], Vector2.RIGHT], [[KEY_A], Vector2.LEFT], [[KEY_W], Vector2.UP], [[KEY_S], Vector2.DOWN],
			[[KEY_RIGHT], Vector2.RIGHT], [[KEY_LEFT], Vector2.LEFT], [[KEY_UP], Vector2.UP], [[KEY_DOWN], Vector2.DOWN],
			[[KEY_W, KEY_D], Vector2(1, -1).normalized()]]:
		var from := cat.position
		await _hold(entry[0], 30)
		var moved := cat.position - from
		var names := ", ".join((entry[0] as Array).map(func(k: Key) -> String: return OS.get_keycode_string(k)))
		_expect(moved.length() > 20.0 and moved.normalized().dot(entry[1]) > 0.9, "%s moves the cat %s (moved %s)" % [names, entry[1], moved])
		if (entry[0] as Array).size() == 1 and single == 0.0:
			single = moved.length()
		elif (entry[0] as Array).size() == 2:
			_expect(moved.length() < single * 1.2, "diagonal is not faster (%.0f vs %.0f)" % [moved.length(), single])
	await _press(KEY_ESCAPE)
	var still := cat.position
	await _hold([KEY_D], 30)
	_expect(cat.position.distance_to(still) < 1.0, "no movement while paused")
	await _press(KEY_ESCAPE)
	_expect(not paused, "Esc resumes after the movement check")
	# M mutes and unmutes.
	var settings_node := root.get_node("Settings")
	var was_muted: bool = settings_node.get("muted")
	await _press(KEY_M)
	await _press(KEY_ESCAPE)
	await _press(KEY_M)
	_expect(settings_node.get("muted") != was_muted, "M toggles sound in the pause menu")
	await _press(KEY_M)
	await _press(KEY_ESCAPE)
	# Pause menu and its settings.
	await _press(KEY_ESCAPE)
	_expect(paused, "Esc pauses")
	_expect(_focus_text() == "PAUSE_RESUME", "pause starts on Resume (got %s)" % _focus_text())
	await _press(KEY_DOWN)
	_expect(_focus_text() == "MENU_SETTINGS", "Down goes to Settings (got %s)" % _focus_text())
	await _press(KEY_ENTER)
	var settings: Control = hud.get("settings")
	_expect(settings.visible, "pause settings open")
	await _check_trapped(settings, "pause settings")
	await _press(KEY_ESCAPE)
	_expect(not settings.visible, "pause settings close on Esc")
	_expect(paused, "still paused after closing settings")
	_expect(_focus_text() == "PAUSE_RESUME", "pause menu back with focus (got %s)" % _focus_text())
	for i in 6:
		await _press(KEY_DOWN)
		_expect(_focus_text() in ["PAUSE_RESUME", "MENU_SETTINGS", "PAUSE_GIVE_UP"], "pause focus stays on its buttons (got %s)" % _focus_text())
	await _press(KEY_ESCAPE)
	_expect(not paused, "Esc resumes")

	# Level-up: focus moves between cards only; Enter picks.
	var level_up: Control = hud.get("level_up")
	main.call("_queue_modal", "level")
	await _frames(70)
	_expect(level_up.visible and paused, "level-up opens and pauses")
	for key: Key in [KEY_RIGHT, KEY_RIGHT, KEY_RIGHT, KEY_RIGHT, KEY_LEFT, KEY_DOWN, KEY_UP]:
		await _press(key)
		var focus := root.gui_get_focus_owner()
		_expect(focus != null and level_up.is_ancestor_of(focus), "level-up focus stays on cards after %s" % OS.get_keycode_string(key))
	await _press(KEY_ENTER)
	await _frames(5)
	_expect(not level_up.visible and not paused, "Enter picks a card and the game goes on")

	# Level-up with number keys, and the reroll key.
	main.call("_queue_modal", "level")
	await _frames(70)
	await _press(KEY_2)
	await _frames(5)
	_expect(not level_up.visible and not paused, "number key 2 picks the second card")
	cat.set("rerolls_left", 1)
	main.call("_queue_modal", "level")
	await _frames(70)
	await _press(KEY_R)
	await _frames(70)
	_expect(level_up.visible and int(cat.get("rerolls_left")) == 0, "R rerolls the cards once")
	await _press(KEY_1)
	await _frames(5)
	_expect(not level_up.visible, "after a reroll a card can still be picked")

	# Chest: any key closes it once everything is shown.
	var treasure: Control = hud.get("treasure")
	main.call("_queue_modal", "chest")
	await _frames(240)
	_expect(treasure.visible, "chest opens")
	await _press(KEY_ENTER)
	await _frames(5)
	_expect(not treasure.visible and not paused, "Enter closes the chest")

	# Give up from the pause menu, then back to character select.
	await _press(KEY_ESCAPE)
	await _press(KEY_DOWN)
	await _press(KEY_DOWN)
	_expect(_focus_text() == "PAUSE_GIVE_UP", "Down twice reaches Give up (got %s)" % _focus_text())
	await _press(KEY_ENTER)
	_expect(main.get("_run_over"), "Give up ends the run")
	await _press(KEY_ESCAPE)
	await _frames(10)
	_expect(current_scene.name == "CharacterSelect", "Esc after the run goes to character select (got %s)" % current_scene.name)
	await _press(KEY_ESCAPE)
	await _frames(10)
	_expect(current_scene.name == "MainMenu", "Esc on character select goes to the menu (got %s)" % current_scene.name)


# --- helpers ---------------------------------------------------------------------------

## Arrow keys all around a panel with GUI focus; focus must never leave it.
func _check_trapped(panel: Control, what: String) -> void:
	await _frames(3)
	for key: Key in [KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN,
			KEY_UP, KEY_UP, KEY_UP, KEY_UP, KEY_UP, KEY_UP, KEY_UP, KEY_UP, KEY_UP, KEY_UP, KEY_UP, KEY_UP, KEY_UP,
			KEY_LEFT, KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		await _press(key)
		var focus := root.gui_get_focus_owner()
		_expect(focus != null and panel.is_ancestor_of(focus), "%s: focus stays inside after %s (got %s)" % [what, OS.get_keycode_string(key), focus.get_path() if focus else "none"])


## Holds `keys` down together for `frames` physics frames, then lets go.
func _hold(keys: Array, frames: int) -> void:
	for pressed in [true, false]:
		for key: Key in keys:
			var e := InputEventKey.new()
			e.keycode = key
			e.physical_keycode = key
			e.pressed = pressed
			Input.parse_input_event(e)
		# Physics frames: the same game time whatever the screen's frame rate.
		for i in (frames if pressed else 3):
			await physics_frame


func _press(key: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = key
		e.physical_keycode = key
		e.pressed = pressed
		Input.parse_input_event(e)
		await _frames(2)
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _focus_text() -> String:
	var focus := root.gui_get_focus_owner()
	if focus is Button:
		return (focus as Button).text
	return "-" if focus == null else String(focus.name)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		print("UI: FAIL ", what)
