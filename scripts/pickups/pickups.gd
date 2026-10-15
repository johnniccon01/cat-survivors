class_name Pickups
extends Node2D
## Owns every pickup on the floor. Pickups inside the cat's magnet radius
## hop back a little, then fly into the cat with growing speed.
## Must stay at the world origin.

const MAX_XP := 300
const COLLECT_DIST := 8.0
const ACCEL := 700.0
const HOP_SPEED := -90.0

var player: Player
var items: Array[Pickup] = []

var _xp_count := 0


func spawn_xp(pos: Vector2, value: float) -> void:
	# Too many kibbles on the floor: fold the XP into an existing one instead.
	if _xp_count >= MAX_XP:
		for i in 8:
			var other: Pickup = items.pick_random()
			if other.kind == Pickup.Kind.XP:
				other.value += value
				other.refresh()
				return
	_xp_count += 1
	_spawn(Pickup.Kind.XP, pos, value)


func spawn_heal(pos: Vector2, value: float) -> void:
	_spawn(Pickup.Kind.HEAL, pos, value)


func _spawn(kind: Pickup.Kind, pos: Vector2, value: float) -> void:
	var item := Pickup.new()
	item.kind = kind
	item.value = value
	item.position = pos
	add_child(item)
	items.append(item)


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	var target := player.position
	var magnet := player.stat("magnet")
	for i in range(items.size() - 1, -1, -1):
		var item := items[i]
		var to := target - item.position
		var dist := to.length()
		if not item.attracted:
			if dist > magnet:
				continue
			item.attracted = true
			item.speed = HOP_SPEED
		item.speed += ACCEL * delta
		item.position += to / maxf(dist, 0.001) * minf(item.speed * delta, dist)
		if dist <= COLLECT_DIST:
			_collect(item)
			items.remove_at(i)


func _collect(item: Pickup) -> void:
	match item.kind:
		Pickup.Kind.XP:
			_xp_count -= 1
			player.add_xp(item.value)
		Pickup.Kind.HEAL:
			player.heal(item.value)
	item.queue_free()
