class_name EnemyManager
extends Node2D
## Owns every enemy: spawning, movement, soft separation, contact damage and
## area queries for weapons. Uses a uniform spatial grid rebuilt each physics
## tick so lookups stay cheap with hundreds of enemies.
## Must stay at the world origin (enemy positions are treated as global).

signal enemy_killed(enemy_id: String, pos: Vector2, xp: float)
signal prop_broken(prop_id: String, pos: Vector2)
signal elite_killed(pos: Vector2)
signal champion_killed(affix: String, pos: Vector2)
## A fleeing enemy (the golden mouse) got away.
signal escaped(enemy_id: String, pos: Vector2)

const CELL := 24.0
const MAX_ENEMIES := 500
## Above this many enemies they stop their walk animation (see Enemy.calm).
const CALM_CROWD := 220
const MAX_RADIUS := 16.0
const SEPARATION := 6.0

var player: Player
var enemies: Array[Enemy] = []
## Sum of `cost` of all living enemies (the spawn budget in use).
var budget_used := 0.0
## Late-night scaling for newly spawned enemies, set by the spawner.
var damage_mult := 1.0
var speed_mult := 1.0
## Enemies on fire from a weapon branch.
var burning: Array[Enemy] = []
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
## Half the visible area around the cat (1280x720 at zoom 2, plus a margin).
const ON_SCREEN := Vector2(340.0, 200.0)
## Plain chasers top out at this share of the cat's base speed.
const CHASER_MAX_SPEED := 0.85

var _grid: Dictionary = {}
## Regular ranged enemies share this many shots a second (up to a small
## burst), and only so many of their shots fly at once.
const SHOTS_PER_SECOND := 1.6
const SHOT_BURST := 3.0
const MAX_REGULAR_BULLETS := 10
var _shot_budget := SHOT_BURST
var _spits: Array = []


func _enter_tree() -> void:
	add_to_group("enemy_manager")


func _ready() -> void:
	var ground := EnemyGround.new()
	ground.manager = self
	add_child(ground)
	# First child, so it is drawn under every enemy.
	move_child(ground, 0)


func spawn(id: String, pos: Vector2, hp_mult: float = 1.0) -> Enemy:
	if enemies.size() >= MAX_ENEMIES and not GameData.enemies[id].get("boss", false):
		return null
	var enemy := Enemy.new()
	enemy.setup(id, GameData.enemies[id], self)
	enemy.max_hp *= hp_mult
	enemy.hp = enemy.max_hp
	enemy.hp_mult = hp_mult
	if not enemy.persistent:
		enemy.damage *= damage_mult
		enemy.speed *= speed_mult
	if not enemy.is_boss and GameData.enemies[id].get("behavior", "chase") == "chase":
		enemy.speed = minf(enemy.speed, Player.BASE_SPEED * CHASER_MAX_SPEED)
	enemy.position = Terrain.fix_spawn(pos, player.position, enemy.radius) if player != null else pos
	pos = enemy.position
	# Something appearing where you can see it gets a moment to be seen first.
	if player != null and not enemy.is_prop and not GameData.enemies[id].get("final", false):
		var off := pos - player.position
		if absf(off.x) < ON_SCREEN.x and absf(off.y) < ON_SCREEN.y:
			enemy.spawn_in = Enemy.SPAWN_IN
	add_child(enemy)
	enemies.append(enemy)
	budget_used += enemy.cost
	return enemy


## A projectile fired by an enemy that hurts the player on contact.
func spawn_bullet(pos: Vector2, dir: Vector2, bullet_damage: float, style: String = "laser", bullet_speed: float = 90.0) -> EnemyBullet:
	var bullet := EnemyBullet.new()
	bullet.style = style
	bullet.position = pos
	bullet.velocity = dir * bullet_speed
	bullet.damage = bullet_damage
	bullet.player = player
	get_parent().add_child(bullet)
	return bullet


## A shot from a regular ranged enemy, if the shared budget allows it: a
## crowd of spitters never fills the screen with blobs nobody can dodge.
func try_spit(pos: Vector2, dir: Vector2, bullet_damage: float) -> bool:
	for i in range(_spits.size() - 1, -1, -1):
		if not is_instance_valid(_spits[i]):
			_spits.remove_at(i)
	if _shot_budget < 1.0 or _spits.size() >= MAX_REGULAR_BULLETS:
		return false
	_shot_budget -= 1.0
	_spits.append(spawn_bullet(pos, dir, bullet_damage, "spit"))
	return true


## A danger zone on the floor made by a boss: "steam" hurts while the cat
## stands in it, "strike" is marked first and hits once.
func spawn_hazard(pos: Vector2, mode: String, r: float, seconds: float, hazard_damage: float, style: String = "") -> void:
	var h := EnemyHazard.new()
	h.position = pos
	h.mode = mode
	h.radius = r
	h.lifetime = seconds
	h.damage = hazard_damage
	h.style = style
	h.player = player
	get_parent().add_child(h)


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


## Sets an enemy on fire: `per_tick` damage every half second for `seconds`.
func ignite(enemy: Enemy, per_tick: float, seconds: float) -> void:
	if enemy.burn_t <= 0.0:
		burning.append(enemy)
		enemy.burn_tick = 0.5
	enemy.burn_damage = maxf(enemy.burn_damage, per_tick)
	enemy.burn_t = maxf(enemy.burn_t, seconds)


## Burn ticks, run after the enemy loop so deaths don't disturb it.
func _tick_burning(delta: float) -> void:
	if burning.is_empty():
		return
	# Rebuilt every frame: burning enemies may die (and be freed) meanwhile.
	var still: Array[Enemy] = []
	for item: Variant in burning:
		if not is_instance_valid(item):
			continue
		var enemy := item as Enemy
		if enemy.dead:
			continue
		enemy.burn_t -= delta
		enemy.burn_tick -= delta
		if enemy.burn_tick <= 0.0:
			enemy.burn_tick = 0.5
			enemy.hit(enemy.burn_damage, Vector2.ZERO, 0.0, false)
		if enemy.dead:
			continue
		if enemy.burn_t > 0.0:
			still.append(enemy)
		else:
			enemy.burn_damage = 0.0
	burning = still


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
		# Some enemies burst into smaller ones.
		var data: Dictionary = GameData.enemies[enemy.id]
		if data.has("split_into"):
			var n := int(data.get("split_count", 2))
			for i in n:
				var child := spawn(data["split_into"], enemy.position + Vector2.from_angle(TAU * i / n) * enemy.radius, enemy.hp_mult)
				if child != null:
					child._knock = Vector2.from_angle(TAU * i / n) * 120.0
		if enemy.is_elite:
			elite_killed.emit(enemy.position)
		if enemy.champion != "":
			champion_killed.emit(enemy.champion, enemy.position)
			var c: Dictionary = GameData.champions[enemy.champion]
			if c.has("split"):
				var n := int(c["split"])
				for i in n:
					var child := spawn(enemy.id, enemy.position + Vector2.from_angle(TAU * i / n) * enemy.radius, enemy.hp_mult)
					if child != null:
						child._knock = Vector2.from_angle(TAU * i / n) * 140.0
			if c.has("bomb"):
				var bomb := ChampionBomb.new()
				bomb.position = enemy.position
				bomb.player = player
				bomb.damage = enemy.damage * float(c["bomb"])
				get_parent().add_child(bomb)
	poof.position = enemy.position
	get_parent().add_child(poof)
	# The enemy itself squashes and fades (capped, so crowds stay cheap).
	if not enemy.is_prop and DeathFx.alive < DeathFx.MAX_ALIVE * Settings.effects_scale():
		var info := Sprites.enemy(enemy.id)
		if not info.is_empty():
			var fx := DeathFx.new()
			fx.sprite = info
			fx.frame = enemy.get("_frame")
			fx.facing = signf(enemy.scale.x) if enemy.scale.x != 0.0 else 1.0
			fx.size = absf(enemy.scale.y)
			fx.tint = enemy.modulate
			fx.position = enemy.position
			get_parent().add_child(fx)
	enemy.queue_free()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_shot_budget = minf(_shot_budget + SHOTS_PER_SECOND * delta, SHOT_BURST)
	_rebuild_grid()
	Enemy.calm = enemies.size() > CALM_CROWD or Settings.effects_scale() < 1.0
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
		if Terrain.current != null:
			# Belts carry enemies at half speed, so they never get stuck on one.
			var moved := enemy.position + Terrain.flow(enemy.position) * 0.5 * delta
			var fixed := Terrain.current.resolve(moved, enemy.radius)
			if fixed != moved:
				# Pushed back by a wall or tree: slide along it towards the cat
				# instead of standing stuck against it.
				var along := (fixed - moved).orthogonal().normalized()
				if along.dot(chase - fixed) < 0.0:
					along = -along
				fixed = Terrain.current.resolve(fixed + along * enemy.speed * delta, enemy.radius)
			enemy.position = fixed
		if not arena.is_empty():
			_apply_arena(enemy)
		for c in cats:
			var reach := enemy.radius + Player.RADIUS
			if enemy.spawn_in <= 0.0 and not c.is_dead and enemy.position.distance_squared_to(c.position) < reach * reach:
				c.take_damage(enemy.damage, enemy.fatal)
	_tick_burning(delta)
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
