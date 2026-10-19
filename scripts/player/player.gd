class_name Player
extends Node2D
## A cat: the one you play, or a companion that follows it. Look, starting
## weapon and stat bonus come from data/cats.json. Weapons fire on their own.
##
## Controllers: "input" (WASD / arrows / left stick), "bot" (automated tests)
## "follow" (companion: trails the leader, can't be hurt, borrows the
## leader's stats and levels its weapon as the leader levels up) and
## "escort" (a rescued cat being walked home: slower, unarmed, can be hurt
## and knocked down).

signal died
signal leveled_up
signal xp_changed
signal inventory_changed
signal revived
signal hurt

const RADIUS := 7.0
const HIT_INVULN := 0.4
const MAX_WEAPONS := 6
const MAX_PASSIVES := 6
const BASE_SPEED := 115.0

## Base values of all character stats; passives add to these.
const BASE_STATS := {
	"might": 1.0, "area": 1.0, "cooldown": 1.0, "amount": 0.0, "speed": 1.0,
	"max_hp": 100.0, "regen": 0.0, "magnet": 40.0, "duration": 1.0,
	"proj_speed": 1.0, "armor": 0.0,
	"growth": 1.0, "greed": 1.0, "curse": 1.0, "revival": 0.0, "reroll": 0.0,
	"crit_chance": 0.05, "crit_mult": 2.0, "luck": 1.0,
	# Artifacts: damage to bosses, thorns when hurt, healing per level, less
	# damage below 30 % health, and timers (seconds) for the hourglass freeze
	# and the magnet pulse.
	"boss_damage": 1.0, "thorns": 0.0, "level_heal": 0.0, "low_hp_guard": 0.0,
	"freeze_every": 0.0, "pulse_magnet": 0.0, "heal_power": 1.0,
	# Shop: extra weapon slots on top of MAX_WEAPONS.
	"weapon_slots": 0.0,
}

const OUTLINE := Color("2b1d14")
## Companion weapon gains a level every this many leader levels.
const COMPANION_LEVEL_STEP := 2
const COMPANION_EVOLVE_AT := 25
const COMPANION_SECOND_AT := 12

@export var cat_id := "MICA"
@export var controller := "input"

## The cat a companion follows.
var leader: Player
## Slows the cat while it carries something for a quest.
var speed_factor := 1.0
## Max health of an escorted cat.
var escort_hp := 60.0
## Dev cheat: ignore all damage.
var god := false
## From the Revival / Reroll power-ups, used up during the run.
var revivals_left := 0
## Damage actually taken this run (after armor), for balance reports.
var damage_taken := 0.0
## Set when the killing blow can't be survived (the devil cat): no revival
## power-up and no angel.
var killed_by_fatal := false
var rerolls_left := 0
## External pull (e.g. the final boss sucking the cat in); reset every frame.
var pull := Vector2.ZERO

var hp := 100.0
var max_hp := 100.0
var level := 1
var xp := 0.0
var facing := 1
var velocity := Vector2.ZERO
var is_dead := false
## passive id -> level
var passives: Dictionary = {}
var stats: Dictionary = BASE_STATS.duplicate()
var _look: Dictionary
var _follow_offset := Vector2.ZERO
var _shake := 0.0
var _shake_time := 0.0
var _shake_left := 0.0
var _invuln := 0.0
var _hurt_flash := 0.0
var _walk_t := 0.0
var _bot_t := 0.0

@onready var weapons: Node = $Weapons
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	if controller != "follow":
		cat_id = Profile.selected_cat
	_look = CatArt.look(cat_id)
	if controller == "follow" or controller == "escort":
		camera.queue_free()
		camera = null
		_follow_offset = Vector2.from_angle(randf() * TAU) * randf_range(18.0, 30.0)
	_recalc_stats()
	if controller == "escort":
		max_hp = escort_hp
		stats["speed"] = 0.8
	hp = max_hp
	revivals_left = int(stats["revival"])
	rerolls_left = int(stats["reroll"])
	if controller != "escort":
		for id in _start_weapons():
			add_weapon(id)


## The cat's own weapon, or --start-weapon=ID[,ID...] (tests) for the played cat.
func _start_weapons() -> PackedStringArray:
	if controller == "input" or controller == "bot":
		for arg: String in GameData.args():
			if arg.begins_with("--start-weapon="):
				return arg.trim_prefix("--start-weapon=").split(",")
	var weapon: String = GameData.cats[cat_id]["weapon"]
	# The Stray starts with nothing: its first level comes from traps.
	return PackedStringArray([weapon]) if weapon != "" else PackedStringArray()


## The bestiary shows weapons and passives once the played cat has had them.
func _mark_used(id: String) -> void:
	if controller == "input" or controller == "bot":
		Profile.set_flag("used:" + id)


## Weapon slots: one with the "one weapon" challenge.
func max_weapons() -> int:
	if (controller == "input" or controller == "bot") and Profile.has_challenge("ONE_WEAPON"):
		return 1
	return MAX_WEAPONS + int(stat("weapon_slots"))


func is_companion() -> bool:
	return controller == "follow"


func stat(stat_name: String) -> float:
	if is_companion() and is_instance_valid(leader):
		return leader.stat(stat_name)
	return stats[stat_name]


func xp_to_next() -> float:
	# Same shape as Vampire Survivors: cheap first levels, then a steady climb.
	if level < 20:
		return 5.0 + (level - 1) * 8.0
	if level < 40:
		return 157.0 + (level - 20) * 18.0
	return 517.0 + (level - 40) * 30.0


func add_xp(amount: float) -> void:
	if is_dead:
		return
	xp += amount * stats["growth"]
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		if stats["level_heal"] > 0.0:
			heal(max_hp * stats["level_heal"])
		leveled_up.emit()
	xp_changed.emit()


func heal(amount: float) -> void:
	# Challenge "no healing": nothing heals the played cat.
	if (controller == "input" or controller == "bot") and Profile.has_challenge("NO_HEAL"):
		return
	hp = minf(hp + amount, max_hp)


func get_weapon(id: String) -> Weapon:
	for weapon: Weapon in weapons.get_children():
		if weapon.id == id:
			return weapon
	return null


func weapon_count() -> int:
	return weapons.get_child_count()


func add_weapon(id: String) -> Weapon:
	var data: Dictionary = GameData.weapons[id]
	var weapon: Weapon = load(data["script"]).new()
	weapon.setup(id, data, self)
	_mark_used(id)
	weapons.add_child(weapon)
	inventory_changed.emit()
	return weapon


func level_up_weapon(id: String) -> void:
	get_weapon(id).level_up()
	inventory_changed.emit()


## Replaces a maxed weapon with its evolved form, keeping its slot.
func evolve_weapon(from_id: String, into_id: String) -> void:
	var old := get_weapon(from_id)
	var index := old.get_index()
	weapons.remove_child(old)
	old.queue_free()
	var evolved := add_weapon(into_id)
	evolved.branch = old.branch
	evolved.branch_rank = old.branch_rank
	weapons.move_child(evolved, index)
	if controller == "input" or controller == "bot":
		Profile.set_flag("evolved:" + into_id)
	inventory_changed.emit()


## Picks a branch for a weapon, or raises it to rank 2.
func choose_branch(weapon_id: String, branch_id: String) -> void:
	var w := get_weapon(weapon_id)
	if w == null:
		return
	if w.branch == branch_id:
		w.branch_rank = mini(w.branch_rank + 1, 2)
	else:
		w.branch = branch_id
		w.branch_rank = 1
	_mark_used("branch:" + branch_id)
	inventory_changed.emit()


func add_passive(id: String) -> void:
	_mark_used(id)
	passives[id] = passives.get(id, 0) + 1
	_recalc_stats()
	inventory_changed.emit()


func _recalc_stats() -> void:
	stats = BASE_STATS.duplicate()
	var bonus: Dictionary = GameData.cats[cat_id].get("bonus", {})
	for key: String in bonus:
		stats[key] += bonus[key]
	if controller == "input" or controller == "bot":
		var shop := Profile.powerup_bonus()
		for key: String in shop:
			stats[key] += shop[key]
		var worn := Profile.charm_bonus()
		for key: String in worn:
			stats[key] += worn[key]
		var artifacts := Profile.artifact_bonus()
		for key: String in artifacts:
			stats[key] += artifacts[key]
	for id: String in passives:
		var levels: Array = GameData.passives[id]["levels"]
		for i in passives[id]:
			var lv: Dictionary = levels[i]
			for key: String in lv:
				stats[key] += lv[key]
	if controller == "input" or controller == "bot":
		# Challenges: a fragile cat that hits harder, a cursed night.
		if Profile.has_challenge("GLASS"):
			stats["max_hp"] *= 0.5
			stats["might"] *= 1.5
		if Profile.has_challenge("CURSED"):
			stats["curse"] += 0.5
	var old_max := max_hp
	max_hp = stats["max_hp"]
	hp += maxf(max_hp - old_max, 0.0)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var input: Vector2
	match controller:
		"bot":
			input = _bot_input(delta)
		"follow", "escort":
			input = _follow_input()
		_:
			input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * BASE_SPEED * stat("speed") * speed_factor
	position += (velocity + pull) * delta
	pull = Vector2.ZERO
	var manager: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")
	if manager != null and not manager.arena.is_empty():
		var center: Vector2 = manager.arena["center"]
		var r: float = manager.arena["radius"] - RADIUS
		if position.distance_to(center) > r:
			position = center + (position - center).normalized() * r
	if absf(input.x) > 0.1:
		facing = 1 if input.x > 0.0 else -1
	if stats["regen"] > 0.0:
		heal(stats["regen"] * delta)
	_invuln = maxf(_invuln - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_walk_t += delta * (12.0 if velocity.length_squared() > 1.0 else 3.0)
	queue_redraw()


func take_damage(amount: float, fatal: bool = false) -> void:
	if is_dead or _invuln > 0.0 or is_companion() or god:
		return
	if fatal:
		amount = hp + stats["armor"] + 1.0
	elif stats["low_hp_guard"] > 0.0 and hp < max_hp * 0.3:
		amount *= 1.0 - stats["low_hp_guard"]
	var dealt := maxf(amount - stats["armor"], 1.0)
	hp -= dealt
	damage_taken += dealt
	if controller == "bot" and hp <= 0.0:
		# Test runs: report what landed the last hit.
		var src := "?"
		for st in get_stack():
			src = "%s:%d" % [String(st["source"]).get_file(), st["line"]]
			if src.begins_with("trap") or src.begins_with("enemy"):
				break
		print("BOT: killed by ", src)
	if controller != "escort":
		Audio.play("hurt", -6.0)
		shake(2.5, 0.18)
		hurt.emit()
	_invuln = HIT_INVULN
	_hurt_flash = 0.12
	if hp <= 0.0 and revivals_left > 0 and not fatal:
		revivals_left -= 1
		hp = max_hp * 0.5
		_invuln = 2.0
		revived.emit()
		return
	if hp <= 0.0:
		hp = 0.0
		is_dead = true
		killed_by_fatal = fatal
		queue_redraw()
		died.emit()


## Companion: walk to a spot near the leader; catch up faster when far away.
func _follow_input() -> Vector2:
	if not is_instance_valid(leader):
		return Vector2.ZERO
	if leader.is_dead:
		return Vector2.ZERO
	_sync_companion_weapon()
	var goal := leader.position + _follow_offset
	var to := goal - position
	if to.length() < 6.0:
		return Vector2.ZERO
	if to.length() > 400.0:
		position = goal
		return Vector2.ZERO
	return to.normalized() * clampf(to.length() / 40.0, 0.4, 1.6)


## Brings a knocked-down cat back on its feet.
func revive(fraction: float, invuln: float = 1.0) -> void:
	is_dead = false
	hp = max_hp * fraction
	_invuln = invuln
	queue_redraw()


## A companion grows with the cat it follows: its weapon gains a level every
## COMPANION_LEVEL_STEP levels of the leader, evolves once the leader reaches
## COMPANION_EVOLVE_AT, and from COMPANION_SECOND_AT it also borrows one of
## the leader's other weapons (kept at the same level).
func _sync_companion_weapon() -> void:
	if weapons.get_child_count() == 0 or not is_instance_valid(leader):
		return
	var target := 1 + floori(leader.level / float(COMPANION_LEVEL_STEP))
	for child in weapons.get_children():
		var weapon := child as Weapon
		if weapon == null or weapon.is_queued_for_deletion():
			continue
		while weapon.level < mini(target, weapon.max_level()):
			weapon.level_up()
		var evo: Dictionary = weapon.data.get("evolve", {})
		if leader.level >= COMPANION_EVOLVE_AT and not evo.is_empty() and weapon.level >= weapon.max_level():
			evolve_weapon(weapon.id, evo["into"])
			return
	if leader.level >= COMPANION_SECOND_AT and weapons.get_child_count() < 2:
		var own := Icons.base_weapon((weapons.get_child(0) as Weapon).id)
		var options: Array[String] = []
		for child in leader.weapons.get_children():
			var w := child as Weapon
			if w != null and Icons.base_weapon(w.id) != own:
				options.append(Icons.base_weapon(w.id))
		if not options.is_empty():
			add_weapon(options.pick_random())


## Shakes the camera (main cat only); a stronger shake overrides a weaker one.
func shake(strength: float, seconds: float) -> void:
	if camera == null or not Settings.screen_shake:
		return
	if strength >= _shake * (_shake_left / maxf(_shake_time, 0.001)):
		_shake = strength
		_shake_time = seconds
		_shake_left = seconds


func _process(delta: float) -> void:
	if camera == null:
		return
	if _shake_left > 0.0:
		_shake_left -= delta
		var k := clampf(_shake_left / _shake_time, 0.0, 1.0)
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * k
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO


## Test bot: dodges enemies that get close, heads for an open cat flap or
## the active quest, collects nearby pickups, otherwise drifts towards the
## nearest enemy so its weapons have something to hit.
func _bot_input(delta: float) -> Vector2:
	_bot_t += delta
	var wander := Vector2(cos(_bot_t * 0.3), sin(_bot_t * 0.5))
	var manager: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")
	# No weapon yet (the Stray): circle the nearest trap so enemies run into
	# it, dodging (below) whenever one gets close.
	if weapon_count() == 0 and manager.query_radius(position, 45.0).is_empty():
		var best: Node2D = null
		for node in get_parent().get_children():
			if node is Trap and (best == null or position.distance_to(node.position) < position.distance_to(best.position)):
				best = node
		if best != null:
			var goal := best.position + Vector2.from_angle(_bot_t * 1.5) * 45.0
			return (goal - position).normalized()
	# Standing in a quest zone matters more than dodging (while healthy).
	var quest_here: Quest = get_parent().quests.active if get_parent().get("quests") else null
	if quest_here != null and quest_here.started and hp > max_hp * 0.5 and quest_here.target_position().distance_to(position) < 40.0:
		var stay := quest_here.target_position() - position
		return stay.normalized() if stay.length() > 6.0 else Vector2.ZERO
	var away := Vector2.ZERO
	# Keep clear of each enemy by its own size (big bosses from further away).
	for enemy in manager.query_radius(position, 90.0):
		var d := position - enemy.position
		if d.length() > enemy.radius + 30.0:
			continue
		away += d / maxf(d.length_squared(), 1.0) * (1.0 + enemy.radius / 10.0)
	if away != Vector2.ZERO:
		return (away.normalized() + wander * 0.3).normalized()
	# Chase a golden mouse if one is around.
	for e in manager.enemies:
		if e.id == "GOLDEN_MOUSE" and e.position.distance_to(position) < 500.0:
			return (e.position - position).normalized()
	# A diary page on the map is worth a detour.
	var page: Variant = get_parent().get("_page_item")
	if is_instance_valid(page):
		return ((page as Node2D).position - position).normalized()
	# Only escape through a cat flap when the test asks for it (--extract);
	# otherwise balance runs would end the moment a flap opens.
	var flap: Node2D = get_parent().get("extraction")
	if flap != null and "--extract" in GameData.args():
		var to_flap := flap.position - position
		return to_flap.normalized() if to_flap.length() > 10.0 else Vector2.ZERO
	var quest: Quest = get_parent().quests.active if get_parent().get("quests") else null
	if quest != null:
		var to_quest := quest.target_position() - position
		if to_quest.length() > 8.0:
			return (to_quest.normalized() + wander * 0.15).normalized()
		return Vector2.ZERO
	var pickups: Pickups = get_parent().get_node("Pickups")
	var best_d2 := 160.0 * 160.0
	var goal := Vector2.INF
	for item in pickups.items:
		var d2 := item.position.distance_squared_to(position)
		if d2 < best_d2:
			best_d2 = d2
			goal = item.position
	if goal != Vector2.INF:
		return (goal - position).normalized()
	var target := manager.nearest(position)
	if target != null and target.position.distance_to(position) > 50.0:
		return ((target.position - position).normalized() * 0.7 + wander * 0.3).normalized()
	return wander.normalized()


func _draw() -> void:
	CatArt.draw(self, _look, facing, _walk_t, _hurt_flash > 0.0, is_dead, "normal", Vector2.ZERO, 1.0, velocity.length_squared() > 1.0)
	if is_dead or is_companion():
		return
	if controller == "escort":
		draw_rect(Rect2(-10, -24, 20, 4), OUTLINE)
		draw_rect(Rect2(-9, -23, 18 * hp / max_hp, 2), Color("6cc46c"))
		return
	# HP bar
	var w := 18.0
	var y := 11.0 * float(_look["size"])
	draw_rect(Rect2(-w * 0.5 - 1, y, w + 2, 4), OUTLINE)
	draw_rect(Rect2(-w * 0.5, y + 1, w * hp / max_hp, 2), Color("e04646"))
