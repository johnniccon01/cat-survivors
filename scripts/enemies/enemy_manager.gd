class_name EnemyManager
extends Node2D
## Owns every enemy: spawning, movement, soft separation, contact damage and
## area queries for weapons. Uses a uniform spatial grid rebuilt each physics
## tick so lookups stay cheap with hundreds of enemies.
## Must stay at the world origin (enemy positions are treated as global).

signal enemy_killed(enemy_id: String, pos: Vector2, xp: float)
signal prop_broken(prop_id: String, pos: Vector2)
signal elite_killed(pos: Vector2)

const CELL := 24.0
const MAX_ENEMIES := 500
const MAX_RADIUS := 16.0
const SEPARATION := 6.0

var player: Player
var enemies: Array[Enemy] = []
## Sum of `cost` of all living enemies (the spawn budget in use).
var budget_used := 0.0
## Late-night scaling for newly spawned enemies, set by the spawner.
var damage_mult := 1.0
var speed_mult := 1.0
## Floating damage numbers (set by main).
var numbers: DamageNumbers
## Breakable boxes and plants: static, hit by weapons, ignored by targeting.
var props: Array[Enemy] = []
## Cats being escorted: enemies go for whichever cat is closest.
var escorts: Array[Player] = []
## Duel arena {center, radius, rival}: the rival is kept inside it and every
## other enemy is kept outside. Empty when there is no duel.
var arena: Dictionary = {}
## Enemies further than this from the player get moved back in front of them.
var relocate_distance := 600.0
var spawn_radius := 400.0

var _grid: Dictionary = {}


func _enter_tree() -> void:
	add_to_group("enemy_manager")


func spawn(id: String, pos: Vector2, hp_mult: float = 1.0) -> Enemy:
	if enemies.size() >= MAX_ENEMIES and not GameData.enemies[id].get("boss", false):
		return null
	var enemy := Enemy.new()
	enemy.setup(id, GameData.enemies[id], self)
	enemy.max_hp *= hp_mult
	enemy.hp = enemy.max_hp
	if not enemy.persistent:
		enemy.damage *= damage_mult
		enemy.speed *= speed_mult
	enemy.position = pos
	add_child(enemy)
	enemies.append(enemy)
	budget_used += enemy.cost
	return enemy


## A projectile fired by an enemy that hurts the player on contact.
func spawn_bullet(pos: Vector2, dir: Vector2, bullet_damage: float, style: String = "laser") -> void:
	var bullet := EnemyBullet.new()
	bullet.style = style
	bullet.position = pos
	bullet.velocity = dir * 90.0
	bullet.damage = bullet_damage
	bullet.player = player
	get_parent().add_child(bullet)


## Silently removes one enemy (no XP, no effect), e.g. a swarm that ran off.
func despawn(enemy: Enemy) -> void:
	enemy.dead = true
	enemies.erase(enemy)
	budget_used -= enemy.cost
	enemy.queue_free()


## Removes every enemy with a puff of smoke (no XP), e.g. before the final boss.
func clear_all() -> void:
	var kept: Array[Enemy] = []
	for enemy in enemies:
		if enemy.persistent:
			kept.append(enemy)
			continue
		var poof := Poof.new()
		poof.position = enemy.position
		get_parent().add_child(poof)
		enemy.queue_free()
	enemies = kept
	budget_used = 0.0


func spawn_prop(id: String, pos: Vector2) -> Enemy:
	var prop := Enemy.new()
	prop.setup(id, GameData.props[id], self)
	prop.is_prop = true
	prop.position = pos
	add_child(prop)
	props.append(prop)
	return prop


func on_enemy_dead(enemy: Enemy) -> void:
	var poof := Poof.new()
	poof.color = enemy.tint()
	Audio.play("break" if enemy.is_prop else "pop", -8.0, 0.12)
	if enemy.is_prop:
		props.erase(enemy)
		prop_broken.emit(enemy.id, enemy.position)
		poof.color = Color("c8955a")
	else:
		enemies.erase(enemy)
		budget_used -= enemy.cost
		enemy_killed.emit(enemy.id, enemy.position, enemy.xp)
		if enemy.is_elite:
			elite_killed.emit(enemy.position)
	poof.position = enemy.position
	get_parent().add_child(poof)
	enemy.queue_free()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_rebuild_grid()
	var target := player.position
	escorts = escorts.filter(func(c: Player) -> bool: return is_instance_valid(c))
	var cats: Array[Player] = [player]
	for c in escorts:
		if not c.is_dead:
			cats.append(c)
	for enemy in enemies:
		var offset := enemy.position - target
		if offset.length_squared() > relocate_distance * relocate_distance and not enemy.is_charging():
			enemy.position = target - offset.normalized() * spawn_radius
		var chase := target
		if cats.size() > 1:
			for c in cats:
				if c.position.distance_squared_to(enemy.position) < chase.distance_squared_to(enemy.position):
					chase = c.position
		enemy.tick(delta, chase, _separation(enemy) * SEPARATION)
		if not arena.is_empty():
			_apply_arena(enemy)
		for c in cats:
			var reach := enemy.radius + Player.RADIUS
			if not c.is_dead and enemy.position.distance_squared_to(c.position) < reach * reach:
				c.take_damage(enemy.damage, enemy.fatal)
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].wants_despawn:
			despawn(enemies[i])
	for i in range(props.size() - 1, -1, -1):
		if props[i].position.distance_squared_to(target) > relocate_distance * relocate_distance * 2.0:
			props[i].queue_free()
			props.remove_at(i)


func _apply_arena(enemy: Enemy) -> void:
	var center: Vector2 = arena["center"]
	var r: float = arena["radius"]
	var off := enemy.position - center
	if enemy == arena.get("rival"):
		if off.length() > r - enemy.radius:
			enemy.position = center + off.normalized() * (r - enemy.radius)
	elif off.length() < r + enemy.radius:
		enemy.position = center + off.normalized() * (r + enemy.radius)


func nearest(pos: Vector2, max_dist: float = INF) -> Enemy:
	var best: Enemy = null
	var best_d2 := max_dist * max_dist
	for enemy in enemies:
		var d2 := enemy.position.distance_squared_to(pos)
		if d2 < best_d2:
			best_d2 = d2
			best = enemy
	return best


func query_rect(rect: Rect2) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var c0 := _cell(rect.position - Vector2(MAX_RADIUS, MAX_RADIUS))
	var c1 := _cell(rect.end + Vector2(MAX_RADIUS, MAX_RADIUS))
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var bucket: Variant = _grid.get(Vector2i(cx, cy))
			if bucket == null:
				continue
			# The grid is rebuilt each physics frame, so while the game is paused
			# it can still list enemies that died and were freed since.
			for item: Variant in bucket:
				if not is_instance_valid(item):
					continue
				var enemy := item as Enemy
				if enemy.dead:
					continue
				var closest := enemy.position.clamp(rect.position, rect.end)
				if closest.distance_squared_to(enemy.position) <= enemy.radius * enemy.radius:
					result.append(enemy)
	return result


func query_radius(center: Vector2, r: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy in query_rect(Rect2(center - Vector2(r, r), Vector2(r, r) * 2.0)):
		var reach := r + enemy.radius
		if enemy.position.distance_squared_to(center) <= reach * reach:
			result.append(enemy)
	return result


## Enemies touching the segment a-b thickened by `width` on each side.
func query_segment(a: Vector2, b: Vector2, width: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var bounds := Rect2(a, Vector2.ZERO).expand(b).grow(width)
	for enemy in query_rect(bounds):
		var closest := Geometry2D.get_closest_point_to_segment(enemy.position, a, b)
		var reach := width + enemy.radius
		if closest.distance_squared_to(enemy.position) <= reach * reach:
			result.append(enemy)
	return result


func _cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL), floori(pos.y / CELL))


func _rebuild_grid() -> void:
	_grid.clear()
	for enemy in enemies + props:
		var c := _cell(enemy.position)
		if not _grid.has(c):
			_grid[c] = []
		_grid[c].append(enemy)


func _separation(enemy: Enemy) -> Vector2:
	var c := _cell(enemy.position)
	var push := Vector2.ZERO
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var bucket: Variant = _grid.get(c + Vector2i(dx, dy))
			if bucket == null:
				continue
			for other: Enemy in bucket:
				if other == enemy:
					continue
				var d := enemy.position - other.position
				var min_d := enemy.radius + other.radius
				var dist2 := d.length_squared()
				if dist2 < min_d * min_d and dist2 > 0.0001:
					var dist := sqrt(dist2)
					push += d / dist * (min_d - dist)
	return push
