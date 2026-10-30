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

## Garden: golden sunset, a green-blue night, a bright dawn.
const GARDEN_KEYS := [
	[0.0, Color(1.0, 0.9, 0.78)],
	[0.2, Color(0.8, 0.82, 0.92)],
	[0.4, Color(0.6, 0.7, 0.86)],
	[0.85, Color(0.6, 0.7, 0.86)],
	[0.95, Color(0.95, 0.8, 0.78)],
	[1.0, Color(1.0, 0.95, 0.85)],
]

## Rooftop: purple dusk and a night lit by the city.
const ROOFTOP_KEYS := [
	[0.0, Color(0.95, 0.82, 0.88)],
	[0.2, Color(0.72, 0.68, 0.9)],
	[0.4, Color(0.6, 0.6, 0.86)],
	[0.85, Color(0.62, 0.6, 0.86)],
	[0.95, Color(0.95, 0.78, 0.72)],
	[1.0, Color(1.0, 0.92, 0.82)],
]

## Supermarket: cold shop lights after closing time.
const SUPERMARKET_KEYS := [
	[0.0, Color(0.96, 0.97, 0.95)],
	[0.2, Color(0.78, 0.82, 0.9)],
	[0.4, Color(0.66, 0.72, 0.86)],
	[0.85, Color(0.66, 0.72, 0.86)],
	[0.95, Color(0.9, 0.82, 0.8)],
	[1.0, Color(1.0, 0.95, 0.88)],
]

## Harbor: a warm sunset, then fog rolling in from the sea.
const HARBOR_KEYS := [
	[0.0, Color(0.98, 0.88, 0.8)],
	[0.2, Color(0.74, 0.8, 0.88)],
	[0.4, Color(0.58, 0.68, 0.82)],
	[0.85, Color(0.58, 0.68, 0.82)],
	[0.95, Color(0.94, 0.8, 0.74)],
	[1.0, Color(1.0, 0.93, 0.84)],
]

## Factory: orange furnace light, then a cold machine-hall night.
const FACTORY_KEYS := [
	[0.0, Color(1.0, 0.88, 0.76)],
	[0.2, Color(0.8, 0.76, 0.84)],
	[0.4, Color(0.62, 0.64, 0.78)],
	[0.85, Color(0.62, 0.64, 0.78)],
	[0.95, Color(0.95, 0.8, 0.72)],
	[1.0, Color(1.0, 0.93, 0.84)],
]

const THEME_KEYS := {"basement": BASEMENT_KEYS, "garden": GARDEN_KEYS, "rooftop": ROOFTOP_KEYS,
	"supermarket": SUPERMARKET_KEYS, "harbor": HARBOR_KEYS, "factory": FACTORY_KEYS,
	"park": GARDEN_KEYS, "island": HARBOR_KEYS, "station": ROOFTOP_KEYS}

var spawner: Spawner
var _keys: Array = KEYS
## Above 0 while a quest has turned the lights off.
var dark := 0
## 0..1: how deep the cat has wandered into a map that darkens with
## distance (a "far" secret with "dark_from", see QuestDirector).
var far_dark := 0.0
var _cat_light: PointLight2D


func setup(p_spawner: Spawner, player: Player) -> void:
	spawner = p_spawner
	_keys = THEME_KEYS.get(spawner.stage().get("theme", "apartment"), KEYS)
	var light := PointLight2D.new()
	light.texture = FloorChunk._get_light_texture()
	light.texture_scale = 2.4
	light.energy = 0.35
	light.color = Color(1.0, 0.95, 0.85)
	player.add_child(light)
	_cat_light = light


func _process(_delta: float) -> void:
	if spawner == null:
		return
	var t := clampf(spawner.elapsed / (spawner.duration_minutes() * 60.0), 0.0, 1.0)
	var tint: Color = _keys[-1][1]
	for i in _keys.size() - 1:
		var a: Array = _keys[i]
		var b: Array = _keys[i + 1]
		if t <= b[0]:
			tint = (a[1] as Color).lerp(b[1], (t - a[0]) / (b[0] - a[0]))
			break
	# 0..1: lights out (quest) is full, the far dark grows on the way.
	var gloom := 1.0 if dark > 0 else far_dark
	if gloom > 0.0:
		tint = tint.darkened(0.82 * gloom)
	color = tint
	if _cat_light != null:
		_cat_light.energy = lerpf(0.35, 1.4, gloom)
		# In daylight the glow shows little; switched off it also lets Godot
		# draw more of the crowd in one go (a light splits batches).
		_cat_light.visible = gloom > 0.0 or tint.get_luminance() < 0.8
		_cat_light.texture_scale = lerpf(2.4, 3.2, gloom)
