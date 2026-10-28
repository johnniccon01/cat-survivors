class_name Pickup
extends Node2D
## A collectible lying on the floor. Movement and collection are handled by
## Pickups.

enum Kind { XP, HEART, SARDINE, MAGNET, CHEST, COIN, CHARM, PAGE }

const OUTLINE := Color("2b1d14")
## A chest just appears where the enemy fell; a boss chest shines in a
## pillar of light. The show is when it opens (TreasurePanel).

var kind := Kind.XP
var value := 1.0
var attracted := false
var speed := 0.0
## Which charm this is (Kind.CHARM only).
var charm_id := ""

var _bob := randf() * TAU
## Seconds since it appeared (boss chests: the flash and the light).
var _age := 0.0


## Above puddles and other ground effects (-2); a chest even above the
## cats and weapon effects, so it is never lost.
func _init() -> void:
	z_index = -1


func _ready() -> void:
	if kind == Kind.CHEST:
		z_index = 6
	# Kibble lies still; only the special pickups bob (saves hundreds of
	# _process calls a frame on a full floor).
	set_process(kind != Kind.XP)


## Re-tint after merged XP made the kibble more valuable.
func refresh() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	# Only the special pickups bob, so they stand out from the kibble.
	if kind != Kind.XP:
		_bob += delta * 4.0
		if kind == Kind.CHEST and _age == 0.0:
			Audio.play("chest_boss" if value >= 1.0 else "chest_land", -3.0, 0.0)
		_age += delta
		queue_redraw()


## A chest just appears (the show is when it opens), so it can be opened at once.
func landed() -> bool:
	return true


func _draw() -> void:
	match kind:
		Kind.HEART:
			_draw_heart()
		Kind.SARDINE:
			_draw_sardine()
		Kind.MAGNET:
			_draw_magnet()
		Kind.CHEST:
			_draw_chest()
		Kind.COIN:
			_draw_coin()
		Kind.CHARM:
			_draw_charm()
		Kind.PAGE:
			_draw_page()
		_:
			_draw_kibble()


## A torn page of the old cat's diary, glowing so it can be spotted.
func _draw_page() -> void:
	_shadow_and_lift()
	for i in 3:
		Blit.disc(self, Vector2(0, -2), 10.0 + i * 5.0, Color(1.0, 0.95, 0.7, 0.07))
	var page := PackedVector2Array([Vector2(-5, -8), Vector2(5, -7), Vector2(6, 5), Vector2(1, 4), Vector2(-4, 6)])
	draw_colored_polygon(page, Color("efe2c0"))
	draw_polyline(Shapes.closed(page), OUTLINE, 1.0)
	for y: float in [-4.0, -1.0, 2.0]:
		draw_line(Vector2(-3, y), Vector2(3, y + 0.5), Color("8a6a4a"), 1.0)


const CHARM_GLOW := {"common": Color("d8e4ee"), "rare": Color("5aa9ff"), "epic": Color("c77dff")}


## A charm: a gem in a gold frame on a little chain, in a soft halo of its
## rarity's color with slow turning rays, so it never looks like kibble.
func _draw_charm() -> void:
	var data: Dictionary = GameData.charms[charm_id]
	var glow: Color = CHARM_GLOW.get(data.get("rarity", "common"), Color.WHITE)
	var pulse := 0.7 + 0.3 * sin(_bob * 1.2)
	Blit.disc(self, Vector2(0, -2), 15.0, Color(glow, 0.14 * pulse))
	Blit.disc(self, Vector2(0, -2), 9.0, Color(glow, 0.2 * pulse))
	for i in 6:
		var a := _bob * 0.2 + TAU * i / 6.0
		var tip := Vector2.from_angle(a) * 20.0
		draw_colored_polygon(PackedVector2Array([Vector2(0, -2), Vector2(0, -2) + tip.rotated(0.1), Vector2(0, -2) + tip.rotated(-0.1)]), Color(glow, 0.16 * pulse))
	Blit.ellipse(self, Vector2(0, 8), 6, 1.5, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(_bob) * 2.0))
	var c := Color(data["color"])
	# The chain loop on top.
	draw_arc(Vector2(0, -9), 3.5, PI, TAU, 10, OUTLINE, 2.5)
	draw_arc(Vector2(0, -9), 3.5, PI, TAU, 10, Color("f2c14e"), 1.2)
	# Gold frame, then the gem.
	var frame := PackedVector2Array([Vector2(0, -9), Vector2(7, -1), Vector2(0, 8), Vector2(-7, -1)])
	var gem := PackedVector2Array([Vector2(0, -6), Vector2(4.5, -1), Vector2(0, 5), Vector2(-4.5, -1)])
	draw_colored_polygon(frame, Color("f2c14e"))
	draw_polyline(Shapes.closed(frame), OUTLINE, 1.0)
	draw_colored_polygon(gem, c)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(4.5, -1), Vector2(0, -1)]), c.lightened(0.35))
	draw_polyline(Shapes.closed(gem), OUTLINE, 1.0)
	draw_rect(Rect2(-2, -4, 1, 2), Color(1, 1, 1, 0.95))
	var a := 0.5 + 0.5 * sin(_bob * 2.0)
	for p: Vector2 in [Vector2(9, -10), Vector2(-9, 2)]:
		draw_line(p + Vector2(0, -2.5), p + Vector2(0, 2.5), Color(1, 1, 0.85, a), 1.0)
		draw_line(p + Vector2(-2.5, 0), p + Vector2(2.5, 0), Color(1, 1, 0.85, a), 1.0)


## A soft colored halo under heart, sardine and magnet pickups, so they
## stand out from the kibble on a full floor.
func _halo(color: Color) -> void:
	Blit.disc(self, Vector2(0, -1), 11.0, Color(color, 0.12 + 0.06 * sin(_bob * 1.5)))


func _draw_coin() -> void:
	var r := 3.5 if value < 10.0 else 5.0
	Blit.disc(self, Vector2.ZERO, r + 1.0, OUTLINE)
	Blit.disc(self, Vector2.ZERO, r, Color("f2c14e"))
	Blit.disc(self, Vector2.ZERO, r * 0.55, Color("d9a23a"))
	Blit.rect(self, Rect2(-r * 0.5, -r * 0.6, 1, 1), Color(1, 1, 1, 0.9))


func _draw_kibble() -> void:
	var color := Color("5aa9e6")
	var size := 3.0
	if value >= 10.0:
		color = Color("e05a5a")
		size = 4.5
	elif value >= 3.0:
		color = Color("6cc46c")
		size = 3.5
	# A diamond: a turned square, drawn so that hundreds of kibbles merge
	# into a single draw call.
	var side := size * sqrt(2.0)
	draw_set_transform(Vector2.ZERO, PI * 0.25)
	Blit.rect(self, Rect2(-side * 0.5 - 0.5, -side * 0.5 - 0.5, side + 1.0, side + 1.0), OUTLINE)
	Blit.rect(self, Rect2(-side * 0.5 + 0.5, -side * 0.5 + 0.5, side - 1.0, side - 1.0), color)
	draw_set_transform(Vector2.ZERO)
	Blit.rect(self, Rect2(-1, -size + 1, 1, 1), Color(1, 1, 1, 0.8))


func _shadow_and_lift() -> void:
	Blit.ellipse(self, Vector2(0, 6), 5, 1.5, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2(0, sin(_bob) * 1.5))


func _draw_heart() -> void:
	_halo(Color("ff6060"))
	_shadow_and_lift()
	var pts := PackedVector2Array([
		Vector2(0, 5), Vector2(-5, 0), Vector2(-5, -2), Vector2(-3, -4),
		Vector2(-1, -4), Vector2(0, -2), Vector2(1, -4), Vector2(3, -4),
		Vector2(5, -2), Vector2(5, 0),
	])
	draw_colored_polygon(pts, Color("e04646"))
	draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	draw_rect(Rect2(-3, -3, 1, 1), Color(1, 1, 1, 0.9))


func _draw_sardine() -> void:
	_halo(Color("9fd8ff"))
	_shadow_and_lift()
	var body := Shapes.ellipse(Vector2.ZERO, 6, 3)
	var tail := PackedVector2Array([Vector2(-5, 0), Vector2(-9, -3), Vector2(-9, 3)])
	draw_colored_polygon(tail, Color("8fa9b8"))
	draw_colored_polygon(body, Color("b8cfdc"))
	draw_polyline(Shapes.closed(body), OUTLINE, 1.0)
	draw_polyline(Shapes.closed(tail), OUTLINE, 1.0)
	draw_rect(Rect2(3, -1, 1, 1), OUTLINE)


func _draw_magnet() -> void:
	_halo(Color("ff7070"))
	_shadow_and_lift()
	draw_arc(Vector2(0, -1), 4.0, PI, TAU, 10, OUTLINE, 5.0)
	draw_arc(Vector2(0, -1), 4.0, PI, TAU, 10, Color("d94848"), 3.0)
	draw_rect(Rect2(-5.5, -1, 3, 4), OUTLINE)
	draw_rect(Rect2(2.5, -1, 3, 4), OUTLINE)
	draw_rect(Rect2(-5, 0, 2, 2), Color("dddddd"))
	draw_rect(Rect2(3, 0, 2, 2), Color("dddddd"))


func _draw_chest() -> void:
	# A great chest (strong bosses) is bigger and purple.
	var great := value >= 2.0
	var boss := value >= 1.0
	var size := 1.4 if great else 1.0
	if boss:
		_draw_chest_light(_age, great)
	Blit.ellipse(self, Vector2(0, 7), 9, 2, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(_bob) * 1.0), 0.0, Vector2.ONE * size)
	draw_rect(Rect2(-8, -4, 16, 10), Color("5b3a8a") if great else Color("8a5a2b"))
	draw_rect(Rect2(-8, -8, 16, 5), Color("7d52b8") if great else Color("a8703a"))
	draw_rect(Rect2(-8, -8, 16, 14), OUTLINE, false, 1.0)
	draw_line(Vector2(-8, -3), Vector2(8, -3), OUTLINE, 1.0)
	draw_rect(Rect2(-8, -8, 2, 14), Color("f2c14e"))
	draw_rect(Rect2(6, -8, 2, 14), Color("f2c14e"))
	draw_rect(Rect2(-1.5, -4, 3, 3), Color("f2c14e"))
	# Sparkle
	var a := 0.5 + 0.5 * sin(_bob * 1.7)
	draw_line(Vector2(9, -11), Vector2(9, -7), Color(1, 1, 0.8, a), 1.0)
	draw_line(Vector2(7, -9), Vector2(11, -9), Color(1, 1, 0.8, a), 1.0)


## A boss chest: a pillar of light, slow turning rays and sparkles rising,
## with a bright flash the moment it lands.
func _draw_chest_light(since: float, great: bool) -> void:
	var glow := Color("c77dff") if great else Color("f2c14e")
	var pulse := 0.75 + 0.25 * sin(_bob * 1.3)
	if since < 0.6:
		var f := since / 0.6
		Blit.ring(self, Vector2.ZERO, 10.0 + 70.0 * f, 3.0, Color(1, 1, 0.85, 0.8 * (1.0 - f)))
		Blit.disc(self, Vector2.ZERO, 30.0 * (1.0 - f), Color(1, 1, 0.9, 0.5 * (1.0 - f)))
	for i in 3:
		var w := 14.0 - i * 4.0
		draw_rect(Rect2(-w * 0.5, -140.0, w, 140.0), Color(glow, 0.07 * pulse * (i + 1)))
	var rays := 10 if great else 8
	for i in rays:
		var a := _bob * 0.15 + TAU * i / rays
		var tip := Vector2.from_angle(a) * (30.0 if great else 24.0)
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, tip.rotated(0.12), tip.rotated(-0.12)]), Color(glow, 0.22 * pulse))
	Blit.disc(self, Vector2(0, -2), 14.0, Color(glow, 0.18 * pulse))
	for i in 5:
		var rise := fmod(_age * 0.5 + i * 0.2, 1.0)
		var x := sin(i * 2.3 + _age) * 9.0
		Blit.disc(self, Vector2(x, -8.0 - rise * 70.0), 1.5, Color(1, 1, 0.8, 1.0 - rise))
