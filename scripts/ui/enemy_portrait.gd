class_name EnemyPortrait
extends Control
## An enemy's sprite for the bestiary, scaled to fit; a dark silhouette when
## the enemy hasn't been met yet.

const SILHOUETTE := Color(0.12, 0.09, 0.15)

var enemy_id := ""
var known := true


func _init(p_id: String = "", p_known: bool = true) -> void:
	enemy_id = p_id
	known = p_known
	custom_minimum_size = Vector2(56, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var data: Dictionary = GameData.enemies.get(enemy_id, {})
	var center := size * 0.5 + Vector2(0, 4)
	if data.get("shape", "") == "cat":
		var lk := CatArt.look(data.get("cat", "MICA")).duplicate()
		lk["silhouette"] = not known
		CatArt.draw(self, lk, 1, 0.0, false, false, "angry", center, 1.3, false)
		return
	var sprite := Sprites.enemy(enemy_id)
	if sprite.is_empty():
		return
	var zoom := 2.0
	draw_set_transform(center, 0.0, Vector2(zoom, zoom))
	Sprites.draw_frame(self, sprite, 0, 0, Color.WHITE if known else SILHOUETTE)
	draw_set_transform(Vector2.ZERO)
