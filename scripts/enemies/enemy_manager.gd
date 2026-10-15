class_name EnemyManager
extends Node2D
## Owns every enemy: spawning, movement, soft separation, contact damage and
## area queries for weapons. Uses a uniform spatial grid rebuilt each physics
## tick so lookups stay cheap with hundreds of enemies.
## Must stay at the world origin (enemy positions are treated as global).

signal enemy_killed(enemy_id: String, pos: Vector2, xp: float)

const CELL := 24.0
const MAX_ENEMIES := 500
const MAX_RADIUS := 16.0
const SEPARATION := 6.0

var player: Player
var enemies: Array[Enemy] = []
## Enemies further than this from the player get moved back in front of them.
var relocate_distance := 600.0
var spawn_radius := 400.0

var _grid: Dictionary = {}


func _enter_tree() -> void:
	add_to_group("enemy_manager")


func spawn(id: String, pos: Vector2) -> Enemy:
	if enemies.size() >= MAX_ENEMIES:
		return null
	var enemy := Enemy.new()
	enemy.setup(id, GameData.enemies[id], self)
	enemy.position = pos
	add_child(enemy)
	enemies.append(enemy)
	return enemy


func on_enemy_dead(enemy: Enemy) -> void:
	enemies.erase(enemy)
	enemy_killed.emit(enemy.id, enemy.position, enemy.xp)
	var poof := Poof.new()
	poof.position = enemy.position
	get_parent().add_child(poof)
	enemy.queue_free()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_rebuild_grid()
	var target := player.position
	for enemy in enemies:
		var offset := enemy.position - target
		if offset.length_squared() > relocate_distance * relocate_distance:
			enemy.position = target - offset.normalized() * spawn_radius
		enemy.tick(delta, target, _separation(enemy) * SEPARATION)
		var reach := enemy.radius + Player.RADIUS
		if not player.is_dead and enemy.position.distance_squared_to(target) < reach * reach:
			player.take_damage(enemy.damage)


func query_rect(rect: Rect2) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var c0 := _cell(rect.position - Vector2(MAX_RADIUS, MAX_RADIUS))
	var c1 := _cell(rect.end + Vector2(MAX_RADIUS, MAX_RADIUS))
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var bucket: Variant = _grid.get(Vector2i(cx, cy))
			if bucket == null:
				continue
			for enemy: Enemy in bucket:
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


func _cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL), floori(pos.y / CELL))


func _rebuild_grid() -> void:
	_grid.clear()
	for enemy in enemies:
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
