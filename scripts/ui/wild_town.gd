class_name WildTown
## The Wild beyond the dogs' town, drawn into DistrictMap's picture with its
## brush (DistrictMap.R, P, ellipse, _tree...): forest everywhere, a river
## with a waterfall, a swamp in the west, mountains, cliffs and a frozen lake
## in the north, and the machines' cleared strip leading east to the
## Company's fence. Twelve places (TRETIA_STVRT.md).

const PLACES := {
	"FOREST_EDGE": {"pos": Vector2(84, 330), "view": Rect2(10, 284, 150, 104)},
	"DEEP_WOODS": {"pos": Vector2(206, 258), "view": Rect2(140, 214, 136, 94)},
	"SWAMP": {"pos": Vector2(84, 186), "view": Rect2(10, 140, 150, 96)},
	"WATERFALL": {"pos": Vector2(250, 122), "view": Rect2(184, 76, 130, 92)},
	"CAVES": {"pos": Vector2(384, 76), "view": Rect2(320, 30, 130, 90)},
	"MOUNTAIN_MEADOW": {"pos": Vector2(410, 196), "view": Rect2(344, 150, 134, 92)},
	"EAGLE_CLIFFS": {"pos": Vector2(530, 60), "view": Rect2(466, 8, 130, 96)},
	"FROZEN_LAKE": {"pos": Vector2(654, 94), "view": Rect2(590, 40, 128, 100)},
	"OLD_CAMP": {"pos": Vector2(344, 326), "view": Rect2(278, 282, 134, 100)},
	"LOGGING_SITE": {"pos": Vector2(500, 300), "view": Rect2(430, 254, 140, 100)},
	"BURNT_CLEARING": {"pos": Vector2(604, 214), "view": Rect2(540, 168, 132, 92)},
	"FENCE_LINE": {"pos": Vector2(664, 342), "view": Rect2(592, 296, 126, 100)},
}


static func build() -> void:
	_ground()
	_mountains()
	_river()
	_swamp()
	_lake()
	_strip()
	_forest()
	_places()


static func _ground() -> void:
	var img := DistrictMap._img
	var rng := DistrictMap._rng
	var g := [Color("3f7a34"), Color("386f2f"), Color("47863a"), Color("31632a")]
	for y in DistrictMap.WH:
		for x in DistrictMap.WW:
			var n := sin(x * 0.11 + y * 0.09) + sin(x * 0.05 - y * 0.13) * 1.4 + rng.randf() * 1.2
			img.set_pixel(x, y, g[2] if n > 1.6 else (g[0] if n > 0.2 else (g[1] if n > -1.0 else g[3])))
	for i in 700:
		DistrictMap.P(rng.randi_range(0, DistrictMap.WW - 1), rng.randi_range(0, DistrictMap.WH - 1), "5a9a48")


## Grey peaks with snow along the north.
static func _mountains() -> void:
	for p: Vector3 in [Vector3(340, 40, 44), Vector3(420, 30, 52), Vector3(500, 46, 40), Vector3(560, 26, 50), Vector3(620, 40, 36), Vector3(700, 30, 44), Vector3(460, 120, 34)]:
		for k in int(p.z):
			var w := float(k) * 1.1
			var y := p.y - p.z * 0.5 + k
			DistrictMap.R(p.x - w, y, w, 1, "7a7a84")
			DistrictMap.R(p.x, y, w, 1, "62626c")
			if k < p.z * 0.3:
				DistrictMap.R(p.x - w, y, w * 2.0, 1, "eef4f8")


## A river from the north-west down to the south, with the waterfall.
static func _river() -> void:
	for y in range(0, DistrictMap.WH):
		var x := 230.0 + sin(y / 36.0) * 18.0 + (y - 120) * 0.25 if y > 120 else 260.0 - y * 0.08
		var wide := 10 if y > 130 else 7
		for k in wide:
			DistrictMap.P(x + k, y, "2e729e" if k > 1 and k < wide - 2 else "3d90c0")
		DistrictMap.P(x - 1, y, "8a7a5a")
		DistrictMap.P(x + wide, y, "8a7a5a")
	# The waterfall: white falling water and a pool.
	DistrictMap.R(244, 104, 12, 22, "e8f4fc")
	for i in 10:
		DistrictMap.P(244 + i, 104 + (i * 7) % 22, "b8d8ec")
	DistrictMap.ellipse(250, 132, 16, 7, "3d90c0")
	DistrictMap.R(232, 100, 36, 4, "6a6a72")


static func _swamp() -> void:
	var rng := DistrictMap._rng
	DistrictMap.ellipse(84, 190, 70, 36, "4a5a34")
	for i in 14:
		DistrictMap.ellipse(30 + rng.randi_range(0, 110), 165 + rng.randi_range(0, 50), rng.randi_range(5, 12), rng.randi_range(3, 6), "3a5a5a")
	for i in 60:
		var x := 20 + rng.randi_range(0, 130)
		var y := 160 + rng.randi_range(0, 60)
		DistrictMap.R(x, y, 1, 4, "8a9a4a")
		DistrictMap.P(x, y - 1, "6a4a2a")


static func _lake() -> void:
	DistrictMap.ellipse(656, 100, 48, 26, "b8d8ec")
	DistrictMap.ellipse(650, 96, 30, 14, "d8ecf8")
	for i in 8:
		DistrictMap.R(630 + i * 7, 92 + (i % 3) * 6, 5, 1, "8ab8d8")


## The machines' strip: cut trees, stumps and caterpillar tracks to the fence.
static func _strip() -> void:
	var rng := DistrictMap._rng
	for x in range(300, DistrictMap.WW):
		var y := 300.0 + (x - 300) * 0.1
		for k in 34:
			DistrictMap.P(x, y - 17 + k, "8a6a44" if (x + k) % 7 else "7a5a3a")
		if x % 6 == 0:
			DistrictMap.R(x, y - 8, 3, 1, "5a4a3a")
			DistrictMap.R(x, y + 6, 3, 1, "5a4a3a")
	for i in 30:
		var x := 310 + rng.randi_range(0, 380)
		DistrictMap.ellipse(x, 300 + (x - 300) * 0.1 + rng.randi_range(-14, 14), 3, 2, "c8a070")
	# Burnt ground.
	DistrictMap.ellipse(604, 216, 46, 30, "3a3430")
	for i in 30:
		DistrictMap.P(570 + rng.randi_range(0, 70), 196 + rng.randi_range(0, 40), "e0802a" if i % 4 == 0 else "1a1a1e")
	# The Company's fence in the south-east.
	for y in range(300, DistrictMap.WH):
		DistrictMap.P(700, y, "9aa0a6")
		if y % 6 == 0:
			DistrictMap.R(699, y, 3, 1, "c8ccd0")
	DistrictMap.R(640, 380, 60, 3, "9aa0a6")
	DistrictMap.R(684, 334, 14, 18, "c0392b")
	DistrictMap.R(686, 338, 10, 2, "f4f1ea")


static func _forest() -> void:
	var rng := DistrictMap._rng
	for i in 520:
		var x := rng.randi_range(0, DistrictMap.WW - 1)
		var y := rng.randi_range(8, DistrictMap.WH - 4)
		if _clear(x, y):
			continue
		if y < 60 and x > 300:
			continue
		var pine := rng.randf() < 0.45
		if pine:
			DistrictMap._tree(x, y, rng.randi_range(3, 5), "1f4a26", "2a5e30", "3a7a3a")
		else:
			DistrictMap._tree(x, y, rng.randi_range(3, 6))


## No trees on water, the strip, the swamp pools or the places' own spots.
static func _clear(x: int, y: int) -> bool:
	if absf(x - (230.0 + sin(y / 36.0) * 18.0 + (y - 120) * 0.25 if y > 120 else 260.0 - y * 0.08)) < 16.0:
		return true
	if x > 296 and absf(y - (300.0 + (x - 300) * 0.1)) < 22.0:
		return true
	if Vector2(x, y).distance_to(Vector2(656, 100)) < 52.0:
		return true
	for id: String in PLACES:
		if Vector2(x, y).distance_to(PLACES[id]["pos"]) < 24.0:
			return true
	return false


static func _places() -> void:
	# Forest edge: the road from the dogs' town ends at a log gate.
	DistrictMap.R(0, 334, 70, 8, "8a7a5a")
	DistrictMap.R(66, 326, 4, 18, "6a4a2a"); DistrictMap.R(96, 326, 4, 18, "6a4a2a"); DistrictMap.R(64, 324, 38, 3, "8a5a3a")
	# Deep woods: a dark heart.
	DistrictMap.dim_ellipse(206, 262, 30, 20, 0.35)
	# Caves: a dark mouth in the rock.
	DistrictMap.ellipse(384, 84, 16, 10, "4a4a52"); DistrictMap.ellipse(384, 88, 9, 6, "141418")
	# Meadow: flowers.
	var rng := DistrictMap._rng
	DistrictMap.ellipse(410, 200, 34, 20, "6aa850")
	for i in 30:
		DistrictMap.P(380 + rng.randi_range(0, 60), 186 + rng.randi_range(0, 28), ["f2d14e", "e04646", "f4f1ea", "a070e0"][i % 4])
	# Eagle cliffs: a nest on a peak.
	DistrictMap.ellipse(530, 58, 7, 3, "8a6a3a"); DistrictMap.P(528, 56, "f4f1ea"); DistrictMap.P(532, 56, "f4f1ea")
	# Old camp: tents and a fire.
	for p: Vector2 in [Vector2(330, 318), Vector2(356, 320)]:
		for k in 8:
			DistrictMap.R(p.x - k, p.y - 8 + k, k * 2, 1, "e08a2a" if p.x < 340 else "3a6ac8")
	DistrictMap.ellipse(344, 334, 3, 2, "f2a12e"); DistrictMap.P(344, 332, "f2d14e")
	# Logging site: a parked bulldozer and stacked logs.
	DistrictMap.R(486, 292, 22, 12, "e8c02a"); DistrictMap.R(484, 302, 26, 4, "2a2a2e"); DistrictMap.R(480, 290, 4, 14, "8a8a94")
	for k in 4:
		DistrictMap.R(512, 300 + k * 3, 18, 2, "8a5a3a")
	DistrictMap._lamp(470, 300)
