class_name Weapon
extends Node
## Base for all weapons. Stats come from data/weapons.json: level 1 holds the
## base values and every further level only lists increments, which are summed
## up to the current level (same scheme as Vampire Survivors).
##
## Every `interval` seconds the weapon fires a burst of `amount` shots spaced
## `repeat_interval` apart; subclasses implement shoot().

var id := ""
var data: Dictionary
var player: Player
var enemies: EnemyManager
var world: Node2D
var level := 1
var stats: Dictionary = {}
## Chosen upgrade branch (data/branches.json) and its rank (1 or 2); kept
## through evolution.
var branch := ""
var branch_rank := 0

var _cooldown := 0.3
var _burst_index := 0
var _burst_count := 0
var _burst_timer := 0.0


func setup(p_id: String, p_data: Dictionary, p_player: Player) -> void:
	id = p_id
	data = p_data
	player = p_player
	_recalc()


func _ready() -> void:
	enemies = get_tree().get_first_node_in_group("enemy_manager")
	world = player.get_parent()


func max_level() -> int:
	return data["levels"].size()


func level_up() -> void:
	if level < max_level():
		level += 1
		_recalc()


func stat(stat_name: String, default: float = 0.0) -> float:
	var value := float(stats.get(stat_name, default))
	var mods: Dictionary = branch_effect().get("mods", {})
	if mods.has(stat_name):
		# Counts add up, everything else is a percentage.
		if stat_name in ["amount", "pierce"]:
			value += float(mods[stat_name])
		else:
			value *= 1.0 + float(mods[stat_name])
	return value


## The base weapon whose branches apply (evolutions use their base's).
func base_id() -> String:
	return Icons.base_weapon(id)


## The current rank's effect of the chosen branch, or {}.
func branch_effect() -> Dictionary:
	if branch == "":
		return {}
	var ranks: Array = GameData.branches.get(base_id(), {}).get(branch, {}).get("ranks", [])
	return ranks[branch_rank - 1] if branch_rank >= 1 and branch_rank <= ranks.size() else {}


## Weapons whose hits leave enemies wet (evolutions count as their base).
const WET_SOURCES := ["SPRINKLER", "WAVE", "MILK"]
const WET_SECONDS := 3.0
## Lightning on a wet enemy: this much harder, and it jumps to one more.
const CONDUCT_BONUS := 0.3
const CONDUCT_JUMP := 0.5
const CONDUCT_RANGE := 90.0


## Hits an enemy with this weapon, then applies the branch's on-hit effect.
func strike(enemy: Enemy, amount_hit: float, dir: Vector2, knockback: float) -> void:
	if not enemy.dead and not enemy.is_prop:
		HitFx.spawn(world, enemy.position, id)
	var base := base_id()
	var conduct := base == "ANTENNA" and not enemy.is_prop and enemy.is_wet()
	if conduct:
		amount_hit *= 1.0 + CONDUCT_BONUS
	enemy.hit(amount_hit, dir, knockback)
	if base in WET_SOURCES and not enemy.dead and not enemy.is_prop:
		enemy.make_wet(WET_SECONDS)
	if conduct:
		_conduct(enemy, amount_hit)
	var fx := branch_effect()
	if fx.is_empty() or enemy == null:
		return
	if fx.has("execute") and not enemy.dead and not enemy.is_boss and enemy.hp < enemy.max_hp * float(fx["execute"]):
		enemy.hit(enemy.hp + 1.0, dir, 0.0, false)
	if enemy.dead:
		if fx.has("vamp") and randf() < float(fx["vamp"]):
			player.heal(2.0)
		return
	if fx.has("burn"):
		enemies.ignite(enemy, amount_hit * float(fx["burn"][0]), float(fx["burn"][1]))
	if fx.has("chill"):
		enemy.slow_down(float(fx["chill"][0]), float(fx["chill"][1]))
		enemy.chill(float(fx["chill"][1]))
	if fx.has("shock") and randf() < float(fx["shock"][0]):
		var other := _nearest_other(enemy, 80.0)
		if other != null:
			other.hit(amount_hit * float(fx["shock"][1]), other.position - enemy.position, 0.2, false)
			Audio.play("zap", -16.0)
			var bolt := ChainBolt.new()
			bolt.points = PackedVector2Array([enemy.position, other.position])
			world.add_child(bolt)
	if fx.has("blast") and randf() < float(fx["blast"][0]):
		var r := float(fx["blast"][2]) * area()
		var at := enemy.position
		for e in enemies.query_radius(at, r):
			if e != enemy:
				e.hit(amount_hit * float(fx["blast"][1]), e.position - at, 0.5, false)
		var ring := RingWave.new()
		ring.enemies = enemies
		ring.position = at
		ring.max_radius = r
		ring.expand_time = 0.18
		ring.damage = 0.0
		ring.knockback = 0.0
		ring.color = Color("ff8a3d")
		world.add_child(ring)


## For effect nodes that remember which weapon made them.
## (`source` is untyped: after an evolution the old weapon is freed while its
## projectiles are still flying.)
static func strike_from(source: Variant, enemy: Enemy, amount_hit: float, dir: Vector2, knockback: float) -> void:
	if is_instance_valid(source):
		(source as Weapon).strike(enemy, amount_hit, dir, knockback)
	else:
		enemy.hit(amount_hit, dir, knockback)


## Water carries the spark on to the nearest other wet enemy.
func _conduct(from: Enemy, amount_hit: float) -> void:
	var best: Enemy = null
	var best_d2 := CONDUCT_RANGE * CONDUCT_RANGE
	for e in enemies.query_radius(from.position, CONDUCT_RANGE):
		if e == from or e.dead or e.is_prop or not e.is_wet():
			continue
		var d2 := e.position.distance_squared_to(from.position)
		if d2 < best_d2:
			best_d2 = d2
			best = e
	if best == null:
		return
	best.hit(amount_hit * CONDUCT_JUMP, best.position - from.position, 0.2, false)
	var bolt := ChainBolt.new()
	bolt.points = PackedVector2Array([from.position, best.position])
	world.add_child(bolt)
	BotLog.event("combo:CONDUCT")


func _nearest_other(from: Enemy, r: float) -> Enemy:
	var best: Enemy = null
	var best_d2 := r * r
	for e in enemies.query_radius(from.position, r):
		if e == from or e.dead:
			continue
		var d2 := e.position.distance_squared_to(from.position)
		if d2 < best_d2:
			best_d2 = d2
			best = e
	return best


# Final values: the weapon's own stats combined with the cat's passives.

func damage() -> float:
	return stat("damage") * player.stat("might")


func area() -> float:
	return stat("area", 1.0) * player.stat("area")


func interval() -> float:
	return maxf(stat("interval", 1.0) * player.stat("cooldown"), 0.1)


func amount() -> int:
	return int(stat("amount", 1.0) + player.stat("amount"))


func duration() -> float:
	return stat("duration", 1.0) * player.stat("duration")


func proj_speed() -> float:
	return stat("speed", 1.0) * player.stat("proj_speed")


## Shots per burst; weapons that spawn everything at once override this.
func shots() -> int:
	return amount()


func _recalc() -> void:
	stats = {}
	for i in level:
		var lv: Dictionary = data["levels"][i]
		for key: String in lv:
			stats[key] = stats.get(key, 0.0) + lv[key]


func _physics_process(delta: float) -> void:
	if player.is_dead:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown += interval()
		_burst_index = 0
		_burst_count = shots()
		_burst_timer = 0.0
	if _burst_index < _burst_count:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			shoot(_burst_index)
			_burst_index += 1
			_burst_timer = stat("repeat_interval", 0.1)


## Fires shot number `index` of the current burst (0-based).
func shoot(_index: int) -> void:
	pass
