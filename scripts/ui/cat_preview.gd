class_name CatPreview
extends Control
## A big animated cat for the selection screen; locked cats are drawn as a
## dark silhouette.

const SILHOUETTE := Color(0.12, 0.09, 0.15)

var cat_id := "MICA"
var locked := false
var walking := false
## Drawing scale (the select screen uses 3, the journal less).
var zoom := 3.0

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta * (12.0 if walking else 2.0)
	queue_redraw()


func _draw() -> void:
	var lk := CatArt.look(cat_id).duplicate()
	if locked:
		for key: String in ["fur", "dark", "belly", "eyes"]:
			lk[key] = SILHOUETTE
		lk["stripes"] = false
		lk["patches"] = false
		lk["silhouette"] = true
	CatArt.draw(self, lk, 1, _t, false, false, "normal", size * 0.5, zoom, walking)
