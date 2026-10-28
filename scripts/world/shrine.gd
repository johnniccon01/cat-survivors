class_name Shrine
extends Node2D
## A cat shrine that turns up on the map now and then (Death Must Die-like).
## Stand next to it for a moment to wake it, then pick what it gives you: the
## first offer is always safe, the others give more but cost something.
##   MIGHT   – stronger attacks; or much stronger for a quarter of your health;
##             or a little stronger all night while enemies get tougher
##   HASTE   – faster paws and weapons; or much faster but frailer for a
##             while; or faster weapons all night but you take more damage
##   MILK    – heals and keeps healing; or more max health for the night but
##             heavy paws for a while
##   FORTUNE – a shower of gold and all kibble; or two levels for 40 % of your
##             health; or more gold all night while enemies get tougher
##   CURSED  – a little luck; or guards that guard a chest; or champion
##             guards that guard a boss chest
##   BONE    – (all night) armor; or armor and health but slower paws; or
##             thorns and crits but less health
##   MOON    – (all night) faster growth; or much faster growth but tougher
##             enemies; or a reroll and a banish now
##   CHAOS   – (all night) one random stat up; a gamble: an extra projectile
##             or a third of your health gone; or big damage and area while
##             enemies get tougher and faster

const OUTLINE := Color("2b1d14")
const RADIUS := 48.0
const WAKE_TIME := 2.0
const BLESS_SECONDS := 45.0
const CURSED_GUARDS := 5
const CURSED_GUARDS_BIG := 8
## Bonuses that last the rest of the night (the HUD shows no seconds for them).
const FOR_THE_NIGHT := 99999.0
## How many offers each shrine makes (texts SHRINE_<KIND>_OPT<n>).
const OFFERS := {"MIGHT": 3, "HASTE": 3, "MILK": 2, "FORTUNE": 3, "CURSED": 3, "BONE": 3, "MOON": 3, "CHAOS": 3}
const CURSED_LIMIT := 75.0
## The great curse gives a boss chest only from this second of the night.
const BOSS_CHEST_FROM := 480.0
## Forgotten shrines crumble after a while.
const LIFETIME := 100.0
const KINDS := {"MIGHT": 3.0, "HASTE": 3.0, "MILK": 2.0, "FORTUNE": 2.0, "CURSED": 2.5, "BONE": 2.0, "MOON": 2.0, "CHAOS": 1.5}
## Chaos shrine's first offer: one of these, all night.
const CHAOS_STATS := [{"might": 0.15}, {"area": 0.15}, {"cooldown": -0.1}, {"luck": 0.2}, {"magnet": 40.0}, {"regen": 1.0}]
const COLORS := {
	"MIGHT": Color("ff5a4a"), "HASTE": Color("6cc8ff"), "MILK": Color("8ee07a"),
	"FORTUNE": Color("f2c14e"), "CURSED": Color("b06aff"),
	"BONE": Color("e8e0cc"), "MOON": Color("9fb4ff"), "CHAOS": Color("ff6ad5"),
}

var kind := "MIGHT"
var main: Node
var used := false
var _wake := 0.0
var _t := 0.0
var _gone := 0.0
var _guards: Array[Enemy] = []
var _guard_t := 0.0
## The big curse: champion guards, and a boss chest for beating them.
var _big_curse := false


static func random_kind() -> String:
	var total := 0.0
	for k: String in KINDS:
		total += float(KINDS[k])
	var r := randf() * total
	for k: String in KINDS:
		r -= float(KINDS[k])
		if r <= 0.0:
			return k
	return "MIGHT"


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -3
	add_to_group("shrine")


func color() -> Color:
	return COLORS.get(kind, Color.WHITE)


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	var cat: Player = main.player
	if used:
		if not _guards.is_empty():
			_tick_guards(delta)
		else:
			_gone += delta
			if _gone > 3.0:
				queue_free()
		return
	if _t > LIFETIME or cat.position.distance_to(position) > 1600.0:
		queue_free()
		return
	if not cat.is_dead and cat.position.distance_to(position) < RADIUS:
		_wake += delta
		if _wake >= WAKE_TIME:
			_activate(cat)
	else:
		_wake = maxf(_wake - delta * 0.5, 0.0)


## Waking a shrine asks what you want from it, as in Death Must Die: the
## first offer is always safe, the others give more but cost something.
func _activate(cat: Player) -> void:
	used = true
	Audio.play("bell", -2.0, 0.0)
	var options: Array = []
	for i in OFFERS[kind]:
		options.append(tr("SHRINE_%s_OPT%d" % [kind, i]))
	# The last choice turns every offer down; the shrine just goes quiet.
	options.append(tr("SHRINE_REFUSE"))
	main.ask_choice(tr("SHRINE_%s_NAME" % kind), tr("SHRINE_PROMPT"), options, func(index: int) -> void:
		if index >= OFFERS[kind]:
			print("SHRINE: %s refused" % kind)
			return
		Profile.add_stat("shrines")
		_grant(cat, index)
		main.hud.show_banner("%s: %s" % [tr("SHRINE_%s_NAME" % kind), options[index]], 4.0)
		print("SHRINE: %s activated, offer %d" % [kind, index]))


func _grant(cat: Player, offer: int) -> void:
	var c := color()
	var name_key := "SHRINE_%s_NAME" % kind
	match [kind, offer]:
		["MIGHT", 0]:
			cat.bless({"might": 0.25}, BLESS_SECONDS, name_key, c)
		["MIGHT", 1]:
			# Blood oath: a quarter of your health for a huge, longer boost.
			_bleed(cat, 0.25)
			cat.bless({"might": 0.6}, 60.0, name_key, c)
		["MIGHT", 2]:
			cat.bless({"might": 0.12, "curse": 0.1}, FOR_THE_NIGHT, name_key, c)
		["HASTE", 0]:
			cat.bless({"speed": 0.15, "cooldown": -0.1}, BLESS_SECONDS, name_key, c)
		["HASTE", 1]:
			cat.bless({"speed": 0.35, "cooldown": -0.3, "max_hp": -cat.max_hp * 0.3}, BLESS_SECONDS, name_key, c)
			cat.hp = minf(cat.hp, cat.max_hp)
		["HASTE", 2]:
			cat.bless({"cooldown": -0.08, "armor": -2.0}, FOR_THE_NIGHT, name_key, c)
		["MILK", 0]:
			cat.heal(cat.max_hp * 0.4)
			cat.bless({"regen": 1.5}, BLESS_SECONDS, name_key, c)
		["MILK", 1]:
			# Cream: more health for good, but heavy paws for a while.
			cat.bless({"max_hp": 25.0}, FOR_THE_NIGHT, name_key, c)
			cat.bless({"speed": -0.25}, 30.0, "SHRINE_HEAVY", Color("9a8a7a"))
		["FORTUNE", 0]:
			for i in 12:
				main.pickups.spawn_named("coin", position + Vector2.from_angle(TAU * i / 12.0) * 26.0, 5.0)
			main.pickups.pull_all_xp()
		["FORTUNE", 1]:
			# Like Death Must Die's fruit tree: health for two levels.
			_bleed(cat, 0.4)
			for i in 2:
				cat.add_xp((cat.xp_to_next() - cat.xp) / cat.stat("growth") + 0.01)
		["FORTUNE", 2]:
			cat.bless({"greed": 0.35, "curse": 0.12}, FOR_THE_NIGHT, name_key, c)
		["BONE", 0]:
			cat.bless({"armor": 1.0}, FOR_THE_NIGHT, name_key, c)
		["BONE", 1]:
			cat.bless({"armor": 3.0, "max_hp": 30.0, "speed": -0.1}, FOR_THE_NIGHT, name_key, c)
			cat.heal(30.0)
		["BONE", 2]:
			cat.bless({"thorns": 1.0, "crit_chance": 0.08, "max_hp": -cat.max_hp * 0.2}, FOR_THE_NIGHT, name_key, c)
			cat.hp = minf(cat.hp, cat.max_hp)
		["MOON", 0]:
			cat.bless({"growth": 0.1}, FOR_THE_NIGHT, name_key, c)
		["MOON", 1]:
			cat.bless({"growth": 0.3, "curse": 0.15}, FOR_THE_NIGHT, name_key, c)
		["MOON", 2]:
			cat.rerolls_left += 1
			cat.banish_left += 1
		["CHAOS", 0]:
			cat.bless(CHAOS_STATS.pick_random(), FOR_THE_NIGHT, name_key, c)
		["CHAOS", 1]:
			# A coin toss with the gods of chaos.
			if randf() < 0.5:
				cat.bless({"amount": 1.0}, FOR_THE_NIGHT, name_key, c)
				main.hud.show_banner(tr("SHRINE_CHAOS_WON"), 3.0)
			else:
				_bleed(cat, 0.33)
				main.hud.show_banner(tr("SHRINE_CHAOS_LOST"), 3.0)
		["CHAOS", 2]:
			cat.bless({"might": 0.3, "area": 0.2, "curse": 0.2}, FOR_THE_NIGHT, name_key, c)
		["CURSED", 0]:
			cat.bless({"luck": 0.08}, FOR_THE_NIGHT, name_key, c)
		["CURSED", 1]:
			_summon_guards(CURSED_GUARDS)
		["CURSED", 2]:
			_big_curse = true
			_summon_guards(CURSED_GUARDS_BIG)


## Takes `share` of the cat's health, but never the last bit of it.
func _bleed(cat: Player, share: float) -> void:
	cat.hp = maxf(1.0, cat.hp - cat.max_hp * share)


func _summon_guards(count: int) -> void:
	for i in count:
		var guard: Enemy = main.spawner.spawn_guard(position + Vector2.from_angle(TAU * i / count + randf()) * 230.0)
		if guard != null:
			if _big_curse:
				guard.make_champion(GameData.champions.keys().pick_random())
				# Tougher the later in the night, but they give far less
				# experience than wild champions: the chest is the prize.
				var minutes: float = main.spawner.elapsed / 60.0
				guard.max_hp *= 1.6 + minutes * 0.12
				guard.hp = guard.max_hp
				guard.damage *= 1.25
				guard.xp *= 0.15
			else:
				guard.xp *= 0.4
			_guards.append(guard)


func _tick_guards(delta: float) -> void:
	_guard_t += delta
	for i in range(_guards.size() - 1, -1, -1):
		if not is_instance_valid(_guards[i]) or _guards[i].dead:
			_guards.remove_at(i)
	if not _guards.is_empty() and _guard_t < CURSED_LIMIT:
		return
	if _guard_t < CURSED_LIMIT:
		# A boss chest only once the night is well under way; early on the
		# great curse gives a plain chest and more gold.
		var boss_chest: bool = _big_curse and main.spawner.elapsed >= BOSS_CHEST_FROM
		main.pickups.spawn_named("chest", position, 1.0 if boss_chest else 0.0)
		for i in 16 if _big_curse else 8:
			main.pickups.spawn_named("coin", position + Vector2.from_angle(TAU * i / 8.0) * (22.0 if i < 8 else 34.0), 5.0)
		main.hud.show_banner(tr("SHRINE_CURSED_WON"), 3.5)
		print("SHRINE: CURSED cleared")
	_guards.clear()


func _draw() -> void:
	var c := color()
	var fade := 1.0 - clampf(_gone / 3.0, 0.0, 1.0)
	modulate.a = fade
	if not used:
		# The circle to stand in, and how far it has woken up.
		draw_circle(Vector2.ZERO, RADIUS, Color(c, 0.08 + 0.04 * sin(_t * 3.0)))
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 40, Color(c, 0.55), 2.0)
		if _wake > 0.0:
			draw_arc(Vector2.ZERO, RADIUS + 5.0, -PI * 0.5, -PI * 0.5 + TAU * _wake / WAKE_TIME, 40, c.lightened(0.3), 4.0)
	elif not _guards.is_empty():
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 40, Color(c, 0.35 + 0.25 * sin(_t * 8.0)), 3.0)
	# Stone plinth with a little cat statue and a glowing gem.
	draw_colored_polygon(Shapes.ellipse(Vector2(0, 14), 20, 6), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(-15, -2, 30, 16), OUTLINE)
	draw_rect(Rect2(-14, -1, 28, 14), Color("8c8478"))
	draw_rect(Rect2(-14, -1, 28, 3), Color("a8a094"))
	# A sitting stone cat: tail curled round, pointed ears, gem on the chest.
	var body := Color("6a6258") if used else Color("b8b0a4")
	var shade := body.darkened(0.25)
	draw_arc(Vector2(7, -4), 6.0, -PI * 0.5, PI * 0.6, 10, OUTLINE, 4.5)
	draw_arc(Vector2(7, -4), 6.0, -PI * 0.5, PI * 0.6, 10, shade, 2.5)
	draw_colored_polygon(Shapes.ellipse(Vector2(0, -9), 9.5, 11.5), OUTLINE)
	draw_colored_polygon(Shapes.ellipse(Vector2(0, -9), 8.5, 10.5), body)
	for side: float in [-1.0, 1.0]:
		var ear := PackedVector2Array([Vector2(side * 1.5, -28), Vector2(side * 6.5, -35), Vector2(side * 7, -25)])
		draw_colored_polygon(ear, OUTLINE)
		var inner := PackedVector2Array([Vector2(side * 2.5, -27.5), Vector2(side * 6, -33), Vector2(side * 6.2, -26)])
		draw_colored_polygon(inner, body)
	draw_circle(Vector2(0, -24), 7.0, OUTLINE)
	draw_circle(Vector2(0, -24), 6.0, body)
	# Closed eyes, a calm statue.
	draw_line(Vector2(-4, -24), Vector2(-1.5, -23.5), OUTLINE, 1.0)
	draw_line(Vector2(1.5, -23.5), Vector2(4, -24), OUTLINE, 1.0)
	draw_line(Vector2(-3, 0), Vector2(-3, -5), shade, 1.5)
	draw_line(Vector2(3, 0), Vector2(3, -5), shade, 1.5)
	var glow := 0.5 + 0.5 * sin(_t * 4.0)
	if not used:
		draw_circle(Vector2(0, -12), 6.0 + glow * 3.0, Color(c, 0.25))
		draw_circle(Vector2(0, -24), 14.0 + glow * 2.0, Color(c, 0.08))
	draw_circle(Vector2(0, -12), 3.5, c if not used else c.darkened(0.6))
	draw_circle(Vector2(-1, -13), 1.2, Color(1, 1, 1, 0.8 if not used else 0.2))
