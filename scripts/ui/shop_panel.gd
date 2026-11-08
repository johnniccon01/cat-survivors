class_name ShopPanel
extends ColorRect
## Permanent power-ups bought with gold between runs (like Vampire Survivors'
## PowerUps): a grid of cards with an icon, the ranks bought and the price,
## and the chosen one's description with Buy / Refund all / Back underneath.
## Arrows choose, Enter buys, Backspace refunds everything, U / Esc close.

signal closed

const COLUMNS := 4
## Power-ups that share an icon with a passive skill.
const PASSIVE_ICON := {"MIGHT": "MIGHT", "ARMOR": "ARMOR", "MAX_HEALTH": "MAXHP", "RECOVERY": "REGEN", "COOLDOWN": "COOLDOWN", "AREA": "AREA", "MOVE_SPEED": "SPEED", "MAGNET": "MAGNET", "GROWTH": "GROWTH", "GREED": "GREED", "LUCK": "LUCK"}

var _ids: Array[String] = []
var _index := 0
var _cards: Array[PanelContainer] = []
var _names: Array[Label] = []
var _bars: Array[SegmentBar] = []
var _prices: Array[Label] = []
var _gold: Label
var _detail_icon: ShopIcon
var _detail_name: Label
var _desc: Label
var _buy: Button


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	for id: String in GameData.powerups:
		_ids.append(id)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size.x = 920
	UiStyle.board(self, box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UiStyle.label("SHOP_TITLE", 34, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var gold_row := HBoxContainer.new()
	gold_row.add_theme_constant_override("separation", 8)
	head.add_child(gold_row)
	_gold = UiStyle.plain("", 22, UiStyle.GOLD)
	_gold.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gold_row.add_child(_gold)
	gold_row.add_child(PixelGlyph.rect("coin", 3))

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for i in _ids.size():
		var id := _ids[i]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(221, 82)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(i))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(row)
		var icon := ShopIcon.new(id, 46.0)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)
		var name_label := UiStyle.plain(tr("POWERUP_%s_NAME" % id), 17)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.custom_minimum_size.x = 140
		col.add_child(name_label)
		var bar := UiStyle.segments(int(GameData.powerups[id]["max_rank"]), 0, 18, 6)
		col.add_child(bar)
		var price_row := HBoxContainer.new()
		price_row.add_theme_constant_override("separation", 5)
		col.add_child(price_row)
		var price := UiStyle.plain("", 14, UiStyle.GOLD)
		price_row.add_child(price)
		price_row.add_child(PixelGlyph.rect("coin", 2))
		grid.add_child(card)
		_cards.append(card)
		_names.append(name_label)
		_bars.append(bar)
		_prices.append(price)

	# The chosen power-up: what it does and the buttons.
	var line := ColorRect.new()
	line.color = UiStyle.CARD_BORDER
	line.custom_minimum_size.y = 1
	box.add_child(line)
	var detail := HBoxContainer.new()
	detail.add_theme_constant_override("separation", 14)
	box.add_child(detail)
	_detail_icon = ShopIcon.new(_ids[0], 44.0)
	_detail_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	detail.add_child(_detail_icon)
	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 1)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.alignment = BoxContainer.ALIGNMENT_CENTER
	detail.add_child(text_col)
	_detail_name = UiStyle.plain("", 17)
	text_col.add_child(_detail_name)
	_desc = UiStyle.plain("", 14, Color("cfc3dd"), true)
	_desc.custom_minimum_size.x = 380
	text_col.add_child(_desc)
	_buy = UiStyle.click_button("", 0, 16)
	_buy.custom_minimum_size = Vector2(170, 42)
	_buy.add_theme_color_override("font_color", UiStyle.GOLD)
	UiStyle.add_key(_buy, "Enter", 11)
	_buy.pressed.connect(func() -> void:
		_activate()
		_refresh())
	detail.add_child(_buy)
	var refund := UiStyle.click_button("SHOP_REFUND", 0, 15)
	refund.custom_minimum_size.y = 42
	UiStyle.add_key(refund, "⌫", 11)
	refund.pressed.connect(func() -> void:
		Profile.refund_powerups()
		Audio.play("magnet", -8.0, 0.0)
		_refresh())
	detail.add_child(refund)
	var back := UiStyle.click_button("SET_BACK", 0, 15)
	back.custom_minimum_size.y = 42
	UiStyle.add_key(back, "Esc", 11)
	back.pressed.connect(_close)
	detail.add_child(back)
	for b: Button in [_buy, refund, back]:
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func open() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	_gold.text = Hud.thousands(Profile.gold)
	for i in _ids.size():
		var id := _ids[i]
		var data: Dictionary = GameData.powerups[id]
		var rank := Profile.powerup_rank(id)
		var max_rank := int(data["max_rank"])
		var maxed := rank >= max_rank
		var affordable := not maxed and Profile.gold >= Profile.powerup_cost(id)
		_bars[i].filled = rank
		_prices[i].text = tr("SHOP_MAX") if maxed else Hud.thousands(Profile.powerup_cost(id))
		_prices[i].get_parent().get_child(1).visible = not maxed
		_prices[i].add_theme_color_override("font_color", UiStyle.GREEN if maxed else (UiStyle.GOLD if affordable else UiStyle.MUTED))
		_names[i].add_theme_color_override("font_color", UiStyle.GOLD if i == _index else UiStyle.TEXT)
		_cards[i].add_theme_stylebox_override("panel", UiStyle.card(i == _index))
	var id := _ids[_index]
	var rank := Profile.powerup_rank(id)
	var max_rank := int(GameData.powerups[id]["max_rank"])
	_detail_icon.id = id
	_detail_icon.queue_redraw()
	_detail_name.text = "%s  ·  %s" % [tr("POWERUP_%s_NAME" % id), tr("SHOP_RANK") % [rank, max_rank]]
	_desc.text = tr("POWERUP_%s_DESC" % id)
	_buy.text = tr("SHOP_MAX") if rank >= max_rank else tr("SHOP_BUY") % Profile.powerup_cost(id)
	_buy.disabled = rank >= max_rank or Profile.gold < Profile.powerup_cost(id)


## _input, not _unhandled_input: the panel must see keys before the GUI
## focus of the screen behind it does.
func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	# Swallow every key while open (releases too), so the menu behind can't
	# react to it.
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_index = (_index - COLUMNS + _ids.size()) % _ids.size()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_index = (_index + COLUMNS) % _ids.size()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_index = (_index - 1 + _ids.size()) % _ids.size()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_index = (_index + 1) % _ids.size()
	elif event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		_activate()
	elif event is InputEventKey and event.physical_keycode == KEY_BACKSPACE:
		Profile.refund_powerups()
		Audio.play("magnet", -8.0, 0.0)
	elif event.is_action_pressed("shop") or event.is_action_pressed("pause"):
		visible = false
		closed.emit()
		return
	else:
		return
	Audio.play("click", -10.0, 0.0)
	_refresh()


## What Enter (or a click) does on the selected card.
func _activate() -> void:
	if Profile.buy_powerup(_ids[_index]):
		Audio.play("chest", -6.0, 0.0)
	else:
		Audio.play("hurt", -10.0, 0.0)


## Mouse: hovering a card selects it, clicking it does what Enter does.
func _on_card_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_index = i
		_activate()
		_refresh()
	elif event is InputEventMouseMotion and _index != i:
		_index = i
		_refresh()


func _close() -> void:
	visible = false
	closed.emit()
