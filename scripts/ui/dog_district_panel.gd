class_name DogDistrictPanel
extends ColorRect
## The second district, the Dog District, as it will be: a picture of the
## dogs' town with its sixteen places (all locked for now), and beside it the
## chosen place, its dog boss and the friend who joins you there. Opened by
## the "Train east" button on the town map once the story "A Ticket East" is
## done (flag "train_east"). The full plan is in PSIE_STVRTE.md. Esc closes.

signal closed

const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")
## The picture, in its own pixels, and how big it is drawn.
const TW := 340
const TH := 200
const SCALE := 2.0
## The places in the order the nights will open, and where they sit.
const PLACES := [
	["FREIGHT_YARD", Vector2(36, 166)], ["DOG_SHELTER", Vector2(86, 128)], ["DOG_PARK", Vector2(150, 150)],
	["JUNKYARD", Vector2(44, 76)], ["GROOMING_SALON", Vector2(118, 82)], ["BONE_BAKERY", Vector2(178, 104)],
	["RACETRACK", Vector2(234, 164)], ["FIRE_STATION", Vector2(200, 50)], ["POLICE_K9", Vector2(258, 96)],
	["VET_CLINIC", Vector2(296, 52)], ["RIVER_DAM", Vector2(60, 22)], ["SNOW_HILL", Vector2(140, 20)],
	["TRAINING_GROUND", Vector2(300, 140)], ["DOG_SHOW", Vector2(178, 186)], ["BARRACKS", Vector2(316, 184)],
	["GENERAL_KENNEL", Vector2(250, 22)],
]

static var _town: Image

var _selected := 0
var _pins: Array[Button] = []
var _name: Label
var _boss: Label
var _friend: Label
var _desc: Label
var _ring: Control


func _ready() -> void:
	color = Color(0.06, 0.05, 0.09, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	UiStyle.board(self, box)
	var title := _label(32, GOLD)
	title.text = "DOGS_TITLE"
	box.add_child(title)
	var intro := _label(15, Color("d9d4e6"))
	intro.text = "DOGS_INTRO"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(1080, 0)
	box.add_child(intro)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	# The town picture with a numbered pin on every place.
	var map := TextureRect.new()
	map.texture = ImageTexture.create_from_image(town())
	map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map.custom_minimum_size = Vector2(TW, TH) * SCALE
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row.add_child(map)
	_ring = Control.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ring.draw.connect(_draw_ring)
	map.add_child(_ring)
	for i in PLACES.size():
		var pin := Button.new()
		pin.text = str(i + 1)
		pin.focus_mode = Control.FOCUS_NONE
		pin.custom_minimum_size = Vector2(26, 22)
		pin.add_theme_font_size_override("font_size", 13)
		pin.add_theme_color_override("font_color", Color("f4ecd4"))
		pin.add_theme_stylebox_override("normal", UiStyle.box(Color(0.12, 0.1, 0.16, 0.9), Color("8a7aa8")))
		pin.add_theme_stylebox_override("hover", UiStyle.box(Color(0.2, 0.16, 0.26, 0.95), GOLD))
		pin.add_theme_stylebox_override("pressed", UiStyle.box(Color(0.2, 0.16, 0.26, 0.95), GOLD))
		pin.position = (PLACES[i][1] as Vector2) * SCALE - Vector2(13, 11)
		pin.tooltip_text = tr("DOGS_%s_NAME" % PLACES[i][0])
		pin.pressed.connect(_select.bind(i))
		map.add_child(pin)
		_pins.append(pin)
	# The chosen place.
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(380, 0)
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)
	var hint := _label(14, Color("9a92ac"))
	hint.text = "DOGS_PICK"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(380, 0)
	info.add_child(hint)
	_name = _label(24, GOLD)
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.custom_minimum_size = Vector2(380, 0)
	info.add_child(_name)
	var locked := _label(14, Color("e8907a"))
	locked.text = "DOGS_LOCKED"
	info.add_child(locked)
	_boss = _label(17, Color("f4ecd4"))
	_boss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss.custom_minimum_size = Vector2(380, 0)
	info.add_child(_boss)
	_friend = _label(17, Color("9ae08a"))
	_friend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_friend.custom_minimum_size = Vector2(380, 0)
	info.add_child(_friend)
	_desc = _label(15, Color("d9d4e6"))
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(380, 0)
	info.add_child(_desc)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 20)
	box.add_child(bottom)
	var coming := _label(15, Color("c8b8e8"))
	coming.text = "DOGS_COMING"
	bottom.add_child(coming)
	var back := UiStyle.click_button("SET_BACK", 200)
	back.pressed.connect(_close)
	bottom.add_child(back)


func open() -> void:
	visible = true
	_select(_selected)


func _select(i: int) -> void:
	_selected = i
	var id: String = PLACES[i][0]
	_name.text = "%d · %s" % [i + 1, tr("DOGS_%s_NAME" % id)]
	_boss.text = tr("DOGS_BOSS") % tr("DOGS_%s_BOSS" % id)
	var friend := "DOGS_%s_FRIEND" % id
	_friend.visible = tr(friend) != friend
	_friend.text = tr("DOGS_FRIEND") % tr(friend)
	_desc.text = tr("DOGS_%s_DESC" % id)
	_ring.queue_redraw()


func _draw_ring() -> void:
	var at: Vector2 = PLACES[_selected][1] * SCALE
	_ring.draw_arc(at, 20.0, 0.0, TAU, 32, OUTLINE, 5.0)
	_ring.draw_arc(at, 20.0, 0.0, TAU, 32, GOLD, 3.0)


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if event.is_pressed() and not event.is_echo() and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_close()


func _close() -> void:
	visible = false
	closed.emit()


func _label(size: int, font_color: Color) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = font_color
	settings.outline_size = 4
	settings.outline_color = OUTLINE
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


# --- the picture of the dogs' town ---------------------------------------------

static var _img: Image
static var _rng := RandomNumberGenerator.new()


## The dogs' town at night, drawn once: a river and its dam in the north,
## the railway coming in from the west to the freight yard, and every place.
static func town() -> Image:
	if _town != null:
		return _town
	_img = Image.create(TW, TH, false, Image.FORMAT_RGBA8)
	_rng.seed = 11
	for y in TH:
		for x in TW:
			var n := sin(x * 0.19 + y * 0.11) + sin(x * 0.05 - y * 0.13) * 1.4 + _rng.randf()
			_img.set_pixel(x, y, Color("4f8a3e") if n > 1.4 else (Color("467e37") if n > -0.4 else Color("3f7232")))
	# The river and its dam.
	for x in TW:
		var y := 30.0 + sin(x / 23.0) * 4.0 - x * 0.06
		_R(x, y, 1, 9, "2e6a96")
		_R(x, y, 1, 1, "4a8ab8")
	_R(46, 12, 30, 14, "8a8680"); _R(46, 12, 30, 2, "b8b4ac")
	for x in range(48, 74, 4):
		_R(x, 16, 2, 8, "6aa8d8")
	# Roads.
	_R(0, 112, TW, 7, "45434d"); _R(100, 40, 7, 150, "45434d"); _R(212, 40, 7, 150, "45434d"); _R(100, 70, 220, 6, "45434d")
	for x in range(2, TW, 9):
		_R(x, 115, 4, 1, "e8cf6a")
	# The railway from the west and the freight yard.
	for x in range(0, 90):
		_R(x, 176, 1, 6, "6e665c")
		if x % 4 == 0:
			_R(x, 175, 2, 8, "4a3020")
	_R(0, 177, 90, 1, "b8b8c0"); _R(0, 180, 90, 1, "b8b8c0")
	_R(14, 150, 46, 18, "8a5a3b"); _R(14, 150, 46, 2, "a87a5a"); _R(20, 156, 10, 12, "2a2a2e"); _R(40, 156, 10, 12, "2a2a2e")
	_R(62, 168, 22, 7, "c0392b"); _R(62, 168, 22, 1, "e05a4a")
	# Shelter: rows of kennels.
	for i in 4:
		_house(72 + i * 9, 120, 8, 8, "b8503a", "6a3a2a")
	# Dog park: lawn, path, a pond.
	_ellipse(150, 150, 24, 14, "5aa848"); _ellipse(142, 146, 6, 4, "3a7ab8")
	for i in 8:
		_P(132 + i * 5, 158, "c8b88a")
	_R(160, 140, 4, 4, "f2d14e")
	# Junkyard: heaps and a crusher.
	for p: Vector2 in [Vector2(30, 70), Vector2(48, 82), Vector2(58, 66)]:
		_ellipse(p.x, p.y, 9, 6, "6a6058")
		for k in 12:
			_P(p.x + _rng.randi_range(-7, 7), p.y + _rng.randi_range(-4, 4), ["8a3a2a", "3a5a7a", "9aa0a6", "c9a24a"][k % 4])
	_R(22, 84, 12, 8, "4a4e54")
	# Grooming salon, bakery, fire and police stations, vet, barracks.
	_house(108, 76, 22, 14, "e88aa8", "8a3a5a")
	_house(166, 96, 24, 14, "d8a052", "6a4a2a"); _R(184, 90, 3, 6, "6a6e72")
	_house(188, 42, 24, 16, "c0392b", "6a2a20"); _R(190, 54, 8, 4, "e8e4dc")
	_house(246, 88, 24, 16, "3a5a8a", "1a2a4a"); _R(252, 86, 4, 2, "e04646"); _R(258, 86, 4, 2, "4a8ae8")
	_house(284, 44, 24, 16, "e8f0f4", "6a8a9a"); _R(294, 48, 4, 8, "e04646"); _R(292, 50, 8, 4, "e04646")
	_house(298, 176, 34, 18, "5a6a3a", "2a3a1a")
	for x in range(300, 330, 6):
		_R(x, 172, 3, 3, "f2d14e")
	# Racetrack: an oval track.
	for a in 120:
		var t := a * TAU / 120.0
		_R(234 + cos(t) * 26, 164 + sin(t) * 12, 2, 2, "c8a878")
	_ellipse(234, 164, 18, 7, "5aa848")
	# Snowy hill.
	_ellipse(140, 22, 26, 12, "e8eef4"); _ellipse(136, 18, 12, 5, "ffffff")
	# Training ground: hurdles and a tunnel.
	_R(284, 128, 34, 24, "8a7a5a")
	for x in range(288, 316, 7):
		_R(x, 134, 1, 5, "f4f1ea"); _R(x - 2, 134, 5, 1, "c0392b")
	_R(290, 146, 16, 3, "3a6ac8")
	# Dog show: a tent with a red carpet.
	_house(164, 178, 28, 14, "8a3ab0", "4a1a6a"); _R(176, 190, 4, 10, "c0392b")
	# The General's kennel: a castle of a dog house on the hill.
	_R(230, 8, 42, 24, "6a5a4a"); _R(230, 8, 42, 2, "8a7a6a")
	for x in range(230, 272, 6):
		_R(x, 4, 4, 4, "6a5a4a")
	_ellipse(251, 24, 6, 7, "1a1210"); _R(245, 24, 12, 8, "1a1210")
	_R(250, -2, 1, 8, "3a3a40"); _R(251, -2, 6, 4, "c0392b")
	# Lamps and trees.
	for p: Vector2 in [Vector2(96, 108), Vector2(220, 108), Vector2(150, 64), Vector2(320, 110), Vector2(70, 150)]:
		_R(p.x, p.y - 6, 1, 6, "2a2a30"); _R(p.x - 1, p.y - 7, 3, 2, "ffe7a0")
	for p: Vector2 in [Vector2(10, 40), Vector2(20, 110), Vector2(330, 20), Vector2(200, 140), Vector2(270, 130), Vector2(120, 186)]:
		_ellipse(p.x, p.y, 5, 5, "2f6e2c"); _ellipse(p.x - 1, p.y - 1, 3, 3, "4a8a3a")
	# Night: everything a little darker and bluer.
	for y in TH:
		for x in TW:
			_img.set_pixel(x, y, _img.get_pixel(x, y).lerp(Color("1a1830"), 0.28))
	_town = _img
	return _town


static func _R(x: float, y: float, w: float, h: float, c: String) -> void:
	var r := Rect2i(int(x), int(y), int(w), int(h)).intersection(Rect2i(0, 0, TW, TH))
	if r.size.x > 0 and r.size.y > 0:
		_img.fill_rect(r, Color(c))


static func _P(x: float, y: float, c: String) -> void:
	if x >= 0 and y >= 0 and x < TW and y < TH:
		_img.set_pixel(int(x), int(y), Color(c))


static func _ellipse(cx: float, cy: float, rx: float, ry: float, c: String) -> void:
	for y in range(int(cy - ry), int(cy + ry) + 1):
		for x in range(int(cx - rx), int(cx + rx) + 1):
			if pow((x + 0.5 - cx) / rx, 2) + pow((y + 0.5 - cy) / ry, 2) <= 1.0:
				_P(x, y, c)


## A little building from above: walls, a roof edge and lit windows.
static func _house(x: float, y: float, w: float, h: float, roof: String, edge: String) -> void:
	_R(x + 2, y + h, w, 2, "1a1830")
	_R(x, y, w, h, roof)
	_R(x, y, w, 1, Color(roof).lightened(0.25).to_html(false))
	_R(x, y + h - 1, w, 1, edge)
	for wx in range(int(x) + 3, int(x + w) - 3, 6):
		_R(wx, y + h - 6, 3, 3, "ffd977")
