extends SceneTree
## Opens every menu screen and panel in every language and reports text that
## doesn't fit: cut off in a clipped label or button, sticking out of its
## panel, or off the screen. Never saves the profile or settings.
##   godot --headless --path . -s res://tools/text_fit_test.gd -- --ui-test
## Prints "TEXT: FAIL ..." for each problem and "TEXT: done, N failures".

const LOCALES := ["en", "sk", "cs", "es", "ru", "zh_CN"]
## Symbols the game's font lacks but the system font draws.
const SYMBOLS := "←→↑↓★☆◆◇●○✓×•…■□"

var _failures := 0
var _seen := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# First a fresh profile, then one with every map and cat open (the
	# profile is never saved in --ui-test).
	for opened in [false, true]:
		if opened:
			var profile := root.get_node("Profile")
			var data := root.get_node("GameData")
			for id: String in data.stages:
				profile.cleared_stages.append(id)
			# Gear with the longest names in every slot, worn and in the bag.
			var items_script: Script = load("res://scripts/progression/items.gd")
			var found: Array = []
			for id: String in data.items["legendaries"]:
				found.append(items_script.legendary(id))
			for i in 30:
				found.append(items_script.roll(1.0, "rare"))
			profile.bank_items(found)
			for item: Dictionary in profile.items:
				if not profile.equipped_items.has(item["slot"]):
					profile.toggle_item(int(item["uid"]))
			for id: String in data.cats:
				profile.unlocked.append(id)
		for locale: String in LOCALES:
			var tag := locale + (" open" if opened else "")
			TranslationServer.set_locale(locale)
			change_scene_to_file("res://scenes/main_menu.tscn")
			await _frames(8)
			await _screen(tag, "menu", ["_shop", "_charms", "_journal", "_settings"])
			# "What's new" (shown once after an update).
			var news: Control = load("res://scripts/ui/news_panel.gd").new()
			current_scene.add_child(news)
			news.call("open")
			await _frames(3)
			_check(news, tag + " news")
			news.queue_free()
			change_scene_to_file("res://scenes/character_select.tscn")
			await _frames(8)
			await _screen(tag, "select", ["_shop", "_charms", "_items", "_artifacts", "_challenges", "_journal"])
			_map_cards(tag)
			if opened:
				await _in_game(tag)
	print("TEXT: done, %d failures" % _failures)
	quit(1 if _failures > 0 else 0)


## A run: the HUD, the pause menu, level-up cards, a shrine's choices (the
## longest texts) and the end-of-night summary.
func _in_game(tag: String) -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await _frames(20)
	var main := current_scene
	var hud: Node = main.get("hud")
	main.get("player").set("god", true)
	_check(hud, tag + " hud")
	paused = true
	hud.call("show_pause", true)
	await _frames(3)
	_check(hud, tag + " pause")
	hud.call("show_pause", false)
	var offers: Array[Dictionary] = load("res://scripts/progression/upgrades.gd").roll(main.get("player"), 4)
	var level_up: Control = hud.get("level_up")
	level_up.call("open", 12, offers, 2, "", 3)
	await _frames(3)
	_check(level_up, tag + " level-up")
	level_up.visible = false
	var choice: Control = hud.get("choice")
	var options: Array = []
	for key in ["SHRINE_HASTE_OPT0", "SHRINE_HASTE_OPT1", "SHRINE_HASTE_OPT2", "SHRINE_REFUSE"]:
		options.append(TranslationServer.translate(key))
	choice.call("open", TranslationServer.translate("SHRINE_HASTE_NAME"), TranslationServer.translate("SHRINE_PROMPT"), options)
	await _frames(3)
	_check(choice, tag + " shrine choice")
	choice.visible = false
	var lines: Array[String] = []
	for key in ["SUMMARY_GOLD_DEATH", "SUMMARY_STREAK", "SUMMARY_ITEMS_KEPT", "SUMMARY_ITEM_WELL", "SUMMARY_CHARMS_LOST", "SUMMARY_DARKNESS_OPEN"]:
		lines.append(_filled(TranslationServer.translate(key)))
	hud.call("show_game_over", 754.0, 1234, TranslationServer.translate("GAME_OVER_TITLE") % TranslationServer.translate("CAT_KAPITAN_NAME"))
	hud.call("show_summary", lines)
	await _frames(3)
	_check(hud, tag + " summary")
	paused = false


## Checks the screen, then each of its panels open on top of it.
func _screen(locale: String, screen: String, panels: Array) -> void:
	var root := current_scene
	_check(root, "%s %s" % [locale, screen])
	for name: String in panels:
		var panel: Control = root.get(name)
		if panel == null:
			continue
		if panel.has_method("show_tab"):
			for tab: String in panel.get_script().get_script_constant_map()["TABS"]:
				panel.call("open", tab)
				await _frames(3)
				_check(panel, "%s %s %s:%s" % [locale, screen, name, tab])
		else:
			panel.call("open")
			await _frames(3)
			_check(panel, "%s %s %s" % [locale, screen, name])
		panel.visible = false
		await _frames(1)


## A text with its placeholders filled: numbers, and the longest item name
## for every %s (the worst case for the width).
func _filled(text: String) -> String:
	var fill: Array = []
	for m in RegEx.create_from_string("%(\\.\\d+)?[sdf]").search_all(text):
		fill.append(TranslationServer.translate("ITEM_NUTSHELL_HELMET_NAME") if m.get_string().ends_with("s") else 1234)
	return text % fill if not fill.is_empty() else text


## The map cards draw their own text, shrinking it to fit; every map's name
## must still be readable at the smallest size.
func _map_cards(locale: String) -> void:
	var font := ThemeDB.fallback_font
	for id: String in root.get_node("GameData").stages:
		var name := TranslationServer.translate("STAGE_%s_NAME" % id)
		var width := 196.0 - 16.0
		var fitted: int = load("res://scripts/ui/ui_style.gd").fit_size(font, name, width, 18)
		if font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > width or fitted < 12:
			_fail("%s map card %s: \"%s\" too long (size %d)" % [locale, id, name, fitted])


func _check(node: Node, where: String) -> void:
	var view := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	for c in _controls(node):
		if not c.is_visible_in_tree():
			continue
		var text := ""
		var clipped := false
		var font: Font
		var size := 16
		if c is Label:
			var l := c as Label
			text = l.atr(l.text)
			clipped = l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
			if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
				clipped = false
			font = l.get_theme_font("font")
			size = l.get_theme_font_size("font_size")
			if l.label_settings != null:
				size = l.label_settings.font_size
				if l.label_settings.font != null:
					font = l.label_settings.font
		elif c is Button:
			var b := c as Button
			text = b.atr(b.text)
			clipped = b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
			font = b.get_theme_font("font")
			size = b.get_theme_font_size("font_size")
		else:
			continue
		if text.strip_edges() == "":
			continue
		# Every character must be drawable: by the game's font, or by the
		# system font for Chinese and the few symbols it lacks.
		for ch in text:
			var code := ch.unicode_at(0)
			if code > 32 and code != 0xA0 and code < 0x2E80 and ch not in SYMBOLS and not ThemeDB.fallback_font.has_char(code):
				_fail("%s: \"%s\" has '%s' (U+%04X) the font can't draw" % [where, text.left(40), ch, code])
				break
		var rect := c.get_global_rect()
		if clipped:
			# Only the longest line counts for multi-line text.
			var widest := 0.0
			for line in text.split("\n"):
				widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
			if widest > rect.size.x + 1.0:
				_fail("%s: \"%s\" cut off (%d > %d px) at %s" % [where, text.left(40), widest, rect.size.x, c.get_path()])
				continue
		if _scrolled(c):
			# Lists scroll up and down, never sideways.
			if rect.position.x < -1.0 or rect.end.x > view.end.x + 1.0:
				_fail("%s: \"%s\" too wide for the screen (%d px) at %s" % [where, text.left(40), rect.size.x, c.get_path()])
			continue
		# (A few pixels over the edge is padding, not text.)
		if not view.grow(6.0).encloses(rect):
			_fail("%s: \"%s\" off the screen %s at %s" % [where, text.left(40), rect, c.get_path()])
			continue
		var box := _panel_of(c)
		if box != null and not box.get_global_rect().grow(1.0).encloses(rect):
			_fail("%s: \"%s\" sticks out of its panel at %s" % [where, text.left(40), c.get_path()])


func _controls(node: Node) -> Array[Control]:
	var out: Array[Control] = []
	for child in node.get_children():
		if child is Control:
			out.append(child)
		out.append_array(_controls(child))
	return out


## Inside a scroll container text may run past the visible part.
func _scrolled(c: Control) -> bool:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _panel_of(c: Control) -> PanelContainer:
	var p := c.get_parent()
	while p != null:
		if p is PanelContainer:
			return p
		p = p.get_parent()
	return null


func _fail(msg: String) -> void:
	# The same label on the same screen once is enough.
	if _seen.has(msg):
		return
	_seen[msg] = true
	_failures += 1
	print("TEXT: FAIL ", msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame
