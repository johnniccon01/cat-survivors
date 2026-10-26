extends SceneTree
## Screenshots of every menu screen and panel in every language, to look at
## the layout by eye (needs a window, not --headless):
##   godot --path . -s res://tools/menu_shots.gd -- --ui-test
##   (SHOTS_ONLY=ru,zh_CN in the environment: just those languages)
## Saves to user://menu_shots/<language>_<screen>.png. Everything is unlocked
## and some gear is owned (in memory only: --ui-test never saves).

const LOCALES := ["en", "sk", "cs", "es", "ru", "zh_CN"]

var _out := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_out = OS.get_user_data_dir().path_join("menu_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	_unlock()
	var only := LOCALES
	if OS.get_environment("SHOTS_ONLY") != "":
		# (Not a -- flag: any unknown flag makes the menus jump into a run.)
		only = Array(OS.get_environment("SHOTS_ONLY").split(","))
	for locale: String in only:
		TranslationServer.set_locale(locale)
		change_scene_to_file("res://scenes/main_menu.tscn")
		await _frames(12)
		await _shot(locale, "menu")
		for panel in ["_shop", "_charms", "_settings"]:
			await _panel(locale, "menu", panel)
		await _journal(locale, "menu")
		change_scene_to_file("res://scenes/character_select.tscn")
		await _frames(12)
		await _shot(locale, "select")
		for panel in ["_items", "_artifacts", "_challenges"]:
			await _panel(locale, "select", panel)
	print("SHOTS: saved to ", _out)
	quit()


func _unlock() -> void:
	var profile := root.get_node("Profile")
	var data := root.get_node("GameData")
	for id: String in data.stages:
		profile.cleared_stages.append(id)
	for id: String in data.cats:
		profile.unlocked.append(id)
	profile.gold = 12345
	var items_script: Script = load("res://scripts/progression/items.gd")
	var found: Array = []
	for id: String in data.items["legendaries"]:
		found.append(items_script.legendary(id))
	for i in 20:
		found.append(items_script.roll(1.0))
	profile.bank_items(found)
	for item: Dictionary in profile.items:
		if not profile.equipped_items.has(item["slot"]):
			profile.toggle_item(int(item["uid"]))


func _panel(locale: String, screen: String, name: String) -> void:
	var panel: Control = current_scene.get(name)
	if panel == null:
		return
	panel.call("open")
	await _frames(6)
	await _shot(locale, "%s%s" % [screen, name])
	panel.visible = false
	await _frames(2)


func _journal(locale: String, screen: String) -> void:
	var panel: Control = current_scene.get("_journal")
	if panel == null:
		return
	for tab: String in panel.get_script().get_script_constant_map()["TABS"]:
		panel.call("open", tab)
		await _frames(6)
		await _shot(locale, "%s_journal_%s" % [screen, tab])
	panel.visible = false
	await _frames(2)


func _shot(locale: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [locale, name]))


func _frames(n: int) -> void:
	for i in n:
		await process_frame
