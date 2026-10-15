class_name DevPanel
extends CanvasLayer
## Development-only cheats (F1 to show/hide). Only created in debug builds,
## so exported release builds never contain it. Remove before release.

var main: Node

var _panel: PanelContainer
var _god_button: Button


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
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var title := Label.new()
	title.text = "DEV (F1)"
	title.add_theme_color_override("font_color", Color("e04646"))
	box.add_child(title)
	_button(box, "+1 min", func() -> void: _skip(60.0))
	_button(box, "+5 min", func() -> void: _skip(300.0))
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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F1:
		_panel.visible = not _panel.visible


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _skip(seconds: float) -> void:
	var limit: float = main.spawner.duration_minutes() * 60.0 - 5.0
	main.spawner.elapsed = minf(main.spawner.elapsed + seconds, limit)


func _toggle_god() -> void:
	main.player.god = not main.player.god
	_god_button.text = "God mode: %s" % ("ON" if main.player.god else "OFF")


func _levels() -> void:
	for i in 5:
		main.player.level += 1
		Upgrades.apply(main.player, Upgrades.roll(main.player)[0])
	main.hud.update_xp(main.player)


func _final_boss() -> void:
	main.spawner.elapsed = main.spawner.duration_minutes() * 60.0 - 1.0


func _quest(kind: String) -> void:
	var director: QuestDirector = main.quests
	if director.active != null:
		director.active.fail()
	if kind == "cat":
		var id := director._pick_cat()
		if id != "":
			director.force(id)
	else:
		director.force((GameData.quests["side_quests"] as Dictionary).keys().pick_random())
