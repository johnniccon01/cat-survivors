class_name CompanyTown
## The Company: a huge fenced compound at the end of the Wild, drawn into
## DistrictMap's picture with its brush. The gate and car park in the
## south-west, the machine garage, the laboratory with its cages, and the
## director's glass tower in the north-east. Four places (TRETIA_STVRT.md).

const PLACES := {
	"COMPANY_LOT": {"pos": Vector2(132, 300), "view": Rect2(40, 244, 190, 124)},
	"MACHINE_GARAGE": {"pos": Vector2(320, 236), "view": Rect2(236, 180, 180, 120)},
	"COMPANY_LAB": {"pos": Vector2(530, 292), "view": Rect2(442, 236, 180, 120)},
	"DIRECTOR_TOWER": {"pos": Vector2(566, 96), "view": Rect2(470, 20, 200, 140)},
}


static func build() -> void:
	_ground()
	_fence()
	_lot()
	_garage()
	_lab()
	_tower()
	_forest_rim()


static func _ground() -> void:
	var img := DistrictMap._img
	var rng := DistrictMap._rng
	for y in DistrictMap.WH:
		for x in DistrictMap.WW:
			var c := Color("7a7a80") if (x / 24 + y / 24) % 2 == 0 else Color("74747a")
			img.set_pixel(x, y, c.darkened(rng.randf() * 0.05))
	# Roads between the buildings.
	for y0: int in [190, 340]:
		DistrictMap.R(20, y0, 680, 14, "45434d")
		for x in range(24, 700, 12):
			DistrictMap.R(x, y0 + 6, 6, 1, "e8cf6a")
	DistrictMap.R(440, 40, 14, 310, "45434d")
	for y in range(44, 350, 12):
		DistrictMap.R(446, y, 1, 6, "e8cf6a")


static func _fence() -> void:
	for x in range(10, 710):
		DistrictMap.P(x, 14, "c8ccd0"); DistrictMap.P(x, 386, "c8ccd0")
	for y in range(14, 387):
		DistrictMap.P(10, y, "c8ccd0"); DistrictMap.P(709, y, "c8ccd0")
	for x in range(10, 710, 10):
		DistrictMap.R(x, 12, 1, 4, "6a6a72"); DistrictMap.R(x, 384, 1, 4, "6a6a72")


static func _lot() -> void:
	# The gate with its barrier and the guard booth.
	DistrictMap.R(20, 330, 30, 22, "3a3a40"); DistrictMap.R(22, 332, 26, 6, "8ab8d8")
	for x in range(52, 110, 6):
		DistrictMap.R(x, 344, 4, 2, "c0392b" if (x / 6) % 2 == 0 else "f4f1ea")
	# Parked cars in rows.
	var colors := ["c0392b", "3a6ac8", "e0a020", "8a3ab0", "f4f1ea", "2a2a2e"]
	for row in 3:
		for i in 7:
			DistrictMap.R(80 + i * 18, 250 + row * 26, 1, 18, "e8e4dc")
			if (row + i) % 3 != 0:
				DistrictMap._car(84 + i * 18, 254 + row * 26, colors[(row * 7 + i) % colors.size()], true)
	DistrictMap._lamp(70, 240); DistrictMap._lamp(210, 240)


static func _garage() -> void:
	DistrictMap.dim(262, 216, 120, 50, 0.3)
	DistrictMap.R(256, 206, 120, 50, "8a6a3a")
	DistrictMap.R(256, 206, 120, 3, "a8844a")
	for i in 4:
		DistrictMap.R(264 + i * 28, 226, 22, 30, "3a3a40")
		DistrictMap.R(264 + i * 28, 226 + (i % 2) * 10, 22, 2, "6a6a72")
	# A bulldozer outside.
	DistrictMap.R(300, 268, 26, 12, "e8c02a"); DistrictMap.R(298, 278, 30, 4, "2a2a2e"); DistrictMap.R(292, 266, 4, 16, "8a8a94")


static func _lab() -> void:
	DistrictMap.dim(474, 266, 120, 50, 0.3)
	DistrictMap.R(470, 256, 120, 50, "e8ecf0")
	DistrictMap.R(470, 256, 120, 3, "c8d8e8")
	for i in 6:
		DistrictMap._window(478 + i * 18, 264, 10, 8, i % 2 == 0)
	# Cages in the yard.
	for i in 4:
		DistrictMap.R(480 + i * 26, 318, 18, 12, "4a4a52")
		for k in 5:
			DistrictMap.R(482 + i * 26 + k * 4, 318, 1, 12, "c8ccd0")
	DistrictMap._lamp(462, 260); DistrictMap._lamp(600, 260)


static func _tower() -> void:
	DistrictMap.dim(536, 44, 64, 120, 0.35)
	DistrictMap.R(530, 30, 64, 116, "2a4a6a")
	for y in range(36, 140, 8):
		for x in range(534, 590, 8):
			DistrictMap.R(x, y, 6, 5, "8ab8d8" if (x + y) % 3 else "f2d14e")
	DistrictMap.R(530, 28, 64, 3, "c8ccd0")
	# The logo on top and the helipad.
	DistrictMap.ellipse(562, 22, 10, 5, "c0392b")
	DistrictMap.ellipse(640, 70, 20, 12, "4a4a52"); DistrictMap.R(634, 64, 2, 12, "f4f1ea"); DistrictMap.R(646, 64, 2, 12, "f4f1ea"); DistrictMap.R(634, 69, 14, 2, "f4f1ea")


## What is left of the forest outside the fence.
static func _forest_rim() -> void:
	var rng := DistrictMap._rng
	for i in 60:
		var x := rng.randi_range(14, 140)
		var y := rng.randi_range(24, 170)
		DistrictMap._tree(x, y, rng.randi_range(3, 5))
	for i in 24:
		DistrictMap.ellipse(150 + rng.randi_range(0, 200), 40 + rng.randi_range(0, 120), 3, 2, "c8a070")
