class_name DamageNumbers
extends Node2D
## Floating damage numbers, all drawn by this one node (hundreds of hits a
## second would be far too many separate nodes). Crits are bigger, yellow
## and get a "!". Can be switched off in the pause menu.

const LIFETIME := 0.6
const MAX_NUMBERS := 140
const OUTLINE := Color("2b1d14")
const NORMAL := Color(1, 1, 1)
const CRIT := Color("ffd23f")

## [position, value, crit, age, drift]
var _numbers: Array = []
var _font: Font


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 20


func _ready() -> void:
	_font = ThemeDB.fallback_font


func add(pos: Vector2, value: float, crit: bool) -> void:
	if not Settings.damage_numbers or value < 0.5:
		return
	while _numbers.size() >= MAX_NUMBERS * Settings.effects_scale():
		_numbers.pop_front()
	_numbers.append([pos + Vector2(randf_range(-4, 4), -8), value, crit, 0.0, randf_range(-12, 12)])


func _process(delta: float) -> void:
	if _numbers.is_empty():
		return
	for n: Array in _numbers:
		n[3] += delta
	while not _numbers.is_empty() and _numbers[0][3] >= LIFETIME:
		_numbers.pop_front()
	queue_redraw()


func _draw() -> void:
	for n: Array in _numbers:
		var k: float = n[3] / LIFETIME
		var crit: bool = n[2]
		var text := str(roundi(n[1])) + ("!" if crit else "")
		var size := 13 if crit else 9
		# Pop in, float up, fade out.
		var pop := 1.0 + maxf(0.0, 0.25 - k) * (3.0 if crit else 1.5)
		var pos: Vector2 = n[0] + Vector2(n[4] * k, -18.0 * k)
		var color := CRIT if crit else NORMAL
		# Plain hits stay a bit see-through so they don't hide the enemies.
		color.a = clampf((1.0 - k) * 2.0, 0.0, 1.0 if crit else 0.7)
		# Two fixed font sizes, popped by scaling: a new size every frame
		# would make the font render its glyphs again and again (slow).
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_set_transform(pos, 0.0, Vector2(pop, pop))
		var at := Vector2(-w * 0.5, 0)
		draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(OUTLINE, color.a))
		draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	draw_set_transform(Vector2.ZERO)
