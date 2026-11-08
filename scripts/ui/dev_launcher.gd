class_name DevLauncher
extends Control
## Development only (debug builds: the editor and the launchers; the main
## menu's DEV button, or `-- --dev-launcher`). Starts any test straight away:
## a quest on the map it belongs to, at the minute it opens, with a build;
## any map at any minute; any boss; the test lab (no waves, dummies, every
## weapon / passive / evolution / branch in the F1 panel's Build tab); and
## special events. Nothing is saved until the game restarts (dev sandbox),
## and the run comes back here when it ends.

const SCENE := "res://scenes/dev_launcher.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"
const RED := Color("e04646")
const GOLD := Color("f2c14e")
const DIM := Color(0.62, 0.56, 0.7)
const BUILDS := ["As played by then", "Strong (all weapons, 40 levels)", "My build (F1 > Build > Save)", "Cat's weapon only"]
const BUILD_FLAGS := ["played", "strong", "mine", "none"]
const SETTINGS := "user://dev_launcher.cfg"

## Set once the launcher has been shown, so `--dev-launcher` on the command
## line only skips the menu the first time (Back then leads to the menu).
static var opened_once := false

var _cat: OptionButton
var _build: OptionButton
var _minute: SpinBox
var _auto_minute: CheckBox
var _god: CheckBox
var _calm: CheckBox
var _any_map: OptionButton
var _lab_map: OptionButton
var _search: LineEdit
var _tabs: TabContainer
var _cat_ids: Array[String] = []
var _stage_ids: Array[String] = []
## {"text", "node"} for the search box.
var _rows: Array[Dictionary] = []


func _ready() -> void:
	opened_once = true
	GameData.dev_sandbox = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	_stage_ids.assign(GameData.stages.keys())
	for id: String in GameData.cats:
		if not GameData.cats[id].get("npc", false):
			_cat_ids.append(id)
	_build_head(root)
	_build_options(root)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_tabs)
	_build_quests(_tab("Quests"))
	_build_maps(_tab("Maps & bosses"))
	_build_lab(_tab("Lab (weapons, passives, evolutions)"))
	_build_special(_tab("Special"))
	_load_settings()


func _build_head(root: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	var title := Label.new()
	title.text = "DEV LAUNCHER  ·  nothing is saved until you restart the game"
	title.add_theme_color_override("font_color", RED)
	title.add_theme_font_size_override("font_size", 18)
	head.add_child(title)
	_search = LineEdit.new()
	_search.placeholder_text = "Search quests, maps, bosses..."
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.clear_button_enabled = true
	_search.text_changed.connect(func(_t: String) -> void: _filter())
	head.add_child(_search)
	_button(head, "Back to menu", func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))


## What every start uses: cat, build, minute, god mode, waves.
func _build_options(root: VBoxContainer) -> void:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 10)
	root.add_child(row)
	row.add_child(_label("Cat:", GOLD))
	_cat = OptionButton.new()
	for id in _cat_ids:
		_cat.add_item("%s (%s)" % [tr("CAT_%s_NAME" % id), id])
	_cat.item_selected.connect(func(_i: int) -> void: _save_settings())
	row.add_child(_cat)
	row.add_child(_label("Build:", GOLD))
	_build = OptionButton.new()
	for b: String in BUILDS:
		_build.add_item(b)
	_build.item_selected.connect(func(_i: int) -> void: _save_settings())
	row.add_child(_build)
	row.add_child(_label("Minute:", GOLD))
	_auto_minute = CheckBox.new()
	_auto_minute.text = "auto (when it opens)"
	_auto_minute.button_pressed = true
	_auto_minute.toggled.connect(func(on: bool) -> void:
		_minute.editable = not on
		_save_settings())
	row.add_child(_auto_minute)
	_minute = SpinBox.new()
	_minute.min_value = 0
	_minute.max_value = 60
	_minute.step = 0.5
	_minute.editable = false
	_minute.value_changed.connect(func(_v: float) -> void: _save_settings())
	row.add_child(_minute)
	_god = CheckBox.new()
	_god.text = "God mode"
	_god.toggled.connect(func(_on: bool) -> void: _save_settings())
	row.add_child(_god)
	_calm = CheckBox.new()
	_calm.text = "No waves"
	_calm.toggled.connect(func(_on: bool) -> void: _save_settings())
	row.add_child(_calm)
	var hint := _label("In the run: F1 = dev panel (build, enemies, time, quests); a death asks to revive.", DIM)
	hint.add_theme_font_size_override("font_size", 12)
	row.add_child(hint)


# --- Quests -----------------------------------------------------------------

## Every quest under the map it belongs to (districts in order), then the
## ones that can happen on any map.
func _build_quests(col: VBoxContainer) -> void:
	var top := HBoxContainer.new()
	col.add_child(top)
	top.add_child(_label("Quests that can happen anywhere start on:", GOLD))
	_any_map = _map_picker()
	top.add_child(_any_map)
	var list := _scroll(col)
	var anywhere: Array[Dictionary] = []
	var by_stage := {}
	for chain_id: String in GameData.chains:
		var steps: Array = ChainStep.steps(chain_id)
		for n in steps.size():
			var step: Dictionary = steps[n]
			var entry := {"kind": "chain", "chain": chain_id, "step": n + 1, "type": step["type"],
				"minute": -1.0 if step["type"] == "final" else float(step.get("after_minute", 0.0)),
				"text": "%s  %d/%d. %s" % [tr("CHAIN_%s_NAME" % chain_id), n + 1, steps.size(), tr("CHAIN_%s_%d" % [chain_id, n + 1])],
				"tag": "%s#%d %s%s" % [chain_id, n + 1, step["type"], "  secret" if GameData.chains[chain_id].has("secret") else ""]}
			var stage := ChainStep.stage_of(chain_id, n + 1)
			if stage == "any" or not GameData.stages.has(stage):
				anywhere.append(entry)
			else:
				if not by_stage.has(stage):
					by_stage[stage] = []
				by_stage[stage].append(entry)
	var district := ""
	for stage_id in _stage_ids:
		var stage: Dictionary = GameData.stages[stage_id]
		var d := DistrictMap.stage_district(stage_id)
		if d != district:
			district = d
			_head(list, "District: %s" % tr("DISTRICT_NAME_" + d.to_upper()))
		var section := HBoxContainer.new()
		list.add_child(section)
		var name := _label("  %s" % tr("STAGE_%s_NAME" % stage_id), GOLD)
		name.add_theme_font_size_override("font_size", 15)
		section.add_child(name)
		var tag := _label(stage_id, DIM)
		tag.add_theme_font_size_override("font_size", 11)
		section.add_child(tag)
		for cat_id: String in stage.get("cat_quests", []):
			_quest_row(list, stage_id, {"kind": "quest", "id": cat_id, "minute": QuestDirector.CAT_QUEST_FROM / 60.0,
				"text": "Cat quest: %s" % tr("CAT_%s_NAME" % cat_id), "tag": cat_id})
		var story: String = stage.get("story", "")
		if story != "":
			_quest_row(list, stage_id, {"kind": "quest", "id": story, "minute": 1.0, "text": "Story quest: %s" % DevLauncher.quest_name(story), "tag": story})
		for entry: Dictionary in by_stage.get(stage_id, []):
			_quest_row(list, stage_id, entry)
		_quest_row(list, stage_id, {"kind": "final", "minute": -1.0, "text": "Final boss: %s" % tr("ENEMY_%s_NAME" % stage.get("final_boss", "")), "tag": stage.get("final_boss", "")})
	_head(list, "Anywhere (starts on the map chosen above)")
	for id: String in GameData.quests["side_quests"]:
		_quest_row(list, "", {"kind": "quest", "id": id, "minute": 1.0, "text": "Side quest: %s" % DevLauncher.quest_name(id), "tag": id})
	for entry in anywhere:
		_quest_row(list, "", entry)


func _quest_row(list: VBoxContainer, stage_id: String, entry: Dictionary) -> void:
	var row := HBoxContainer.new()
	list.add_child(row)
	var minute: float = entry["minute"]
	var b := _button(row, "    " + String(entry["text"]), func() -> void: _start_quest(stage_id, entry))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var when := _label("final" if minute < 0.0 else "min %s" % str(minute), Color("9ae0ff") if minute > 0.0 else DIM)
	when.custom_minimum_size.x = 60
	row.add_child(when)
	var tag := _label(entry["tag"], DIM)
	tag.add_theme_font_size_override("font_size", 11)
	tag.custom_minimum_size.x = 260
	row.add_child(tag)
	_rows.append({"text": ("%s %s %s" % [entry["text"], entry["tag"], tr("STAGE_%s_NAME" % stage_id) if stage_id != "" else ""]).to_lower(), "node": row})


func _start_quest(stage_id: String, entry: Dictionary) -> void:
	if stage_id == "":
		stage_id = _stage_ids[_any_map.selected]
	var args: Array[String] = []
	match entry["kind"]:
		"quest":
			args.append("--dev-quest=" + String(entry["id"]))
		"chain":
			# The save as if the story had got this far (in memory only).
			Profile.chains[entry["chain"]] = int(entry["step"]) - 1
			if entry["type"] == "final":
				args.append("--dev-final")
			else:
				args.append("--dev-quest=%s#%d" % [entry["chain"], entry["step"]])
		"final":
			args.append("--dev-final")
	_launch(stage_id, args, maxf(float(entry["minute"]), 0.0))


# --- Maps and bosses --------------------------------------------------------

func _build_maps(col: VBoxContainer) -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(cols)
	var maps := _scroll(_column(cols))
	var bosses := _scroll(_column(cols))
	_head(maps, "Maps (minute from the box above; auto = start)")
	for stage_id in _stage_ids:
		var row := HBoxContainer.new()
		maps.add_child(row)
		var b := _button(row, "%s" % tr("STAGE_%s_NAME" % stage_id), func() -> void: _launch(stage_id, [], 0.0))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for m in [5, 10, 15]:
			_button(row, "%d'" % m, func() -> void: _launch(stage_id, [], float(m), true))
		_button(row, "Final", func() -> void: _launch(stage_id, ["--dev-final"], 0.0))
		_button(row, "Endless", func() -> void: _launch(stage_id, ["--dev-endless"], 0.0))
		var tag := _label("%s  %s  %d min" % [stage_id, DistrictMap.stage_district(stage_id), int(GameData.stages[stage_id].get("duration_minutes", 0))], DIM)
		tag.add_theme_font_size_override("font_size", 11)
		row.add_child(tag)
		_rows.append({"text": (b.text + " " + stage_id).to_lower(), "node": row})
	_head(bosses, "Bosses (on their map, at the minute they come)")
	var seen: Array[String] = []
	for stage_id in _stage_ids:
		var stage: Dictionary = GameData.stages[stage_id]
		for w: Dictionary in stage["waves"]:
			for id: String in w.get("bosses", []):
				if id not in seen and GameData.enemies.has(id):
					seen.append(id)
					_boss_row(bosses, id, stage_id, float(w["minute"]), "")
		var final_id: String = stage.get("final_boss", "")
		if final_id != "" and final_id not in seen:
			seen.append(final_id)
			_boss_row(bosses, final_id, stage_id, float(stage.get("duration_minutes", 20)), "  ★ final")
	for id in DevPanel.boss_ids():
		if id not in seen:
			_boss_row(bosses, id, _stage_ids[0], 10.0, "  (quest / event)")


func _boss_row(list: VBoxContainer, id: String, stage_id: String, minute: float, note: String) -> void:
	var row := HBoxContainer.new()
	list.add_child(row)
	var b := _button(row, tr("ENEMY_%s_NAME" % id) + note, func() -> void: _launch(stage_id, ["--dev-boss=" + id], minute))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tag := _label("%s  %s  min %s" % [id, stage_id, str(minute)], DIM)
	tag.add_theme_font_size_override("font_size", 11)
	row.add_child(tag)
	_rows.append({"text": (b.text + " " + id + " " + stage_id).to_lower(), "node": row})


# --- Lab --------------------------------------------------------------------

func _build_lab(col: VBoxContainer) -> void:
	var text := _label("The test lab: no waves, the cat can't die, a ring of training dummies (30x health, they never move\nor hit) and the DPS meter per weapon. F1 > Build: add any weapon, passive, evolution or branch,\nlevel it up or down, evolve it at once, save the build (\"My build\" in the Build box above).\nF1 > Enemies: spawn any enemy or boss (x1 / x5 / x20 / x100), as dummies or for real; waves on/off.", Color.WHITE)
	col.add_child(text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	row.add_child(_label("Map:", GOLD))
	_lab_map = _map_picker()
	row.add_child(_lab_map)
	var start := _button(row, "Start the lab", func() -> void: _launch(_stage_ids[_lab_map.selected], ["--dev-lab"], 0.0, false, true))
	start.custom_minimum_size = Vector2(220, 44)
	_button(row, "Lab with every base weapon at max", func() -> void:
		var build: Array = []
		for id: String in GameData.weapons:
			if not GameData.weapons[id].get("evolved", false):
				build.append({"kind": "weapon", "id": id, "level": (GameData.weapons[id]["levels"] as Array).size()})
		DevPanel.store_build(build)
		_build.select(BUILD_FLAGS.find("mine"))
		_launch(_stage_ids[_lab_map.selected], ["--dev-lab"], 0.0, false, true))
	_button(row, "Lab with every evolution", func() -> void:
		var build: Array = []
		for id: String in GameData.weapons:
			if GameData.weapons[id].get("evolved", false):
				build.append({"kind": "weapon", "id": id, "level": 1})
		DevPanel.store_build(build)
		_build.select(BUILD_FLAGS.find("mine"))
		_launch(_stage_ids[_lab_map.selected], ["--dev-lab"], 0.0, false, true))
	var saved := DevPanel.saved_build()
	var names: Array[String] = []
	for item: Dictionary in saved:
		names.append("%s %d" % [item.get("id", "?"), int(item.get("level", 1))])
	var mine := _label("My build: %s" % (", ".join(names) if not names.is_empty() else "(none saved yet: F1 > Build > Save as my build)"), DIM)
	mine.autowrap_mode = TextServer.AUTOWRAP_WORD
	col.add_child(mine)


# --- Special events ---------------------------------------------------------

func _build_special(col: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	col.add_child(row)
	row.add_child(_label("Map:", GOLD))
	var map := _map_picker()
	row.add_child(map)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	col.add_child(flow)
	var events := [
		["Every quest in turn (5 s each)", ["--dev-quest-all", "--god"]],
		["Boss rush (every boss)", ["--boss-rush", "--god"]],
		["Every trap next to the cat", ["--traps"]],
		["Golden mouse", ["--golden"]],
		["Diary page (after 5 s)", ["--page"]],
		["Champions (half the enemies)", ["--champions"]],
		["Cat flap right away", ["--extract"]],
		["Charm next to the cat", ["--drop-charm"]],
		["Rare item in the bag", ["--drop-item=rare"]],
		["Legendary item in the bag", ["--drop-item=legendary"]],
		["Death (devil cat)", ["--devil"]],
		["Every shrine: F1 > Run", ["--dev-tab=Run", "--dev-panel"]],
		["Weather: rain", ["--weather=RAIN"]],
		["Weather: storm", ["--weather=STORM"]],
		["Weather: fog", ["--weather=FOG"]],
		["Weather: frost", ["--weather=FROST"]],
		["Weather: wind", ["--weather=WIND"]],
		["Endless night now", ["--dev-endless"]],
	]
	for e: Array in events:
		var b := _button(flow, e[0], func() -> void: _launch(_stage_ids[map.selected], e[1], 0.0, true))
		b.custom_minimum_size = Vector2(260, 40)
		_rows.append({"text": String(e[0]).to_lower(), "node": b})


# --- Starting a run ---------------------------------------------------------

## Starts `stage_id` with the chosen cat and build at `minute` (the box
## overrides it unless "auto"; `fixed`: the button's own minute wins).
func _launch(stage_id: String, extra: Array, minute: float, fixed: bool = false, lab: bool = false) -> void:
	if not _auto_minute.button_pressed and not fixed:
		minute = _minute.value
	Profile.selected_stage = stage_id
	Profile.selected_cat = _cat_ids[_cat.selected]
	var args := PackedStringArray(["--no-save"])
	var build: String = BUILD_FLAGS[_build.selected]
	if lab and build == "played":
		build = "none"
	match build:
		"played":
			if minute > 0.0:
				args.append("--dev-go-minute=%s" % str(minute))
		"strong":
			args.append("--strong")
		"mine":
			args.append("--dev-build=mine")
	if build != "played" and minute > 0.0:
		args.append("--start-minute=%s" % str(minute))
	if _god.button_pressed:
		args.append("--god")
	if _calm.button_pressed:
		args.append("--dev-calm")
	for a: String in extra:
		args.append(a)
	print("DEV LAUNCHER: %s %s as %s: %s" % [stage_id, str(minute), Profile.selected_cat, " ".join(args)])
	_save_settings()
	GameData.dev_sandbox = true
	GameData.dev_args = args
	get_tree().change_scene_to_file(MAIN_SCENE)


# --- Helpers ----------------------------------------------------------------

static func quest_name(id: String) -> String:
	for key in ["QUEST_%s_TITLE" % id, "STORY_%s_NAME" % id, "QUEST_%s_NAME" % id]:
		if TranslationServer.translate(key) != key:
			return TranslationServer.translate(key)
	return id.capitalize()


func _map_picker() -> OptionButton:
	var o := OptionButton.new()
	for id in _stage_ids:
		o.add_item("%s (%s)" % [tr("STAGE_%s_NAME" % id), id])
	return o


func _tab(title: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.name = title
	col.add_theme_constant_override("separation", 6)
	_tabs.add_child(col)
	return col


func _column(parent: Node) -> VBoxContainer:
	var col := VBoxContainer.new()
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


func _head(list: VBoxContainer, text: String) -> void:
	var label := _label(text, RED)
	label.add_theme_font_size_override("font_size", 17)
	list.add_child(label)


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	return label


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _filter() -> void:
	var q := _search.text.strip_edges().to_lower()
	for r in _rows:
		(r["node"] as Control).visible = q == "" or q in (r["text"] as String)


## The launcher's choices are kept between starts (apart from the profile).
func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("dev", "cat", _cat.selected)
	cfg.set_value("dev", "build", _build.selected)
	cfg.set_value("dev", "auto", _auto_minute.button_pressed)
	cfg.set_value("dev", "minute", _minute.value)
	cfg.set_value("dev", "god", _god.button_pressed)
	cfg.set_value("dev", "calm", _calm.button_pressed)
	cfg.set_value("dev", "any_map", _any_map.selected)
	cfg.set_value("dev", "lab_map", _lab_map.selected)
	cfg.set_value("dev", "tab", _tabs.current_tab)
	cfg.save(SETTINGS)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) != OK:
		return
	_cat.select(clampi(int(cfg.get_value("dev", "cat", 0)), 0, _cat.item_count - 1))
	_build.select(clampi(int(cfg.get_value("dev", "build", 0)), 0, _build.item_count - 1))
	_auto_minute.button_pressed = bool(cfg.get_value("dev", "auto", true))
	_minute.value = float(cfg.get_value("dev", "minute", 0.0))
	_minute.editable = not _auto_minute.button_pressed
	_god.button_pressed = bool(cfg.get_value("dev", "god", false))
	_calm.button_pressed = bool(cfg.get_value("dev", "calm", false))
	_any_map.select(clampi(int(cfg.get_value("dev", "any_map", 0)), 0, _any_map.item_count - 1))
	_lab_map.select(clampi(int(cfg.get_value("dev", "lab_map", 0)), 0, _lab_map.item_count - 1))
	_tabs.current_tab = clampi(int(cfg.get_value("dev", "tab", 0)), 0, _tabs.get_tab_count() - 1)
