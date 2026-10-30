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
	var real := not enemy.is_prop
	var conduct := base == "ANTENNA" and real and enemy.is_wet()
	if conduct:
		amount_hit *= 1.0 + CONDUCT_BONUS
	# Combos that make this hit itself stronger (see Combos).
	var shatter := base == "SQUEAKY_HAMMER" and real and player.has_combo("SHATTER") and (enemy.is_chilled() or enemy.is_frozen())
	if shatter:
		amount_hit *= 1.0 + Combos.SHATTER_BONUS
	if base == "MOUSE_TOY" and real and enemy.mark_t > 0.0 and player.has_combo("CHASE"):
		amount_hit *= 1.0 + Combos.CHASE_BONUS
		BotLog.event("combo:CHASE")
	if base == "HAIRBALL" and player.has_combo("HEAVY"):
		amount_hit *= 1.0 + Combos.HEAVY_BONUS
		knockback *= 1.0 + Combos.HEAVY_BONUS
	if base == "FEATHER" and real and player.has_combo("CATNIP_HIGH") and _in_catnip(enemy):
		amount_hit *= 1.0 + Combos.CATNIP_BONUS
		BotLog.event("combo:CATNIP_HIGH")
	var was_wet := real and enemy.is_wet()
	enemy.hit(amount_hit, dir, knockback)
	if base in WET_SOURCES and not enemy.dead and real:
		enemy.make_wet(WET_SECONDS)
	if conduct:
		_conduct(enemy, amount_hit)
	if real:
		_after_combos(base, enemy, amount_hit, was_wet, shatter)
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


## Combos that add something after the hit (see Combos).
func _after_combos(base: String, enemy: Enemy, amount_hit: float, was_wet: bool, shatter: bool) -> void:
	if player.combos.is_empty():
		return
	match base:
		"FROST_FISH":
			if was_wet and not enemy.dead and player.has_combo("ICE"):
				enemy.slow_down(0.5 if enemy.is_boss else 0.0, Combos.ICE_SECONDS)
				enemy.chill(Combos.ICE_SECONDS + 1.0)
				BotLog.event("combo:ICE")
		"SQUEAKY_HAMMER":
			if shatter:
				for e in enemies.query_radius(enemy.position, Combos.SHATTER_RADIUS):
					if e != enemy and not e.dead:
						e.hit(amount_hit * Combos.SHATTER_SPLINTER, e.position - enemy.position, 0.3, false)
				_burst(enemy.position, Combos.SHATTER_RADIUS, Color("bfe8ff"))
				BotLog.event("combo:SHATTER")
			if player.has_combo("RESONANCE") and randf() < Combos.RESONANCE_CHANCE:
				var ring := _burst(enemy.position, Combos.RESONANCE_RADIUS * area(), Color("f2c14e"))
				ring.damage = amount_hit * Combos.RESONANCE_DAMAGE
				ring.knockback = 0.4
				Audio.play("bell", -14.0, 0.2)
				BotLog.event("combo:RESONANCE")
		"LASER":
			if player.has_combo("CHASE"):
				enemy.mark_t = Combos.CHASE_MARK
		"YARN":
			if not enemy.dead and player.has_combo("TANGLE"):
				enemy.slow_down(Combos.TANGLE_SLOW, Combos.TANGLE_SECONDS)
				BotLog.event("combo:TANGLE")
		"DRONE_BUDDY":
			if player.has_combo("SIGNAL") and randf() < Combos.SIGNAL_CHANCE:
				var other := _nearest_other(enemy, 80.0)
				if other != null:
					other.hit(amount_hit * Combos.SIGNAL_DAMAGE, other.position - enemy.position, 0.2, false)
					var bolt := ChainBolt.new()
					bolt.points = PackedVector2Array([enemy.position, other.position])
					world.add_child(bolt)
					BotLog.event("combo:SIGNAL")


## A ring that only shows (or hits, once `damage` is set) round `at`.
func _burst(at: Vector2, r: float, color: Color) -> RingWave:
	var ring := RingWave.new()
	ring.enemies = enemies
	ring.position = at
	ring.max_radius = r
	ring.expand_time = 0.16
	ring.damage = 0.0
	ring.knockback = 0.0
	ring.color = color
	world.add_child(ring)
	return ring


## Inside the catnip cloud round the cat (combo Catnip high).
func _in_catnip(enemy: Enemy) -> bool:
	for w: Weapon in player.weapons.get_children():
		if w.base_id() == "CATNIP":
			return enemy.position.distance_to(player.position) < Combos.CATNIP_RADIUS * w.area()
	return false


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
	var a := stat("area", 1.0) * player.stat("area")
	# Combo: watered-down milk spreads wider.
	if base_id() == "MILK" and player.has_combo("THIN_MILK"):
		a *= 1.0 + Combos.MILK_AREA
	return a


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
