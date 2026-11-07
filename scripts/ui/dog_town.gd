class_name DogTown
## The Dog District's town, drawn into DistrictMap's picture with its own
## brush (DistrictMap.R, P, ellipse, _tree...): a river and its dam in the
## north, the railway from the cat town coming in from the west to the
## freight yard, and the sixteen places of PSIE_STVRTE.md.

const PLACES := {
	"FREIGHT_YARD": {"pos": Vector2(92, 318), "view": Rect2(14, 280, 176, 104)},
	"DOG_SHELTER": {"pos": Vector2(214, 252), "view": Rect2(156, 214, 120, 84)},
	"DOG_PARK": {"pos": Vector2(336, 304), "view": Rect2(262, 252, 150, 112)},
	"JUNKYARD": {"pos": Vector2(92, 176), "view": Rect2(16, 124, 160, 100)},
	"GROOMING_SALON": {"pos": Vector2(226, 150), "view": Rect2(180, 112, 100, 78)},
	"BONE_BAKERY": {"pos": Vector2(366, 182), "view": Rect2(316, 142, 104, 80)},
	"RACETRACK": {"pos": Vector2(510, 318), "view": Rect2(426, 268, 166, 112)},
	"FIRE_STATION": {"pos": Vector2(410, 80), "view": Rect2(360, 42, 104, 80)},
	"POLICE_K9": {"pos": Vector2(546, 196), "view": Rect2(486, 154, 120, 82)},
	"VET_CLINIC": {"pos": Vector2(528, 82), "view": Rect2(480, 44, 104, 78)},
	"RIVER_DAM": {"pos": Vector2(104, 54), "view": Rect2(30, 6, 150, 96)},
	"SNOW_HILL": {"pos": Vector2(266, 48), "view": Rect2(196, 2, 140, 92)},
	"TRAINING_GROUND": {"pos": Vector2(650, 286), "view": Rect2(590, 236, 128, 100)},
	"DOG_SHOW": {"pos": Vector2(370, 372), "view": Rect2(318, 336, 116, 64)},
	"BARRACKS": {"pos": Vector2(654, 372), "view": Rect2(596, 336, 122, 64)},
	"GENERAL_KENNEL": {"pos": Vector2(664, 70), "view": Rect2(604, 4, 116, 110)},
}

static func build() -> void:
	_ground()
	_river()
	_roads()
	_railway()
	_freight_yard()
	_shelter()
	_park()
	_junkyard()
	_salon()
	_bakery()
	_racetrack()
	_fire_station()
	_police()
	_vet()
	_dam()
	_snow_hill()
	_training()
	_show()
	_barracks()
	_kennel()
	_scatter()


static func _ground() -> void:
	var img := DistrictMap._img
	var rng := DistrictMap._rng
	var g := [Color("5c9443"), Color("558b3d"), Color("62a04a"), Color("4f8239")]
	for y in DistrictMap.WH:
		for x in DistrictMap.WW:
			var n := sin(x * 0.17 + y * 0.12) + sin(x * 0.06 - y * 0.1) * 1.5 + rng.randf() * 1.2
			img.set_pixel(x, y, g[2] if n > 1.6 else (g[0] if n > 0.2 else (g[1] if n > -1.0 else g[3])))
	for i in 900:
		var x := rng.randi_range(0, DistrictMap.WW - 1)
		var y := rng.randi_range(0, DistrictMap.WH - 2)
		DistrictMap.P(x, y, "78b85a")
		DistrictMap.P(x, y + 1, "4a7a34")


static func _river() -> void:
	for x in DistrictMap.WW:
		var y := 18.0 + sin(x / 40.0) * 6.0 + x * 0.02
		for k in 14:
			var c := "2e729e" if k > 2 and k < 11 else "3d90c0"
			DistrictMap.P(x, y + k, c if (x + k) % 9 else "3884b4")
		DistrictMap.P(x, y - 1, "c9ad78")
		DistrictMap.P(x, y + 14, "c9ad78")


static func _roads() -> void:
	for y0: int in [122, 232]:
		DistrictMap.R(0, y0, DistrictMap.WW, 12, "a49c8e"); DistrictMap.R(0, y0 + 2, DistrictMap.WW, 8, "45434d")
		for x in range(4, DistrictMap.WW, 10):
			DistrictMap.R(x, y0 + 6, 5, 1, "e8cf6a")
	for x0: int in [300, 470]:
		DistrictMap.R(x0, 40, 12, 360, "a49c8e"); DistrictMap.R(x0 + 2, 40, 8, 360, "45434d")
		for y in range(44, 400, 10):
			DistrictMap.R(x0 + 6, y, 1, 5, "e8cf6a")
	DistrictMap._car(60, 124, "c0392b"); DistrictMap._car(520, 236, "3a6ac8"); DistrictMap._car(302, 300, "e0a020", true); DistrictMap._car(472, 160, "8a3ab0", true)


static func _railway() -> void:
	var y := 346
	for x in range(0, 200):
		for yy in range(y - 3, y + 13):
			DistrictMap.P(x, yy, "6a6258" if (x * 7 + yy * 13) % 5 == 0 else "7a7268")
	for x in range(0, 200, 4):
		DistrictMap.R(x, y, 2, 10, "5a3a24")
	DistrictMap.R(0, y + 2, 200, 1, "b8b8c0"); DistrictMap.R(0, y + 7, 200, 1, "b8b8c0")


static func _house(x: float, y: float, w: float, h: float, roof: String, windows: int = 3) -> void:
	DistrictMap.dim(x + 3, y + h, w, 4, 0.3)
	DistrictMap.R(x, y, w, h, roof)
	DistrictMap.R(x, y, w, 2, Color(roof).lightened(0.25))
	DistrictMap.R(x, y + h - 2, w, 2, Color(roof).darkened(0.3))
	for i in windows:
		DistrictMap._window(x + 6 + i * (w - 12) / maxf(windows, 1), y + h - 10, 5, 5, i % 2 == 0)


static func _freight_yard() -> void:
	DistrictMap.R(20, 290, 150, 40, "6e665c")
	_house(40, 292, 70, 24, "8a5a3b", 4)
	DistrictMap.R(120, 300, 34, 14, "c0392b"); DistrictMap.R(120, 300, 34, 1, "e05a4a")
	DistrictMap.R(124, 318, 30, 10, "3a5a7a")
	DistrictMap.R(30, 330, 8, 12, "e8c02a"); DistrictMap.R(26, 328, 16, 2, "e8c02a")
	DistrictMap._lamp(26, 326); DistrictMap._lamp(166, 326)


static func _shelter() -> void:
	for i in 5:
		_house(168 + i * 20, 244, 16, 14, "b8503a", 1)
	DistrictMap.R(166, 262, 104, 3, "c8a070")
	DistrictMap._lamp(164, 250)


static func _park() -> void:
	DistrictMap.ellipse(336, 300, 56, 34, "6aa850")
	DistrictMap.ellipse(318, 292, 12, 7, "3a7ab8")
	for i in 24:
		DistrictMap.P(290 + i * 4, 318 + sin(i) * 2, "c8b88a")
	for p: Vector2 in [Vector2(360, 285), Vector2(372, 312), Vector2(300, 318)]:
		DistrictMap._tree(p.x, p.y, 5)
	DistrictMap.R(350, 296, 3, 3, "f2d14e"); DistrictMap.R(340, 312, 3, 3, "e04646")
	DistrictMap._bench(320, 322); DistrictMap._lamp(380, 300)


static func _junkyard() -> void:
	var rng := DistrictMap._rng
	for p: Vector2 in [Vector2(52, 160), Vector2(84, 186), Vector2(120, 164), Vector2(140, 196)]:
		DistrictMap.ellipse(p.x, p.y, 16, 10, "6a6058")
		for k in 40:
			DistrictMap.P(p.x + rng.randi_range(-14, 14), p.y + rng.randi_range(-8, 8), ["8a3a2a", "3a5a7a", "9aa0a6", "c9a24a", "4a4e54"][k % 5])
	DistrictMap.R(30, 196, 24, 14, "4a4e54"); DistrictMap.R(30, 196, 24, 2, "8a9096")
	for x in range(20, 170, 3):
		DistrictMap.R(x, 136, 2, 3, "8a9096"); DistrictMap.R(x, 214, 2, 3, "8a9096")


static func _salon() -> void:
	_house(196, 136, 60, 28, "e88aa8", 4)
	DistrictMap.R(196, 134, 60, 3, "f4f1ea")
	DistrictMap.ellipse(226, 132, 8, 3, "f8c8e0")


static func _bakery() -> void:
	_house(332, 164, 66, 28, "d8a052", 4)
	DistrictMap.R(388, 154, 5, 12, "6a6e72")
	DistrictMap.ellipse(390, 150, 4, 3, "c8c8c8")


static func _racetrack() -> void:
	for a in 240:
		var t := a * TAU / 240.0
		DistrictMap.R(510 + cos(t) * 66, 318 + sin(t) * 34, 3, 3, "c8a878")
	DistrictMap.ellipse(510, 318, 50, 22, "6aa850")
	DistrictMap.R(460, 278, 100, 6, "8a5a3b")
	for x in range(462, 558, 6):
		DistrictMap.R(x, 279, 4, 4, ["c0392b", "3a6ac8", "f2d14e"][(x / 6) % 3])


static func _fire_station() -> void:
	_house(372, 66, 76, 30, "c0392b", 2)
	DistrictMap.R(384, 82, 16, 14, "e8e4dc"); DistrictMap.R(408, 82, 16, 14, "e8e4dc")
	DistrictMap.R(440, 50, 6, 16, "8a3a2a")


static func _police() -> void:
	_house(504, 180, 84, 30, "3a5a8a", 5)
	DistrictMap.R(530, 176, 6, 4, "e04646"); DistrictMap.R(540, 176, 6, 4, "4a8ae8")
	for x in range(500, 594, 4):
		DistrictMap.R(x, 214, 2, 6, "9aa0a6")


static func _vet() -> void:
	_house(494, 66, 70, 28, "e8f0f4", 4)
	DistrictMap.R(522, 70, 4, 12, "e04646"); DistrictMap.R(518, 74, 12, 4, "e04646")


static func _dam() -> void:
	DistrictMap.R(70, 22, 70, 22, "8a8680"); DistrictMap.R(70, 22, 70, 3, "b8b4ac")
	for x in range(74, 136, 5):
		DistrictMap.R(x, 30, 3, 12, "6aa8d8")
	DistrictMap.R(60, 44, 90, 6, "c9ad78")


static func _snow_hill() -> void:
	DistrictMap.ellipse(266, 44, 58, 30, "dfe8f0")
	DistrictMap.ellipse(256, 36, 30, 14, "ffffff")
	for i in 6:
		DistrictMap._pine(220 + i * 18, 70 + (i % 2) * 6, 10)
	DistrictMap.R(270, 52, 12, 3, "c0392b")


static func _training() -> void:
	DistrictMap.R(596, 252, 112, 64, "8a7a5a")
	for x in range(604, 700, 14):
		DistrictMap.R(x, 268, 1, 8, "f4f1ea"); DistrictMap.R(x - 3, 268, 8, 1, "c0392b")
	DistrictMap.R(612, 294, 40, 6, "3a6ac8"); DistrictMap.R(612, 294, 40, 1, "5a8ae8")
	for x in range(596, 708, 3):
		DistrictMap.R(x, 250, 2, 3, "c8a070")


static func _show() -> void:
	DistrictMap.R(330, 356, 82, 30, "8a3ab0"); DistrictMap.R(330, 356, 82, 3, "b06ad8")
	DistrictMap.R(366, 370, 10, 30, "c0392b")
	for x in range(334, 410, 10):
		DistrictMap.R(x, 352, 6, 4, "f2d14e")


static func _barracks() -> void:
	for i in 3:
		_house(604 + i * 38, 356, 34, 20, "5a6a3a", 2)
	DistrictMap.R(600, 380, 116, 3, "6a5a3a")
	DistrictMap.R(690, 340, 2, 14, "3a3a40"); DistrictMap.R(692, 340, 8, 5, "c0392b")


static func _kennel() -> void:
	# A dog house the size of a castle, on the hill.
	DistrictMap.ellipse(664, 84, 54, 22, "4f8239")
	DistrictMap.R(624, 34, 80, 44, "6a5a4a"); DistrictMap.R(624, 34, 80, 3, "8a7a6a")
	for x in range(624, 704, 10):
		DistrictMap.R(x, 28, 6, 6, "6a5a4a")
	DistrictMap.R(612, 24, 14, 54, "5a4a3a"); DistrictMap.R(702, 24, 14, 54, "5a4a3a")
	DistrictMap.ellipse(664, 62, 10, 12, "1a1210"); DistrictMap.R(654, 62, 20, 16, "1a1210")
	DistrictMap.R(663, 6, 2, 18, "3a3a40"); DistrictMap.R(665, 6, 12, 7, "c0392b")
	DistrictMap._window(632, 44, 6, 6); DistrictMap._window(690, 44, 6, 6)


static func _scatter() -> void:
	for p: Vector2 in [Vector2(20, 100), Vector2(180, 100), Vector2(460, 140), Vector2(600, 140), Vector2(700, 200),
			Vector2(250, 300), Vector2(440, 380), Vector2(560, 380), Vector2(200, 380), Vector2(20, 250)]:
		DistrictMap._tree(p.x, p.y, 6)
	for p: Vector2 in [Vector2(150, 120), Vector2(296, 230), Vector2(466, 120), Vector2(620, 230), Vector2(150, 230), Vector2(296, 120)]:
		DistrictMap._lamp(p.x, p.y)
