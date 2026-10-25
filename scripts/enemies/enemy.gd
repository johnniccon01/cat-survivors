class_name Enemy
extends Node2D
## One enemy. Movement and collision are driven centrally by EnemyManager
## (much cheaper than hundreds of physics bodies); this node only stores
## state and draws itself.

const KNOCK_SPEED := 120.0
const KNOCK_DECAY := 600.0
const OUTLINE := Color("2b1d14")

var id := ""
var max_hp := 1.0
var hp := 1.0
var speed := 30.0
var damage := 1.0
var radius := 6.0
var xp := 1.0
## How much of the spawn budget this enemy takes while alive.
var cost := 1.0
var knockback_resist := 0.0
var dead := false
var is_prop := false
var is_boss := false
## Seconds left of fading in (enemies that appear inside the screen).
const SPAWN_IN := 0.6
const HALO := 0.09
## Boss specials: below this share of health a boss is angry (faster, attacks
## more often); it only starts a special this close to the cat.
const ENRAGE_AT := 0.3
const ENRAGE_SPEED := 1.3
const SPECIAL_RANGE := 420.0
const SPECIAL_EVERY := Vector2(4.5, 6.5)
## Set by the manager in big crowds (or with the effect saver): enemies stop
## their walk animation then, which saves thousands of redraws a second.
static var calm := false
var spawn_in := 0.0
var is_elite := false
## Set when a swarm enemy has run its course; the manager removes it.
var wants_despawn := false
var manager: EnemyManager

var _shape := "sock"
## "chase" (default), "dash" (winds up, then lunges) or "shooter" (keeps its
## distance and spits laser dots).
var _behavior := "chase"
var _cat_id := ""
var _state := "chase"
var _state_t := 2.0
var _dash_dir := Vector2.ZERO
var _shoot_t := 1.5
var _ring_t := 3.0
var _blink_t := 0.0
var _suck_t := 6.0
var _summon_t := 4.0
var _minion := ""
## Swarm events: run straight in one direction, then vanish.
var _charge_dir := Vector2.ZERO
var _charge_t := 0.0
## Final boss special: "suck" (pulls the cat in) or "roar" (rings of shots).
var _final_mode := "suck"
var _base_scale := 1.0
## Takes no damage while true (the devil cat before it weakens).
var immortal := false
## Survives clear_all (final boss arrival, debug wipe).
var persistent := false
## Its touch kills outright, through revivals and the angel (the devil cat).
var fatal := false
## Speed factor while caught in a web, and how long that lasts.
var _slow := 1.0
var _slow_t := 0.0
## Branch effects: burning (handled by the manager) and the chill tint.
## Champion affix (data/champions.json) or "".
var champion := ""
var champion_color := Color.WHITE
var _taken := 1.0
var _regen := 0.0
## Flee behaviour (the golden mouse): seconds left before it gets away.
var _flee_t := 0.0
## Mid-boss attacks: steam trail, bullet spiral, marked strikes.
var _trail_t := 0.0
var _spiral := 0.0
var _mortar_style := ""
var burn_damage := 0.0
var burn_t := 0.0
var burn_tick := 0.0
var _chill_t := 0.0
## Health multiplier this enemy was spawned with (its splits and summons use it).
var hp_mult := 1.0
## Bosses that call in helpers: id, how many, how often.
var _summon_id := ""
var _summon_count := 0
var _summon_every := 0.0
var _summon_timer := 0.0
## Soft glow under cats like the devil.
## Boss specials (data "specials"): a named attack every few seconds, on top
## of the usual behaviour, so every boss fights its own way.
var _specials: Array = []
var _special := ""
var _special_t := 4.0
var _special_step := 0
var _special_state_t := 0.0
var _special_at := Vector2.ZERO
var _special_dir := Vector2.ZERO
var _aura := Color(0, 0, 0, 0)
var _stripes := false
var _color := Color.WHITE
var _accent := Color.GRAY
var _knock := Vector2.ZERO
var _flash := 0.0
var _wobble := randf() * TAU
## Two-frame sprite animation.
var _anim := randf()
var _frame := 0


func setup(p_id: String, data: Dictionary, p_manager: EnemyManager) -> void:
	id = p_id
	manager = p_manager
	max_hp = data.get("hp", 1.0)
	hp = max_hp
	speed = data.get("speed", 30.0)
	damage = data.get("damage", 1.0)
	radius = data.get("radius", 6.0)
	xp = data.get("xp", 1.0)
	cost = 0.0 if data.get("boss", false) else float(data.get("cost", 1.0))
	knockback_resist = data.get("knockback_resist", 0.0)
	_shape = data.get("shape", "sock")
	_stripes = data.get("stripes", false)
	_color = Color(data.get("color", "#ffffff"))
	_accent = Color(data.get("accent", "#888888"))
	is_boss = data.get("boss", false)
	_behavior = data.get("behavior", "chase")
	_cat_id = data.get("cat", "")
	_minion = data.get("minion", "")
	_final_mode = data.get("final_mode", "suck")
	_base_scale = data.get("scale", 1.0)
	scale = Vector2(_base_scale, _base_scale)
	persistent = data.get("persistent", false)
	_flee_t = float(data.get("flee_time", 0.0))
	_mortar_style = data.get("mortar_style", "")
	_summon_id = data.get("summon", "")
	_summon_count = int(data.get("summon_count", 0))
	_summon_every = float(data.get("summon_every", 8.0))
	_summon_timer = _summon_every * 0.6
	_specials = data.get("specials", [])
	_special_t = randf_range(3.0, 5.0)
	fatal = data.get("fatal", false)
	if data.has("aura"):
		_aura = Color(data["aura"])


## Slows the enemy to `factor` of its speed for `seconds` (webs); the
## strongest current slow wins.
func slow_down(factor: float, seconds: float) -> void:
	if _slow_t <= 0.0 or factor < _slow:
		_slow = factor
	_slow_t = maxf(_slow_t, seconds)


## Turns this enemy into a champion: tougher, with one special trait and a
## coloured aura; worth more XP.
func make_champion(affix: String) -> void:
	var c: Dictionary = GameData.champions[affix]
	champion = affix
	champion_color = Color(c.get("color", "#ffffff"))
	max_hp *= float(c.get("hp", 2.0))
	hp = max_hp
	speed *= float(c.get("speed", 1.0))
	damage *= float(c.get("damage", 1.0))
	_taken = float(c.get("taken", 1.0))
	_regen = float(c.get("regen", 0.0))
	knockback_resist = maxf(knockback_resist, float(c.get("knockback_resist", 0.5)))
	var grow := float(c.get("scale", 1.2))
	_base_scale *= grow
	radius *= grow
	scale = Vector2(_base_scale, _base_scale)
	xp *= 5.0
	manager.budget_used += cost * 2.0
	cost *= 3.0
	queue_redraw()


## Shows the frosty tint for `seconds` (the slow itself is slow_down).
func chill(seconds: float) -> void:
	_chill_t = maxf(_chill_t, seconds)


func charge(dir: Vector2, seconds: float) -> void:
	_charge_dir = dir
	_charge_t = seconds


func is_charging() -> bool:
	return _charge_t > 0.0


## Main colour, used for the death puff.
func tint() -> Color:
	return _color


## Turns a regular enemy into a tougher, bigger quest guard.
func make_elite(hp_factor: float) -> void:
	max_hp *= hp_factor
	hp = max_hp
	radius *= 1.5
	_base_scale *= 1.5
	scale = Vector2(_base_scale, _base_scale)
	knockback_resist = maxf(knockback_resist, 0.7)
	xp *= 10.0
	manager.budget_used += 6.0 - cost
	cost = 6.0
	is_elite = true
	is_boss = true


func tick(delta: float, target: Vector2, push: Vector2) -> void:
	# Appearing on screen: a shadow first, harmless and still, then the enemy.
	if spawn_in > 0.0:
		spawn_in -= delta
		self_modulate.a = clampf(1.0 - spawn_in / SPAWN_IN, 0.15, 1.0)
		queue_redraw()
		return
	var dir := (target - position).normalized()
	var move := dir * speed
	if _charge_t > 0.0:
		_charge_t -= delta
		if _charge_t <= 0.0:
			wants_despawn = true
			return
		dir = _charge_dir
		move = _charge_dir * speed * 2.2
	match _behavior if _charge_t <= 0.0 else "charge":
		"dash":
			move = _tick_dash(delta, dir)
		"shooter":
			move = _tick_shooter(delta, target, dir)
		"final":
			move = _tick_final(delta, target, dir)
		"spit":
			move = _tick_spit(delta, target, dir)
		"dive":
			move = _tick_dive(delta, target, dir)
		"flee":
			move = _tick_flee(delta, dir)
		"trail":
			move = _tick_trail(delta, dir)
		"spiral":
			move = _tick_spiral(delta, dir)
		"mortar":
			move = _tick_mortar(delta, target, dir)
	if is_boss and _charge_t <= 0.0:
		if not _specials.is_empty():
			var special_move := _tick_special(delta, target, dir)
			if special_move != Vector2.INF:
				move = special_move
		# Badly hurt bosses get angry: faster.
		if not is_elite and hp < max_hp * ENRAGE_AT and _special != "pounce" and _special != "rampage":
			move *= ENRAGE_SPEED
	if _summon_id != "":
		_summon_timer -= delta
		if _summon_timer <= 0.0:
			_summon_timer = _summon_every
			for i in _summon_count:
				manager.spawn(_summon_id, position + Vector2.from_angle(TAU * i / _summon_count + randf()) * radius * 1.6, hp_mult)
	if _slow_t > 0.0:
		_slow_t -= delta
		move *= _slow
	if _regen > 0.0 and hp < max_hp:
		hp = minf(max_hp, hp + max_hp * _regen * delta)
	if _chill_t > 0.0:
		_chill_t -= delta
	modulate = Color(1.35, 0.8, 0.55) if burn_t > 0.0 else (Color(0.7, 0.9, 1.4) if _chill_t > 0.0 else Color.WHITE)
	position += (move + _knock + push) * delta
	_knock = _knock.move_toward(Vector2.ZERO, KNOCK_DECAY * delta)
	if absf(dir.x) > 0.2:
		scale.x = signf(dir.x) * _base_scale
	if _shape == "cat" and not calm:
		_wobble += delta * (12.0 if move.length_squared() > 1.0 else 3.0)
		rotation = sin(_wobble * 6.0) * 0.15 if _state == "windup" else 0.0
		queue_redraw()
	else:
		_wobble += delta * speed * 0.15
		rotation = sin(_wobble) * 0.12
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			queue_redraw()
	if not calm:
		_anim += delta * (4.0 + speed * 0.03)
	var f := int(_anim) % 2
	if f != _frame:
		_frame = f
		queue_redraw()


func _tick_dash(delta: float, dir: Vector2) -> Vector2:
	_state_t -= delta
	match _state:
		"windup":
			# The aim is locked when the wind-up starts and the enemy blinks,
			# so the cat can step out of the line.
			_flash = 0.05 if int(_state_t * 10.0) % 2 == 0 else 0.0
			if _state_t <= 0.0:
				_state = "dash"
				_state_t = 0.45
			return Vector2.ZERO
		"dash":
			if _state_t <= 0.0:
				_state = "chase"
				_state_t = randf_range(1.4, 2.0)
				# Lands with a ring of hairballs.
				for i in 6:
					manager.spawn_bullet(position, Vector2.from_angle(TAU * i / 6.0 + randf()), damage * 0.4, "hair")
			return _dash_dir * speed * 5.0
	if _state_t <= 0.0:
		_state = "windup"
		_state_t = 0.7
		_dash_dir = dir
	return dir * speed


## Final boss: alternates chasing, sucking the cat in and spitting out
## minions; below half health it starts lunging too.
func _tick_final(delta: float, target: Vector2, dir: Vector2) -> Vector2:
	_summon_t -= delta
	if _summon_t <= 0.0 and _minion != "":
		_summon_t = 7.0
		for i in 6:
			manager.spawn(_minion, position + Vector2.from_angle(TAU * i / 6.0) * radius * 1.2)
	if _final_mode == "roar":
		_suck_t -= delta
		if _suck_t <= 0.0:
			_suck_t = 5.0
			for i in 16:
				manager.spawn_bullet(position, Vector2.from_angle(TAU * i / 16.0 + _wobble), damage * 0.4, "hair")
		if hp < max_hp * 0.5:
			return _tick_dash(delta, dir)
		return dir * speed
	if _state == "suck":
		_state_t -= delta
		manager.player.pull = (position - target).normalized() * 70.0
		queue_redraw()
		if _state_t <= 0.0:
			_state = "chase"
			_suck_t = 8.0
			queue_redraw()
		return dir * speed * 0.3
	if _state == "chase":
		_suck_t -= delta
		if _suck_t <= 0.0:
			_state = "suck"
			_state_t = 2.5
			return Vector2.ZERO
	if hp < max_hp * 0.5 and _state != "suck":
		return _tick_dash(delta, dir)
	return dir * speed


## Boss specials. Every few seconds one of the boss's "specials" runs:
## "pounce" (marks the cat's spot, leaps on it, shockwave), "bark" (two fast
## fans of shots), "rampage" (three quick lunges), "rain" (a line of marked
## strikes rolling towards the cat), "puddles" (pools that burn), "wall" (a
## row of shots with one gap), "nova" (three rings in a row), "pull" (drags
## the cat in, then a ring). Returns the move, or Vector2.INF to keep the
## usual one.
func _tick_special(delta: float, target: Vector2, dir: Vector2) -> Vector2:
	var angry := hp < max_hp * ENRAGE_AT
	if _special == "":
		_special_t -= delta * (1.5 if angry else 1.0)
		if _special_t > 0.0 or position.distance_to(target) > SPECIAL_RANGE:
			return Vector2.INF
		_special = _specials[randi() % _specials.size()]
		_special_step = 0
		_special_state_t = 0.0
		_special_at = target
		_special_dir = dir
	_special_state_t += delta
	var t := _special_state_t
	var shot := damage * 0.4
	match _special:
		"pounce":
			if _special_step == 0:
				_special_step = 1
				manager.spawn_hazard(_special_at, "strike", 34.0, 0.9, damage * 0.8)
				Audio.play("roar", -8.0, 0.2)
			if t < 0.6:
				_flash = 0.05 if int(t * 10.0) % 2 == 0 else 0.0
				return Vector2.ZERO
			if t < 0.9:
				return (_special_at - position) / maxf(0.9 - t, delta)
			for i in 10:
				manager.spawn_bullet(position, Vector2.from_angle(TAU * i / 10.0), shot, "hair")
			return _end_special()
		"bark":
			if _special_step < 2 and t >= 0.45 + _special_step * 0.5:
				_special_step += 1
				_flash = 0.1
				var aim := (target - position).normalized()
				for i in 7:
					manager.spawn_bullet(position, aim.rotated((i - 3) * 0.17), shot, "hair", 150.0)
				Audio.play("hit", -8.0, 0.2)
			if _special_step >= 2 and t > 1.6:
				return _end_special()
			return Vector2.ZERO
		"rampage":
			# Each lunge aims first, then blinks still a moment with the aim locked.
			var leg := int(t / 0.75)
			if leg >= 3:
				return _end_special()
			var in_leg := fmod(t, 0.75)
			if in_leg < 0.4:
				if in_leg < 0.1:
					_special_dir = (target - position).normalized()
				_flash = 0.05 if int(in_leg * 10.0) % 2 == 0 else 0.0
				return Vector2.ZERO
			return _special_dir * speed * 5.5
		"rain":
			if _special_step == 0:
				_special_step = 1
				var aim := (target - position).normalized()
				for i in 8:
					var at := position + aim * (60.0 + i * 38.0) + aim.orthogonal() * randf_range(-12.0, 12.0)
					manager.spawn_hazard(at, "strike", 24.0, 0.8 + i * 0.12, damage * 0.8)
			if t > 0.8:
				return _end_special()
			return Vector2.ZERO
		"puddles":
			if _special_step == 0:
				_special_step = 1
				manager.spawn_hazard(target, "steam", 26.0, 5.0, damage * 0.3)
				for i in 5:
					manager.spawn_hazard(target + Vector2.from_angle(TAU * i / 5.0 + randf()) * randf_range(55.0, 95.0), "steam", 22.0, 5.0, damage * 0.3)
			return _end_special()
		"wall":
			if _special_step == 0:
				_special_step = 1
				var aim := (target - position).normalized()
				var gap := randi_range(3, 8)
				for i in 13:
					if i == gap or i == gap + 1:
						continue
					manager.spawn_bullet(position + aim.orthogonal() * (i - 6) * 15.0, aim, shot, "laser", 80.0)
			if t > 0.5:
				return _end_special()
			return Vector2.ZERO
		"nova":
			if _special_step < 3 and t >= _special_step * 0.35:
				for i in 14:
					manager.spawn_bullet(position, Vector2.from_angle(TAU * (i + 0.5 * _special_step) / 14.0), shot, "hair")
				_special_step += 1
			if _special_step >= 3:
				return _end_special()
			return dir * speed * 0.3
		"pull":
			if t < 1.8:
				manager.player.pull = (position - target).normalized() * 60.0
				return Vector2.ZERO
			for i in 12:
				manager.spawn_bullet(position, Vector2.from_angle(TAU * i / 12.0), shot, "hair")
			return _end_special()
	return _end_special()


func _end_special() -> Vector2:
	_special = ""
	_special_t = randf_range(SPECIAL_EVERY.x, SPECIAL_EVERY.y)
	return Vector2.INF


## The Iron: lunges like a dashing boss and leaves scalding steam behind.
func _tick_trail(delta: float, dir: Vector2) -> Vector2:
	_trail_t -= delta
	if _trail_t <= 0.0:
		_trail_t = 0.18 if _state == "dash" else 0.6
		manager.spawn_hazard(position, "steam", 15.0, 3.5, damage * 0.35)
	return _tick_dash(delta, dir)


## The Boiler: crawls closer, then stops and sprays a two-armed bullet spiral.
func _tick_spiral(delta: float, dir: Vector2) -> Vector2:
	_state_t -= delta
	if _state_t <= 0.0:
		_state = "rest" if _state == "fire" else "fire"
		_state_t = 3.0 if _state == "fire" else 2.2
	if _state != "fire":
		return dir * speed
	_spiral += delta * 2.4
	_shoot_t -= delta
	if _shoot_t <= 0.0:
		_shoot_t = 0.2
		for k in 2:
			manager.spawn_bullet(position, Vector2.from_angle(_spiral + PI * k), damage * 0.35, "laser")
	return dir * speed * 0.2


## The Scarecrow and the Thundercloud: keep their distance and mark spots
## around the cat that get struck a second later.
func _tick_mortar(delta: float, target: Vector2, dir: Vector2) -> Vector2:
	_shoot_t -= delta
	if _shoot_t <= 0.0:
		_shoot_t = 2.6 if hp > max_hp * 0.5 else 1.8
		for i in 3:
			var at := target if i == 0 else target + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 90.0)
			manager.spawn_hazard(at, "strike", 26.0, 1.0, damage * 0.9, _mortar_style)
	var dist := position.distance_to(target)
	if dist < 120.0:
		return -dir * speed
	if dist > 210.0:
		return dir * speed
	return dir.orthogonal() * speed * 0.5


## Runs away from the cat, zig-zagging, and slips off after a while.
func _tick_flee(delta: float, dir: Vector2) -> Vector2:
	_flee_t -= delta
	if _flee_t <= 0.0:
		wants_despawn = true
		manager.escaped.emit(id, position)
	return (-dir + dir.orthogonal() * sin(_wobble * 0.5) * 0.8).normalized() * speed


## Regular ranged enemy: keeps some distance and spits a slow blob now and then.
func _tick_spit(delta: float, target: Vector2, dir: Vector2) -> Vector2:
	var dist := position.distance_to(target)
	_shoot_t -= delta
	if _shoot_t <= 0.0 and dist < 220.0:
		if manager.try_spit(position, dir, damage * 0.7):
			_shoot_t = randf_range(2.2, 3.0)
			_flash = 0.06
		else:
			_shoot_t = randf_range(0.4, 0.9)
	if dist < 110.0:
		return -dir * speed * 0.7
	if dist > 150.0:
		return dir * speed
	return dir.orthogonal() * speed * 0.4


## Regular diver: when close, stops for a moment, then swoops at the cat.
func _tick_dive(delta: float, target: Vector2, dir: Vector2) -> Vector2:
	_state_t -= delta
	match _state:
		"windup":
			if _state_t <= 0.0:
				_state = "dash"
				_state_t = 0.35
				_dash_dir = dir
			return -dir * speed * 0.2
		"dash":
			if _state_t <= 0.0:
				_state = "chase"
				_state_t = randf_range(2.5, 3.5)
			return _dash_dir * speed * 3.5
	if _state_t <= 0.0 and position.distance_to(target) < 160.0:
		_state = "windup"
		_state_t = 0.5
	return dir * speed


func _tick_shooter(delta: float, target: Vector2, dir: Vector2) -> Vector2:
	var dist := position.distance_to(target)
	_shoot_t -= delta
	_ring_t -= delta
	_blink_t -= delta
	if _shoot_t <= 0.0:
		_shoot_t = 1.2
		# Below half health it fires a fan of three.
		var spread := [0.0] if hp > max_hp * 0.5 else [-0.3, 0.0, 0.3]
		for a: float in spread:
			manager.spawn_bullet(position, dir.rotated(a), damage * 0.4)
	if _ring_t <= 0.0:
		_ring_t = 5.5
		for i in 10:
			manager.spawn_bullet(position, Vector2.from_angle(TAU * i / 10.0), damage * 0.4)
	if dist < 45.0 and _blink_t <= 0.0:
		# Too close: blink away to the other side of the cat.
		_blink_t = 2.5
		position = target - dir * 130.0
		_flash = 0.15
		return Vector2.ZERO
	if dist < 100.0:
		return -dir * speed
	if dist > 150.0:
		return dir * speed
	return dir.orthogonal() * speed * 0.6


## Takes a hit. Hits from the cats can crit (chance scales with luck);
## traps and other world damage pass can_crit = false.
func hit(amount: float, direction: Vector2, knockback: float, can_crit: bool = true) -> void:
	if dead:
		return
	if immortal:
		_flash = 0.05
		queue_redraw()
		return
	amount *= _taken
	var crit := false
	var cat: Player = manager.player
	if can_crit and cat != null and amount > 0.0:
		crit = randf() < cat.stat("crit_chance") * cat.stat("luck")
		if crit:
			amount *= cat.stat("crit_mult")
			Profile.add_stat("crits")
			if CritSpark.alive < CritSpark.MAX_ALIVE * Settings.effects_scale():
				var spark := CritSpark.new()
				spark.position = position + Vector2(randf_range(-4, 4), -radius * 0.5)
				manager.get_parent().add_child(spark)
	if is_boss and can_crit and cat != null:
		amount *= cat.stat("boss_damage")
	if manager.numbers != null and not is_prop:
		manager.numbers.add(position, amount, crit)
	hp -= amount
	if not is_prop:
		Audio.play("hit", -14.0, 0.15)
	_flash = 0.08
	queue_redraw()
	_knock = direction.normalized() * KNOCK_SPEED * knockback * (1.0 - knockback_resist)
	if hp <= 0.0:
		dead = true
		manager.on_enemy_dead(self)


func _draw() -> void:
	var r := radius / _base_scale
	# The halo, shadow, champion aura and spawn ring are drawn for all enemies
	# at once by EnemyGround (props draw their own shadow).
	var sprite := Sprites.enemy(id) if _shape != "cat" else {}
	if not sprite.is_empty():
		if is_prop:
			Blit.ellipse(self, Vector2(1, r + 2), r + 1.5, 3, Color(0, 0, 0, 0.45))
		# Regular enemies flash white; bosses (hit constantly) just brighten.
		var row := 1 if _flash > 0.0 and not is_boss else 0
		var tint := Color(1.5, 1.5, 1.5) if _flash > 0.0 and is_boss else Color.WHITE
		Sprites.draw_frame(self, sprite, _frame, row, tint)
		if _shape == "vacuum" and _state == "suck":
			for i in 8:
				var a := TAU * i / 8.0 + _wobble
				draw_line(Vector2.from_angle(a) * 30.0, Vector2.from_angle(a) * 14.0, Color(0.85, 0.9, 1.0, 0.6), 1.0)
		_draw_boss_marks(r)
		return
	var body := _color
	if _flash > 0.0:
		# Bosses get hit constantly; a lighter tint keeps them recognisable.
		body = _color.lightened(0.4) if is_boss else Color.WHITE
	if is_prop:
		Blit.ellipse(self, Vector2(1, r + 2), r + 1.5, 3, Color(0, 0, 0, 0.45))
	match _shape:
		"dust":
			_draw_dust(body)
		"box":
			_draw_box(body)
		"plant":
			_draw_plant(body)
		"bubble":
			_draw_bubble(body)
		"roomba":
			_draw_roomba(body)
		"slipper":
			_draw_slipper(body)
		"vacuum":
			_draw_vacuum(body)
			if _state == "suck":
				for i in 8:
					var a := TAU * i / 8.0 + _wobble
					draw_line(Vector2.from_angle(a) * 30.0, Vector2.from_angle(a) * 14.0, Color(0.85, 0.9, 1.0, 0.6), 1.0)
		"rat":
			_draw_rat(body)
		"spider":
			_draw_spider(body)
		"moth":
			_draw_moth(body)
		"paint_can":
			_draw_paint_can(body)
		"cat":
			if _aura.a > 0.0:
				for k in 3:
					draw_circle(Vector2(0, -2), r + 3.0 + k * 4.0 + sin(_wobble * 0.5) * 1.5, Color(_aura, 0.13))
			CatArt.draw(self, CatArt.look(_cat_id), 1, _wobble, _flash > 0.0, false, "angry")
		_:
			_draw_sock(body)
	_draw_boss_marks(r)


## Crown and health bar for bosses and elites.
func _draw_boss_marks(r: float) -> void:
	if is_boss:
		if _shape != "cat":
			_draw_crown(Vector2(0, -r - 6))
		var w := 20.0
		draw_rect(Rect2(-w * 0.5 - 0.5, r + 4, w + 1, 2.5), OUTLINE)
		draw_rect(Rect2(-w * 0.5, r + 4.5, w * maxf(hp, 0.0) / max_hp, 1.5), Color("e04646"))


func _draw_sock(body: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(-5, -10), Vector2(3, -10), Vector2(3, 2), Vector2(9, 3),
		Vector2(10, 6), Vector2(8, 9), Vector2(-3, 9), Vector2(-5, 6),
	])
	draw_colored_polygon(pts, body)
	draw_rect(Rect2(-5, -10, 8, 3), _accent)
	if _stripes:
		draw_rect(Rect2(-5, -4, 8, 2), _accent)
		draw_rect(Rect2(-5, 1, 8, 2), _accent)
	draw_colored_polygon(Shapes.ellipse(Vector2(7, 6), 2, 2, 8), _accent)
	draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	# Grumpy face
	draw_rect(Rect2(-3, -6, 1, 2), OUTLINE)
	draw_rect(Rect2(0, -6, 1, 2), OUTLINE)
	draw_line(Vector2(-4, -8), Vector2(-2, -7), OUTLINE, 1.0)
	draw_line(Vector2(2, -8), Vector2(0, -7), OUTLINE, 1.0)


func _draw_dust(body: Color) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		var r := radius + (1.5 if i % 2 == 0 else -0.5)
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	draw_colored_polygon(pts, body)
	draw_polyline(Shapes.closed(pts), _accent, 1.0)
	for e: Vector2 in [Vector2(-2, -1), Vector2(2, -1)]:
		draw_circle(e, 1.8, Color.WHITE)
		draw_rect(Rect2(e + Vector2(0, -0.5), Vector2(1, 1)), OUTLINE)


func _draw_box(body: Color) -> void:
	var r := Rect2(-8, -9, 16, 15)
	draw_rect(r, body)
	draw_rect(Rect2(-8, -9, 16, 4), body.darkened(0.15))
	draw_rect(Rect2(-1.5, -9, 3, 15), _accent)
	draw_rect(r, OUTLINE, false, 1.0)
	draw_line(Vector2(-8, -5), Vector2(8, -5), OUTLINE, 1.0)


func _draw_plant(body: Color) -> void:
	for leaf: Vector2 in [Vector2(-6, -12), Vector2(0, -15), Vector2(6, -12), Vector2(-3, -9), Vector2(3, -9)]:
		var pts := PackedVector2Array([Vector2(0, -4), leaf + Vector2(-2, 1), leaf, leaf + Vector2(2, 1)])
		draw_colored_polygon(pts, _accent)
		draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	var pot := PackedVector2Array([Vector2(-6, -5), Vector2(6, -5), Vector2(4, 6), Vector2(-4, 6)])
	draw_colored_polygon(pot, body)
	draw_rect(Rect2(-7, -6, 14, 3), body.lightened(0.15))
	draw_polyline(Shapes.closed(pot), OUTLINE, 1.0)


func _draw_crown(at: Vector2) -> void:
	var pts := PackedVector2Array([
		at + Vector2(-5, 3), at + Vector2(-5, -2), at + Vector2(-2.5, 0), at + Vector2(0, -3),
		at + Vector2(2.5, 0), at + Vector2(5, -2), at + Vector2(5, 3),
	])
	draw_colored_polygon(pts, Color("f2c14e"))
	draw_polyline(Shapes.closed(pts), OUTLINE, 0.6)
	draw_rect(Rect2(at + Vector2(-0.5, 0.5), Vector2(1, 1)), Color("e04646"))


func _draw_bubble(body: Color) -> void:
	draw_circle(Vector2.ZERO, radius, Color(body, 0.45))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(1, 1, 1, 0.8), 1.0)
	draw_arc(Vector2.ZERO, radius - 2, PI * 1.1, PI * 1.5, 6, Color(1, 1, 1, 0.9), 1.0)
	draw_rect(Rect2(-2, -1, 1, 1), OUTLINE)
	draw_rect(Rect2(1, -1, 1, 1), OUTLINE)


func _draw_roomba(body: Color) -> void:
	var r := 9.0
	draw_circle(Vector2(0, 1), r + 1, OUTLINE)
	draw_circle(Vector2(0, 1), r, body.darkened(0.2))
	draw_circle(Vector2(0, 0), r - 1, body)
	draw_arc(Vector2(0, 0), r - 3, -PI * 0.35, PI * 0.35, 8, body.lightened(0.3), 1.0)
	# Angry LED eyes
	draw_line(Vector2(1, -3), Vector2(4, -2), _accent, 1.0)
	draw_line(Vector2(1, 1), Vector2(4, 0), _accent, 1.0)
	draw_circle(Vector2(-3, 0), 1.5, _accent)


func _draw_slipper(body: Color) -> void:
	var sole := Shapes.ellipse(Vector2(0, 3), 10, 5)
	draw_colored_polygon(sole, _accent)
	draw_polyline(Shapes.closed(sole), OUTLINE, 1.0)
	var strap := PackedVector2Array([Vector2(-1, -2), Vector2(8, -2), Vector2(9, 5), Vector2(-2, 5)])
	draw_colored_polygon(strap, body)
	draw_polyline(Shapes.closed(strap), OUTLINE, 1.0)
	draw_circle(Vector2(9, -2), 3.0, Color.WHITE)
	draw_rect(Rect2(2, 0, 1, 2), OUTLINE)
	draw_rect(Rect2(5, 0, 1, 2), OUTLINE)
	draw_line(Vector2(1, -1), Vector2(3, 0), OUTLINE, 1.0)
	draw_line(Vector2(7, -1), Vector2(5, 0), OUTLINE, 1.0)


func _draw_vacuum(body: Color) -> void:
	# Upright vacuum cleaner with a grumpy face on the bag.
	draw_line(Vector2(-2, -14), Vector2(-2, -4), OUTLINE, 3.0)
	draw_line(Vector2(-2, -14), Vector2(-2, -4), _accent, 1.0)
	draw_line(Vector2(-4, -14), Vector2(0, -14), OUTLINE, 2.0)
	var bag := PackedVector2Array([Vector2(-6, -8), Vector2(4, -8), Vector2(6, 4), Vector2(-7, 4)])
	draw_colored_polygon(bag, body)
	draw_polyline(Shapes.closed(bag), OUTLINE, 1.0)
	draw_rect(Rect2(-9, 4, 18, 4), _accent)
	draw_rect(Rect2(-9, 4, 18, 4), OUTLINE, false, 1.0)
	draw_circle(Vector2(-6, 9), 1.5, OUTLINE)
	draw_circle(Vector2(6, 9), 1.5, OUTLINE)
	draw_rect(Rect2(-3, -4, 1, 2), OUTLINE)
	draw_rect(Rect2(1, -4, 1, 2), OUTLINE)
	draw_line(Vector2(-4, -6), Vector2(-2, -5), OUTLINE, 1.0)
	draw_line(Vector2(3, -6), Vector2(1, -5), OUTLINE, 1.0)
	draw_line(Vector2(-2, 1), Vector2(2, 1), OUTLINE, 1.0)


func _draw_rat(body: Color) -> void:
	var sway := sin(_wobble * 2.0) * 2.0
	draw_polyline(PackedVector2Array([Vector2(-7, 1), Vector2(-11, -1 + sway), Vector2(-14, 2 + sway)]), _accent, 1.0)
	var b := Shapes.ellipse(Vector2(-1, 1), 7, 4.5)
	draw_colored_polygon(b, body)
	draw_polyline(Shapes.closed(b), OUTLINE, 1.0)
	var head := PackedVector2Array([Vector2(3, -3), Vector2(9, 1), Vector2(3, 4)])
	draw_colored_polygon(head, body)
	draw_polyline(Shapes.closed(head), OUTLINE, 1.0)
	draw_circle(Vector2(3, -3), 2.2, OUTLINE)
	draw_circle(Vector2(3, -3), 1.5, _accent)
	draw_rect(Rect2(5, -1, 1, 1), Color("e04646"))
	draw_rect(Rect2(9, 0, 1, 1), _accent)


func _draw_spider(body: Color) -> void:
	var step := sin(_wobble * 3.0) * 1.5
	for side: float in [-1.0, 1.0]:
		for i in 4:
			var root := Vector2(-3 + i * 2.0, 0)
			var knee := root + Vector2((i - 1.5) * 3.0, side * 5.0 + (step if i % 2 == 0 else -step))
			var foot := knee + Vector2((i - 1.5) * 2.0, side * 3.0)
			draw_polyline(PackedVector2Array([root, knee, foot]), OUTLINE, 1.0)
	draw_circle(Vector2(-2, 0), 4.5, OUTLINE)
	draw_circle(Vector2(-2, 0), 3.7, body)
	draw_circle(Vector2(3, 0), 3.0, OUTLINE)
	draw_circle(Vector2(3, 0), 2.3, body.lightened(0.1))
	draw_rect(Rect2(-3, -1, 2, 2), _accent)
	for e: Vector2 in [Vector2(4, -1), Vector2(4, 1), Vector2(5, 0)]:
		draw_rect(Rect2(e, Vector2(1, 1)), Color("e04646"))


func _draw_moth(body: Color) -> void:
	var flap := absf(sin(_wobble * 4.0))
	for side: float in [-1.0, 1.0]:
		var wing := Shapes.ellipse(Vector2(0, side * (3.0 + flap * 2.0)), 5.0, 2.0 + flap * 2.0, 10)
		draw_colored_polygon(wing, body)
		draw_polyline(Shapes.closed(wing), _accent, 1.0)
	draw_line(Vector2(-4, 0), Vector2(4, 0), OUTLINE, 2.0)
	draw_line(Vector2(4, 0), Vector2(7, -2), OUTLINE, 1.0)
	draw_line(Vector2(4, 0), Vector2(7, 2), OUTLINE, 1.0)


func _draw_paint_can(body: Color) -> void:
	draw_rect(Rect2(-6, -6, 12, 12), body)
	draw_rect(Rect2(-6, -2, 12, 5), _accent)
	draw_rect(Rect2(-6, -6, 12, 12), OUTLINE, false, 1.0)
	draw_arc(Vector2(0, -6), 5.0, PI, TAU, 8, OUTLINE, 1.0)
	draw_rect(Rect2(2, 6, 3, 2), _accent)
