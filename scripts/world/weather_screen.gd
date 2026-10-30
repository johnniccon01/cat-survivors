class_name WeatherScreen
extends Control
## The weather drawn over the screen: rain streaks, leaves in the wind,
## frost flakes, a lightning flash, and fog from a small shader. A fixed
## number of dots and lines (fewer with lower effects), so it costs the same
## however busy the night is.

const FOG_SHADER := """
shader_type canvas_item;
uniform float t;
void fragment() {
	vec2 p = UV - 0.5;
	p.x *= 1.6;
	float edge = smoothstep(0.18, 0.62, length(p));
	float drift = 0.5 + 0.5 * sin(UV.x * 7.0 + t * 0.4) * sin(UV.y * 5.0 - t * 0.3);
	COLOR = vec4(0.82, 0.83, 0.88, edge * (0.5 + 0.25 * drift));
}
"""

var kind := ""
var wind := Vector2.RIGHT
var flash := 0.0
var _bits: Array = []
var _fog: ColorRect
var _t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := {"RAIN": 140, "STORM": 180, "WIND": 26, "FROST": 60}.get(kind, 0) as int
	n = int(n * Settings.effects_scale())
	for i in n:
		_bits.append(Vector3(randf(), randf(), randf()))
	if kind == "FOG":
		_fog = ColorRect.new()
		_fog.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = Shader.new()
		mat.shader.code = FOG_SHADER
		_fog.material = mat
		add_child(_fog)


func _process(delta: float) -> void:
	_t += delta
	# Under a CanvasLayer the anchors don't size a Control: follow the screen.
	size = get_viewport_rect().size
	if _fog != null:
		_fog.size = size
	if _fog != null:
		(_fog.material as ShaderMaterial).set_shader_parameter("t", _t)
	if not _bits.is_empty() or flash > 0.0:
		queue_redraw()


func _draw() -> void:
	var s := size
	var fall: float = {"RAIN": 1.6, "STORM": 2.0, "WIND": 0.08, "FROST": 0.12}.get(kind, 0.0)
	var side: float = {"RAIN": 0.15, "STORM": 0.35, "WIND": 0.5, "FROST": 0.03}.get(kind, 0.0) * wind.x
	for b: Vector3 in _bits:
		# Each bit loops over the screen at its own speed (b.z).
		var sp := 0.6 + b.z * 0.6
		var x := fposmod(b.x + _t * side * sp, 1.0) * s.x
		var y := fposmod(b.y + _t * fall * sp, 1.0) * s.y
		match kind:
			"RAIN", "STORM":
				draw_line(Vector2(x, y), Vector2(x - side * 14.0, y + 14.0), Color(0.75, 0.85, 1.0, 0.5), 1.0)
			"WIND":
				var leaf := Color("8ab04a") if b.z < 0.5 else Color("c9a24a")
				var a := _t * 3.0 + b.z * 10.0
				draw_set_transform(Vector2(x, y + sin(a) * 12.0), a, Vector2.ONE)
				draw_colored_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(0, -2), Vector2(4, 0), Vector2(0, 2)]), leaf)
				draw_set_transform(Vector2.ZERO)
			"FROST":
				draw_circle(Vector2(x + sin(_t + b.z * 9.0) * 6.0, y), 1.0 + b.z, Color(1, 1, 1, 0.7))
	if kind == "FROST":
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.75, 0.9, 1.0, 0.06))
	if kind == "STORM" or kind == "RAIN":
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.15, 0.2, 0.35, 0.10))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, flash * 2.5))
