class_name Shapes
## Small drawing helpers for the procedural placeholder art.


static func ellipse(center: Vector2, rx: float, ry: float, segments: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * i / segments
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out
