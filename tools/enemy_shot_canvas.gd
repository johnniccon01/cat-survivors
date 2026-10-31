extends Node2D
## Draws the enemies of `stage` for tools/enemy_shot.gd.

var stage := "LIVING_ROOM"
var _ids: Array[String] = []


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("8a5a3b")
	bg.size = Vector2(1280, 720)
	bg.show_behind_parent = true
	add_child(bg)
	var data: Dictionary = GameData.stages[stage]
	for w: Dictionary in data["waves"]:
		for id: Variant in w.get("enemies", []) + w.get("bosses", []):
			var key := String(id) if id is String else String((id as Dictionary).get("id", ""))
			if key != "" and key not in _ids:
				_ids.append(key)
	for e: Dictionary in data.get("events", []):
		if String(e.get("enemy", "")) not in _ids:
			_ids.append(String(e.get("enemy", "")))
	for p: String in data.get("props", []):
		if p not in _ids:
			_ids.append(p)
	if String(data.get("final_boss", "")) != "":
		_ids.append(String(data["final_boss"]))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in _ids.size():
		var info := Sprites.enemy(_ids[i])
		var at := Vector2(110 + (i % 6) * 200, 150 + (i / 6) * 260)
		if not info.is_empty():
			draw_set_transform(at, 0.0, Vector2(4, 4))
			Sprites.draw_frame(self, info, 0, 0)
			draw_set_transform(Vector2.ZERO)
		draw_string(font, at + Vector2(-60, 110), _ids[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
