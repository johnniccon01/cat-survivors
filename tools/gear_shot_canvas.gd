extends Node2D
## Draws the cats for tools/gear_shot.gd.

const CATS := ["MICA", "TUCKO", "PIP", "KAPITAN"]
const OUTFITS := [
	{"hat": "PARTY_HAT", "collar": "BELL_COLLAR", "vest": "KNIT_VEST", "paws": "SOCKS", "tail": "TAIL_BOW"},
	{"hat": "COUNT_HAT", "collar": "RED_COLLAR", "vest": "CAPE", "paws": "BOOTIES", "tail": "TAIL_BELL"},
	{"hat": "WIZARD_HAT", "collar": "SPIKED_COLLAR", "vest": "RAINCOAT", "paws": "MITTENS", "tail": "TAIL_RIBBON"},
]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("3a5a3a")
	bg.size = Vector2(1100, 760)
	bg.show_behind_parent = true
	add_child(bg)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for i in CATS.size():
		for j in OUTFITS.size():
			var lk := CatArt.look(CATS[i])
			var gear := {}
			var outfit: Dictionary = OUTFITS[j]
			for slot: String in outfit:
				var base: String = outfit[slot]
				var info: Dictionary = GameData.items["bases"].get(base, GameData.items["legendaries"].get(base, {}))
				var color := Color(info.get("color", "#ffffff"))
				if slot == "hat":
					gear["hat"] = base
					gear["color"] = color
				else:
					gear[slot] = {"base": base, "color": color}
			lk["gear"] = gear
			# Different walk moments, so paws and tail are seen moving.
			CatArt.draw(self, lk, 1, float(j) * 0.7, false, false, "normal", Vector2(130 + i * 260, 150 + j * 230), 5.0, true)
