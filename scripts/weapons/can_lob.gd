class_name CanLob
extends Node2D
## A tin can flying in an arc; it bursts where it lands, hitting everything
## in `radius`. A cluster can throws four small ones out of the burst.

const OUTLINE := Color("2b1d14")
const BURST_TIME := 0.25

var weapon: Weapon
var from := Vector2.ZERO
var to := Vector2.ZERO
var flight := 0.55
var radius := 42.0
var damage := 18.0
var cluster := false

var _t := 0.0
var _burst := -1.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 4


func _physics_process(delta: float) -> void:
	_t += delta
	if _burst < 0.0:
		var k := minf(_t / flight, 1.0)
		position = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 60.0)
		rotation += delta * 12.0
		if k >= 1.0:
			_explode()
	else:
		_burst += delta
		if _burst >= BURST_TIME:
			queue_free()
	queue_redraw()


func _explode() -> void:
	_burst = 0.0
	position = to
	rotation = 0.0
	Audio.play("break", -10.0, 0.2)
	if not is_instance_valid(weapon):
		return
	for e in weapon.enemies.query_radius(to, radius):
		Weapon.strike_from(weapon, e, damage, e.position - to, 0.8)
	if cluster:
		for i in 4:
			var small := CanLob.new()
			small.weapon = weapon
			small.from = to
			small.to = to + Vector2.from_angle(TAU * i / 4.0 + randf() * 0.5) * radius * 1.4
			small.flight = 0.3
			small.radius = radius * 0.55
			small.damage = damage * 0.5
			get_parent().add_child.call_deferred(small)


func _draw() -> void:
	if _burst < 0.0:
		var s := 0.6 if radius < 30.0 else 1.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
		Blit.rect(self, Rect2(-5, -6, 10, 12), OUTLINE)
		Blit.rect(self, Rect2(-4, -5, 8, 10), Color("c9ced2"))
		Blit.rect(self, Rect2(-4, -2, 8, 4), Color("d9534f"))
		draw_set_transform(Vector2.ZERO)
		return
	var k := _burst / BURST_TIME
	Blit.disc(self, Vector2.ZERO, radius * (0.4 + 0.6 * k), Color(1.0, 0.65, 0.25, 0.45 * (1.0 - k)))
	Blit.ring(self, Vector2.ZERO, radius * (0.4 + 0.6 * k) + 1.0, 2.0, Color(1.0, 0.9, 0.6, 1.0 - k))
	for i in 6:
		var d := Vector2.from_angle(TAU * i / 6.0 + 0.3)
		Blit.line(self, d * radius * 0.3 * k, d * radius * (0.5 + 0.5 * k), Color(1.0, 0.95, 0.7, 1.0 - k), 1.5)
