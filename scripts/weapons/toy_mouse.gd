class_name ToyMouse
extends Node2D
## A wind-up mouse from the Mouse Toy weapon. Runs in a wobbly line and hits
## each enemy once until its pierce runs out. The robo version steers towards
## the nearest enemy and explodes on its first hit.

const OUTLINE := Color("2b1d14")
const STEER := 5.0

var enemies: EnemyManager
## The weapon that made this (for its branch effects); may be null.
var source: Weapon
var velocity := Vector2.ZERO
var damage := 10.0
var knockback := 0.4
var pierce := 1
var lifetime := 2.0
var scale_k := 1.0
var robo := false
var blast_radius := 34.0

var _hit: Dictionary = {}
var _t := randf() * TAU


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 3


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		if robo:
			_explode()
		queue_free()
		return
	_t += delta
	if robo:
		var target := enemies.nearest(position, 220.0)
		if target != null:
			var want := (target.position - position).normalized() * velocity.length()
			velocity = velocity.lerp(want, minf(STEER * delta, 1.0))
	var wobble := velocity.orthogonal().normalized() * sin(_t * 14.0) * 30.0
	position += (velocity + wobble) * delta
	for enemy in enemies.query_radius(position, 5.0 * scale_k):
		var key := enemy.get_instance_id()
		if _hit.has(key):
			continue
		_hit[key] = true
		Weapon.strike_from(source, enemy, damage, velocity, knockback)
		if robo:
			_explode()
			queue_free()
			return
		pierce -= 1
		if pierce <= 0:
			queue_free()
			return
	queue_redraw()


func _explode() -> void:
	for enemy in enemies.query_radius(position, blast_radius):
		enemy.hit(damage, enemy.position - position, 1.0)
	var ring := RingWave.new()
	ring.enemies = enemies
	ring.position = position
	ring.max_radius = blast_radius
	ring.expand_time = 0.2
	ring.damage = 0.0
	ring.knockback = 0.0
	ring.color = Color("ff8a3d")
	get_parent().add_child(ring)
	Audio.play("pop", -10.0)


func _draw() -> void:
	var facing := -1.0 if velocity.x < 0.0 else 1.0
	var base := Transform2D(0.0, Vector2(facing, 1) * scale_k, 0.0, Vector2.ZERO)
	draw_set_transform_matrix(base)
	var body := Color("b8bcc4") if robo else Color("9a9aa2")
	# Tail, body, ear, eye, nose and the wind-up key on its back.
	Blit.line(self, Vector2(-5, 1), Vector2(-9, -1 + sin(_t * 20.0)), Color("d9a0a8"), 1.0, base)
	Blit.ellipse(self, Vector2.ZERO, 5.5, 3.5, OUTLINE)
	Blit.ellipse(self, Vector2.ZERO, 4.5, 2.6, body)
	Blit.disc(self, Vector2(2, -3), 1.6, Color("d9a0a8"))
	Blit.rect(self, Rect2(3, -1, 1, 1), Color("e04646") if robo else OUTLINE)
	Blit.rect(self, Rect2(5, 0, 1, 1), Color("f08aa0"))
	var turn := sin(_t * 10.0) * 2.0
	Blit.line(self, Vector2(-1, -2.5), Vector2(-1, -5), Color("c9a24a"), 1.0, base)
	Blit.line(self, Vector2(-1 - turn, -5), Vector2(-1 + turn, -5), Color("f2c14e"), 1.5, base)
	if robo:
		Blit.disc(self, Vector2.ZERO, 7.0, Color(1.0, 0.3, 0.2, 0.15))
	draw_set_transform(Vector2.ZERO)
