class_name Pickups
extends Node2D
## Owns every pickup on the floor. Pickups inside the cat's magnet radius
## hop back a little, then fly into the cat with growing speed.
## Must stay at the world origin.

## value >= 1: a boss chest (pick one of three).
signal chest_collected(value: float)
signal gold_collected(amount: float)
signal charm_collected(charm_id: String)
signal heart_collected
signal page_collected

const MAX_XP := 300
## How many kibbles are looked at to find a far one to merge (see spawn_xp).
const FAR_SAMPLES := 32
## Chests are not pulled by the magnet; the cat has to walk over them.
const CHEST_DIST := 12.0
const COLLECT_DIST := 8.0
const ACCEL := 700.0
const HOP_SPEED := -90.0

var player: Player
var items: Array[Pickup] = []
## XP collected this run (for testing).
var total_xp := 0.0

var _xp_count := 0


func spawn_xp(pos: Vector2, value: float) -> void:
	# Too many kibbles on the floor: remove one far from the cat and
	# carry its XP over into the new kibble, so XP is never stranded far away.
	if _xp_count >= MAX_XP and player != null:
		var far_i := -1
		var far_d2 := -1.0
		# The furthest of a random handful: scanning all of them for every
		# kill made big multi-kills slow on a full floor.
		for k in mini(items.size(), FAR_SAMPLES):
			var i := randi() % items.size()
			var other := items[i]
			if other.kind != Pickup.Kind.XP or other.attracted:
				continue
			var d2 := other.position.distance_squared_to(player.position)
			if d2 > far_d2:
				far_d2 = d2
				far_i = i
		if far_i >= 0:
			value += items[far_i].value
			items[far_i].queue_free()
			items.remove_at(far_i)
			_xp_count -= 1
	_xp_count += 1
	_spawn(Pickup.Kind.XP, pos, value)


## Places the map's diary page; returns it so the HUD can point at it.
func spawn_page(pos: Vector2) -> Pickup:
	_spawn(Pickup.Kind.PAGE, pos, 0.0)
	return items[-1]


## Drops a specific charm.
func spawn_charm(pos: Vector2, charm_id: String) -> void:
	_spawn(Pickup.Kind.CHARM, pos, 0.0)
	items[-1].charm_id = charm_id


## Spawns a pickup by its loot-table name: xp, heart, sardine or magnet.
func spawn_named(kind_name: String, pos: Vector2, value: float) -> void:
	match kind_name:
		"xp":
			spawn_xp(pos, value)
		"heart":
			_spawn(Pickup.Kind.HEART, pos, value)
		"sardine":
			_spawn(Pickup.Kind.SARDINE, pos, value)
		"magnet":
			_spawn(Pickup.Kind.MAGNET, pos, value)
		"chest":
			_spawn(Pickup.Kind.CHEST, pos, value)
		"coin":
			_spawn(Pickup.Kind.COIN, pos, value)
		_:
			push_warning("Pickups: unknown kind %s" % kind_name)


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
		if item.kind == Pickup.Kind.CHEST:
			if dist <= CHEST_DIST:
				_collect(item)
				items.remove_at(i)
			continue
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


## Pulls every kibble on the map towards the cat (magnet pickup, magnet core).
func pull_all_xp() -> void:
	Audio.play("magnet", -4.0, 0.0)
	for other in items:
		if other.kind == Pickup.Kind.XP and not other.attracted:
			other.attracted = true
			other.speed = 0.0


func _collect(item: Pickup) -> void:
	match item.kind:
		Pickup.Kind.XP:
			_xp_count -= 1
			total_xp += item.value
			Audio.play("xp", -16.0, 0.12)
			player.add_xp(item.value)
		Pickup.Kind.HEART, Pickup.Kind.SARDINE:
			Audio.play("heal", -4.0)
			player.heal(item.value * player.stat("heal_power"))
			heart_collected.emit()
		Pickup.Kind.MAGNET:
			pull_all_xp()
		Pickup.Kind.CHEST:
			chest_collected.emit(item.value)
		Pickup.Kind.COIN:
			Audio.play("coin", -9.0, 0.08)
			gold_collected.emit(item.value)
		Pickup.Kind.CHARM:
			Audio.play("chest", -4.0, 0.0)
			charm_collected.emit(item.charm_id)
		Pickup.Kind.PAGE:
			Audio.play("quest_done", -2.0, 0.0)
			page_collected.emit()
	item.queue_free()
