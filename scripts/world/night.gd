extends CanvasModulate
## Tints the world over the run: warm evening, a blue night, then dawn right
## before the stage is cleared. Also gives the cat a faint light so it stays
## readable in the dark (lamps in floor_chunk.gd add their own lights).

## [fraction of the run, color]
const KEYS := [
	[0.0, Color(0.98, 0.93, 0.86)],
	[0.15, Color(0.78, 0.79, 0.95)],
	[0.35, Color(0.64, 0.67, 0.9)],
	[0.85, Color(0.64, 0.67, 0.9)],
	[0.95, Color(0.86, 0.76, 0.78)],
	[1.0, Color(1.0, 0.92, 0.82)],
]

## Basement: dim and cold the whole night, a little warmer at the end.
const BASEMENT_KEYS := [
	[0.0, Color(0.6, 0.6, 0.68)],
	[0.9, Color(0.55, 0.56, 0.66)],
	[1.0, Color(0.75, 0.7, 0.66)],
]

var spawner: Spawner
var _keys: Array = KEYS


func setup(p_spawner: Spawner, player: Player) -> void:
	spawner = p_spawner
	if spawner.stage().get("theme", "apartment") == "basement":
		_keys = BASEMENT_KEYS
	var light := PointLight2D.new()
	light.texture = FloorChunk._get_light_texture()
	light.texture_scale = 2.4
	light.energy = 0.35
	light.color = Color(1.0, 0.95, 0.85)
	player.add_child(light)


func _process(_delta: float) -> void:
	if spawner == null:
		return
	var t := clampf(spawner.elapsed / (spawner.duration_minutes() * 60.0), 0.0, 1.0)
	for i in _keys.size() - 1:
		var a: Array = _keys[i]
		var b: Array = _keys[i + 1]
		if t <= b[0]:
			color = (a[1] as Color).lerp(b[1], (t - a[0]) / (b[0] - a[0]))
			return
	color = _keys[-1][1]
