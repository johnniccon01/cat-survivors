extends Node2D
## Wires the run together: player, enemies, pickups, spawner and HUD;
## handles level-ups, treasure chests, pause, restart and the three ways a run
## ends: death (half the gold, streak lost), escape through a cat flap (all
## gold, streak +1) or beating the final boss (all gold + bonus, streak +2).
##
## Level-ups and chests are "modals": they pause the game and are shown one
## after another from a queue.
##
## Debug flags (after `--` on the command line):
##   --bot              the cat plays on its own at 4x speed (takes the first
##                      offer, closes chests) and prints a summary at the end
##   --bot-time=SECONDS how long the bot plays (default 300, counted from the start minute)
##   --start-minute=N   start the run at minute N
##   --all-weapons      start with every base weapon
##   --show-levelup     the bot leaves the level-up screen open
##   --test-evolution   maxes the starting weapon + its partner passive, opens a chest, prints, quits
##   --quest=ID         starts quest ID next to the cat (LUNA, TIGER, RED_DOT...)
##   --cat=ID           play as cat ID (see data/cats.json)
##   --start-weapon=ID  start with weapon ID instead of the cat's own
##   --branch=W:B:R     give weapon W branch B at rank R (comma-separated list)
##   --levels=N         start with N random level-up picks (to test late game)
##   --extract          open a cat flap right away
##   --page             the map's diary page appears after 5 s
##   --champions        half of all regular enemies come as champions
##   --golden           the golden mouse shows up after 2 s
##   --tutorial         the bot gets the first-night tips (fresh profile)
##   --endless          the bot carries on into the endless night after a win
##   --endless-now      start straight in the endless night (tests)
##   --god              the cat can't be hurt (performance checks)
##   --drop-charm       drop a random charm next to the cat at the start
##   --catch-up         with --start-minute: level the cat like the dev panel's skip does
##   --traps            place one of every trap next to the cat

const HEART_DROP_CHANCE := 0.005
const COIN_DROP_CHANCE := 0.015
const VICTORY_GOLD := 150
## Share of the gold you keep when you die.
const DEATH_GOLD_KEPT := 0.5
## Cat flaps only open from this point of the run on.
const EXTRACT_FROM := 180.0
## A cat flap always opens around these minutes (±30 s), even without a
## boss or quest.
const FLAP_MINUTES := [5.0, 10.0, 15.0]
## Quiet time after a boss falls.
const BOSS_BREATHER := 12.0
## Charm drop chances.
const CHARM_CHANCE_ELITE := 0.06
const CHARM_CHANCE_BOSS := 0.35
const CHARM_CHANCE_QUEST := 0.2
## Rarity weights when a charm drops.
const CHARM_RARITY := [["common", 70.0], ["rare", 25.0], ["epic", 5.0]]
const HEART_DROP_AMOUNT := 15.0
## Treasure size odds: [items, weight]
const CHEST_ROLLS := [[1, 70.0], [3, 25.0], [5, 5.0]]
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const MAX_COMPANIONS := 1
const DEVIL_ID := "DEVIL_CAT"
## The devil shows up this long after the second angel save.
const DEVIL_DELAY := 4.0
const GOLDEN_MOUSE := "GOLDEN_MOUSE"
const HYPER_SPEED := 1.25
## Seconds between golden mouse visits (random in this range).
const GOLDEN_EVERY := [150.0, 260.0]
const GOLDEN_COINS := 10
## Share of the night after which the map's night track plays.
const NIGHT_MUSIC_AT := 0.5
## The devil moves this much faster than the cat's current speed.
const DEVIL_SPEED_OVER_CAT := 1.15

var kills := 0
var props_broken := 0
var companions: Array[Player] = []
var quests: QuestDirector
var quests_done := 0
var final_boss: Enemy
## Gold picked up this run; added to the profile when the run ends.
var run_gold := 0.0
var _shown_level := 1
## Bot runs log XP gained per minute to catch progression bugs.
var _xp_log: Dictionary = {}
var _xp_seen := 0.0
var _max_alive := 0
var _budget_log: Dictionary = {}
var bosses_killed := 0
var extraction: Extraction
## Charms picked up this run: only kept by escaping or winning.
var run_charms: Array[String] = []
var _flap_index := 0
var _flap_times: Array[float] = []
var _goal_check := 2.0
var chests_opened := 0

var _args := GameData.args()
var _bot := "--bot" in _args
var _bot_time := float(_arg("--bot-time=", "300"))
var _modals: Array[String] = []
var _in_modal := false
var _run_over := false
## Secret: times the angel cat saved you this run, and the devil it brings.
var angel_saves := 0
var devil: Enemy
var _devil_portal: DevilPortal
## True while the angel's rescue plays (the game is paused for it).
var _rescuing := false
## Test hook: --kill-cat-every=SECONDS knocks the cat out on a timer.
var _kill_every := float(_arg("--kill-cat-every=", "0"))
var _next_kill := INF
## Cats unlocked by beating a cat final boss, listed on the summary.
var _run_unlocks: Array[String] = []
## Quest book tracking for this run.
var _hearts := 0
var _distance := 0.0
var _last_pos := Vector2.ZERO
var _brink_t := 0.0
var _was_on_brink := false
var _final_started := 0.0
## The map's diary page: when it appears, the item on the floor, and whether
## the cat is carrying it.
var _page_time := INF
var _page_item: Pickup
var _has_page := false
## The map track playing now (day or night).
var _music_track := ""
var _golden_t: float = GOLDEN_EVERY[0]
## Game speed (Turbo challenge, 4x for the bot), restored after hit-stops.
var _base_time_scale := 1.0
## Endless night: whether it's on, and the gold already banked at the win.
var _endless := false
var _banked_gold := 0.0
var _last_end := ""
var _champion_seen := false
var _challenge_shown := false
## First night ever: short tips appear as things happen (see _tutorial).
var _tutorial := false
var _tips_shown: Dictionary = {}

@onready var player: Player = $Player
@onready var enemies: EnemyManager = $Enemies
@onready var pickups: Pickups = $Pickups
@onready var spawner: Spawner = $Spawner
@onready var hud: Hud = $HUD
@onready var night: CanvasModulate = $Night


func _ready() -> void:
	enemies.player = player
	pickups.player = player
	enemies.numbers = DamageNumbers.new()
	add_child(enemies.numbers)
	player.hurt.connect(hud.flash_hurt)
	spawner.setup(player, enemies)
	$Floor.theme = spawner.stage().get("theme", "apartment")
	if spawner.stage_id == "BASEMENT" and not Profile.is_unlocked("LUNA"):
		var intro := "STORY_BASEMENT_COLLAR" if Profile.has_flag("collar") else "STORY_BASEMENT_INTRO"
		hud.show_banner.call_deferred(tr(intro), 6.0)
	elif spawner.stage_id in ["GARDEN", "ROOFTOP"] and spawner.stage_id not in Profile.cleared_stages:
		hud.show_banner.call_deferred(tr("STORY_%s_INTRO" % spawner.stage_id), 6.0)
	spawner.skip_to(float(_arg("--start-minute=", "0")) * 60.0)
	if "--catch-up" in _args:
		_catch_up.call_deferred(spawner.elapsed)
	_bot_time += spawner.elapsed
	night.setup(spawner, player)
	for m: float in FLAP_MINUTES:
		_flap_times.append(m * 60.0 + randf_range(-30.0, 30.0))
	quests = QuestDirector.new()
	add_child(quests)
	quests.setup(self)
	quests.finished_quest.connect(func(ok: bool) -> void:
		quests_done += int(ok)
		if ok:
			Profile.add_stat("quests")
			_maybe_drop_charm(player.position + Vector2(16, 16), CHARM_CHANCE_QUEST)
			_open_extraction())
	# Only for brand-new players (no night played yet).
	_tutorial = Profile.get_stat("runs") == 0 and not Profile.has_flag("tutorial_done") and (not _bot or "--tutorial" in _args)
	if "--golden" in _args:
		_golden_t = 2.0
	if "--god" in _args:
		player.god = true
	if "--endless-now" in _args:
		_start_endless.call_deferred()
	if "--devil" in _args:
		summon_devil.call_deferred()
	var forced := _arg("--quest=", "")
	if forced != "":
		quests.force.call_deferred(forced)
	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.prop_broken.connect(_on_prop_broken)
	enemies.champion_killed.connect(_on_champion_killed)
	enemies.escaped.connect(func(enemy_id: String, _pos: Vector2) -> void:
		if enemy_id == GOLDEN_MOUSE:
			hud.show_banner(tr("GOLDEN_MOUSE_GONE"), 3.0))
	enemies.elite_killed.connect(func(pos: Vector2) -> void:
		pickups.spawn_named("coin", pos + Vector2(8, 0), 10.0)
		_maybe_drop_charm(pos + Vector2(-8, 0), CHARM_CHANCE_ELITE))
	pickups.charm_collected.connect(_on_charm_collected)
	pickups.heart_collected.connect(func() -> void: _hearts += 1)
	pickups.page_collected.connect(func() -> void:
		_has_page = true
		_page_item = null
		hud.show_banner(tr("PAGE_FOUND"), 4.0)
		# Test runs with --extract carry the page straight out.
		if _bot:
			print("BOT: page picked up at %.1f" % spawner.elapsed)
		if _bot and "--extract" in _args:
			if extraction != null:
				extraction.position = player.position + Vector2(120, 0)
			_open_extraction(true))
	_last_pos = player.position
	if not Profile.has_flag("page:" + spawner.stage_id):
		_page_time = 5.0 if "--page" in _args else randf_range(360.0, 660.0)
	pickups.gold_collected.connect(func(amount: float) -> void: run_gold += amount * player.stat("greed") * player.stat("curse"))
	pickups.chest_collected.connect(_queue_modal.bind("chest"))
	spawner.boss_spawned.connect(func(_id: String) -> void:
		Audio.play("roar", -2.0, 0.1)
		player.shake(5.0, 0.5)
		hud.show_banner(tr("BOSS_WARNING"))
		Audio.play("warning", -4.0, 0.0))
	spawner.stage_cleared.connect(_on_stage_cleared)
	spawner.final_boss_spawned.connect(_on_final_boss)
	spawner.event_started.connect(func(kind: String) -> void:
		player.shake(3.0, 0.3)
		hud.show_banner(tr("EVENT_%s" % kind.to_upper()), 2.5)
		Audio.play("warning", -6.0, 0.0))
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_queue_modal.bind("level"))
	player.xp_changed.connect(func() -> void: hud.update_xp(player))
	player.inventory_changed.connect(func() -> void: hud.update_inventory(player))
	hud.level_up.chosen.connect(_on_offer_chosen)
	hud.level_up.reroll_requested.connect(_on_reroll)
	player.revived.connect(_on_revived)
	hud.treasure.closed.connect(_next_modal)
	hud.resume_pressed.connect(func() -> void:
		get_tree().paused = false
		hud.show_pause(false))
	hud.give_up_pressed.connect(func() -> void:
		hud.show_pause(false)
		_end_run("death"))
	hud.update_xp(player)
	hud.update_inventory(player)
	if _bot:
		player.controller = "bot"
	_base_time_scale = (4.0 if _bot else 1.0) * (HYPER_SPEED if Profile.has_challenge("HYPER") else 1.0)
	Engine.time_scale = _base_time_scale
	for i in int(_arg("--levels=", "0")):
		Upgrades.apply(player, Upgrades.roll(player)[0])
	if OS.is_debug_build() and not _bot:
		var dev := DevPanel.new()
		dev.main = self
		add_child(dev)
	if "--traps" in _args:
		var i := 0
		for trap_id: String in GameData.traps:
			var trap := Trap.new()
			trap.position = player.position + Vector2(-90 + i * 60, 50)
			trap.setup(trap_id, self)
			add_child(trap)
			i += 1
	if "--pause" in _args:
		(func() -> void:
			get_tree().paused = true
			hud.show_pause(true)).call_deferred()
	if "--test-numbers" in _args:
		for i in 6:
			enemies.numbers.add(player.position + Vector2(-60 + i * 24, -20), 12.0 + i * 7, i % 2 == 1)
	if "--drop-charm" in _args:
		_maybe_drop_charm.call_deferred(player.position + Vector2(20, 0), 1.0)
	if "--extract" in _args:
		_open_extraction.call_deferred(true)
	if "--test-evolution" in _args:
		_test_evolution.call_deferred()
	Audio.play_music(_map_music())
	# --branch=WEAPON:BRANCH:RANK[,...] gives weapons a branch (tests).
	for spec: String in _arg("--branch=", "").split(",", false):
		var parts := spec.split(":")
		for r in int(parts[2]) if parts.size() > 2 else 1:
			player.choose_branch(parts[0], parts[1])
	if "--all-weapons" in _args:
		for id: String in GameData.weapons:
			if not GameData.weapons[id].get("evolved", false) and player.get_weapon(id) == null:
				player.add_weapon(id)


func _process(delta: float) -> void:
	if _kill_every > 0.0 and angel_saves < 2 and not _rescuing and not player.is_dead:
		if _next_kill == INF:
			_next_kill = spawner.elapsed + _kill_every
		elif spawner.elapsed >= _next_kill:
			_next_kill = spawner.elapsed + _kill_every
			player.take_damage(player.hp + 9999.0)
	# The devil is always a bit faster than the cat: it can't be outrun.
	if is_instance_valid(devil):
		devil.speed = maxf(float(GameData.enemies[DEVIL_ID]["speed"]), Player.BASE_SPEED * player.stat("speed") * DEVIL_SPEED_OVER_CAT)
	if is_instance_valid(devil) and devil.immortal and spawner.elapsed >= _devil_mortal_from():
		devil.immortal = false
		hud.show_banner(tr("DEVIL_WEAK"), 4.0)
	_track_run(delta)
	# Long-term goals can complete mid-run; announce them as they happen.
	_goal_check -= delta
	if _goal_check <= 0.0 and not _run_over:
		_goal_check = 2.0
		_announce_goals(Goals.check())
		_announce_quests(QuestBook.check())
	if OS.is_debug_build():
		hud.debug_extra = " · budget %d/%d (x%.2f)" % [roundi(enemies.budget_used), spawner.alive_cap(), spawner.intensity()]
	hud.update_stats(spawner.elapsed, kills, enemies.enemies.size())
	hud.update_gold(floori(run_gold), run_charms.size())
	if _bot:
		var minute := floori(spawner.elapsed / 60.0)
		_xp_log[minute] = _xp_log.get(minute, 0.0) + pickups.total_xp - _xp_seen
		_xp_seen = pickups.total_xp
		_max_alive = maxi(_max_alive, enemies.enemies.size())
		var minute_key := floori(spawner.elapsed / 60.0)
		if not _budget_log.has(minute_key):
			_budget_log[minute_key] = "%d/%d" % [roundi(enemies.budget_used), spawner.alive_cap()]
	hud.update_quest(quests.active)
	# Guaranteed cat flaps wait until a duel's fence is down.
	if _flap_index < _flap_times.size() and spawner.elapsed >= _flap_times[_flap_index] and enemies.arena.is_empty():
		_flap_index += 1
		_open_extraction(true)
	hud.update_extraction(extraction)
	hud.update_boss(final_boss if is_instance_valid(final_boss) and not final_boss.dead else null)
	if _bot and (spawner.elapsed >= _bot_time or (_run_over and not ("--endless" in _args and _last_end == "victory" and not _endless))):
		var weapons: Array[String] = []
		for w: Weapon in player.weapons.get_children():
			weapons.append("%s:%d%s" % [w.id, w.level, "" if w.branch == "" else "[%s%d]" % [w.branch, w.branch_rank]])
		if is_instance_valid(final_boss):
			print("BOT: final boss hp=%.0f/%.0f" % [final_boss.hp, final_boss.max_hp])
		print("BOT: time=%.1f level=%d kills=%d hp=%.0f/%.0f enemies=%d dead=%s" % [
			spawner.elapsed, player.level, kills, player.hp, player.max_hp,
			enemies.enemies.size(), player.is_dead])
		print("BOT: hurt=%.0f armor=%.1f regen=%.2f max_hp=%.0f" % [player.damage_taken, player.stat("armor"), player.stat("regen"), player.max_hp])
		print("BOT: music=%s golden_mice=%d champions=%d endless=%s endless_min=%.1f" % [Audio.get("_music_name"), Profile.get_stat("golden_mice"), Profile.get_stat("champions"), _endless, spawner.endless_minutes()])
		print("BOT: weapons=%s passives=%s props_broken=%d bosses_killed=%d chests=%d won=%s" % [
			weapons, player.passives, props_broken, bosses_killed, chests_opened, _run_over and not player.is_dead])
		print("BOT: damage numbers on screen=%d" % enemies.numbers._numbers.size())
		print("BOT: most enemies alive at once=%d, budget per minute (avg used/cap): %s" % [_max_alive, _budget_log])
		print("BOT: gold=%d streak=%d extraction_open=%s charms=%s owned=%s" % [floori(run_gold), Profile.streak, extraction != null, run_charms, Profile.charms])
		var per_minute: Array[String] = []
		for m: int in _xp_log:
			per_minute.append("%d:%d" % [m, roundi(_xp_log[m])])
		var kinds := {}
		var attracted := 0
		var far := 0
		for it in pickups.items:
			kinds[it.kind] = kinds.get(it.kind, 0) + 1
			attracted += int(it.attracted)
			far += int(it.position.distance_to(player.position) > 600.0)
		print("BOT: xp per minute ", " ".join(per_minute), " | pickups by kind=", kinds, " attracted=", attracted, " far=", far, " xp_count=", pickups._xp_count)
		print("BOT: quests_done=%d companions=%s" % [quests_done, companions.map(func(c: Player) -> String: return c.cat_id)])
		print("BOT: page carried=%s kept=%s questbook=%s" % [_has_page, Profile.has_flag("page:" + spawner.stage_id), Profile.questbook])
		var q := quests.active
		if q != null:
			print("BOT: active quest %s started=%s objective=%s" % [q.quest_id, q.started, q.objective()])
		get_tree().quit()


func _exit_tree() -> void:
	# Never leave the game slowed down by a hit-stop when the scene changes.
	if not _bot:
		Engine.time_scale = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if _in_modal or _rescuing or hud.settings.visible:
		return
	if _run_over:
		if event.is_action_pressed("endless") and _last_end == "victory" and not _endless:
			_start_endless()
			return
		if event.is_action_pressed("restart"):
			get_tree().paused = false
			get_tree().reload_current_scene()
		elif event.is_action_pressed("pause"):
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/character_select.tscn")
		return
	if event.is_action_pressed("mute") and get_tree().paused:
		Settings.toggle_mute()
		hud.show_pause(true)
	elif event.is_action_pressed("toggle_numbers") and get_tree().paused:
		Settings.toggle_damage_numbers()
		hud.show_pause(true)
	elif event.is_action_pressed("toggle_shake") and get_tree().paused:
		Settings.toggle_screen_shake()
		hud.show_pause(true)
	elif event.is_action_pressed("language") and get_tree().paused:
		Settings.cycle_language()
		hud.show_pause(true)
		hud.update_inventory(player)
	elif event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		hud.show_pause(get_tree().paused)


func _on_enemy_killed(id: String, pos: Vector2, xp: float) -> void:
	kills += 1
	Profile.add_stat("kills")
	Profile.add_stat("kills:" + id)
	pickups.spawn_xp(pos, xp)
	if GameData.enemies[id].get("final", false):
		bosses_killed += 1
		var cat: String = GameData.enemies[id].get("cat", "")
		if cat != "" and Profile.unlock(cat):
			_run_unlocks.append(cat)
		_on_stage_cleared()
		return
	if id == DEVIL_ID:
		Profile.set_flag("devil_slain")
		hud.show_banner(tr("DEVIL_SLAIN"), 5.0)
	if id == GOLDEN_MOUSE:
		Profile.add_stat("golden_mice")
		hud.show_banner(tr("GOLDEN_MOUSE_CAUGHT"), 3.0)
		Audio.play("squeak", 0.0, 0.0)
		Audio.play("chest", -2.0, 0.0)
		for i in GOLDEN_COINS:
			pickups.spawn_named("coin", pos + Vector2.from_angle(TAU * i / GOLDEN_COINS) * 14.0, 5.0)
		pickups.spawn_named("chest", pos, 0.0)
		return
	if GameData.enemies[id].get("boss", false):
		_boss_impact()
		bosses_killed += 1
		Profile.add_stat("bosses")
		pickups.spawn_named("chest", pos, 0.0)
		pickups.spawn_named("coin", pos + Vector2(14, 6), 25.0)
		_maybe_drop_charm(pos + Vector2(-14, 6), CHARM_CHANCE_BOSS)
		_open_extraction()
		spawner.calm_for(BOSS_BREATHER)
		hud.show_banner(tr("BREATHER"), 3.0)
	elif randf() < HEART_DROP_CHANCE * player.stat("luck"):
		pickups.spawn_named("heart", pos + Vector2(6, 0), HEART_DROP_AMOUNT)
	elif randf() < COIN_DROP_CHANCE * player.stat("luck"):
		pickups.spawn_named("coin", pos + Vector2(-6, 0), 1.0)


func _on_prop_broken(_id: String, pos: Vector2) -> void:
	props_broken += 1
	var entry: Dictionary = _weighted(GameData.loot.map(func(e: Dictionary) -> Array: return [e, float(e["weight"])]))
	pickups.spawn_named(entry["kind"], pos, float(entry.get("value", 0.0)))


func has_companion(cat_id: String) -> bool:
	return companions.any(func(c: Player) -> bool: return c.cat_id == cat_id)


## A rescued or defeated cat joins the run and is unlocked for good.
func cat_joined(cat_id: String, at: Vector2 = Vector2.INF) -> void:
	var cat_name := tr("CAT_%s_NAME" % cat_id)
	Audio.play("meow", -2.0)
	if Profile.unlock(cat_id) and not "--cat=" in " ".join(_args):
		hud.show_banner("%s\n%s" % [tr("QUEST_JOINED") % cat_name, tr("QUEST_UNLOCKED") % cat_name], 4.0)
	else:
		hud.show_banner(tr("QUEST_JOINED") % cat_name, 3.0)
	if companions.size() >= MAX_COMPANIONS or has_companion(cat_id):
		return
	var cat: Player = PLAYER_SCENE.instantiate()
	cat.controller = "follow"
	cat.cat_id = cat_id
	cat.leader = player
	cat.process_mode = Node.PROCESS_MODE_PAUSABLE
	cat.position = at if at != Vector2.INF else player.position + Vector2(20, 10)
	add_child(cat)
	move_child(cat, player.get_index())
	companions.append(cat)


## Spawns a rescued cat that has to be walked to safety.
func spawn_escort(cat_id: String, at: Vector2, hp: float) -> Player:
	var cat: Player = PLAYER_SCENE.instantiate()
	cat.controller = "escort"
	cat.cat_id = cat_id
	cat.leader = player
	cat.escort_hp = hp
	cat.process_mode = Node.PROCESS_MODE_PAUSABLE
	cat.position = at
	add_child(cat)
	move_child(cat, player.get_index())
	enemies.escorts.append(cat)
	return cat


func _queue_modal(kind: String) -> void:
	_modals.append(kind)
	if not _in_modal:
		_next_modal.call_deferred()


## Opens the next queued level-up or chest, or resumes the game.
func _next_modal() -> void:
	if _run_over:
		return
	if _modals.is_empty():
		_in_modal = false
		get_tree().paused = false
		return
	_in_modal = true
	get_tree().paused = true
	var kind: String = _modals.pop_front()
	if kind == "chest":
		Audio.play("chest", -2.0, 0.0)
		chests_opened += 1
		Profile.add_stat("chests")
		# Luck makes the bigger treasures more likely.
		var luck := player.stat("luck")
		var rolls := [[1, 70.0], [3, 25.0 * luck], [5, 5.0 * luck * luck]]
		var results := Upgrades.open_chest(player, _weighted(rolls))
		if _bot:
			_next_modal.call_deferred()
		else:
			hud.treasure.open(results)
		return
	Audio.play("levelup", -4.0, 0.0)
	Audio.play("meow", -9.0, 0.15)
	_level_burst()
	# Luck above 1.0 is the chance of a fourth card.
	var offers := Upgrades.roll(player, 4 if randf() < player.stat("luck") - 1.0 else 3)
	if _bot and not "--show-levelup" in _args:
		_on_offer_chosen(offers[0])
		return
	_shown_level = player.level - _modals.count("level")
	hud.level_up.open(_shown_level, offers, player.rerolls_left)


func _on_reroll() -> void:
	if player.rerolls_left <= 0:
		return
	player.rerolls_left -= 1
	Audio.play("magnet", -6.0, 0.0)
	hud.level_up.open(_shown_level, Upgrades.roll(player, 4 if randf() < player.stat("luck") - 1.0 else 3), player.rerolls_left)


## Revival power-up: back on your feet, and everything nearby is blown away.
func _on_revived() -> void:
	hud.show_banner(tr("REVIVED"), 3.0)
	Audio.play("levelup", 0.0, 0.0)
	for enemy in enemies.query_radius(player.position, 140.0):
		enemy.hit(0.0, enemy.position - player.position, 5.0)


func _on_offer_chosen(offer: Dictionary) -> void:
	Audio.play("select", -6.0, 0.0)
	Upgrades.apply(player, offer)
	_next_modal()


func _maybe_drop_charm(pos: Vector2, chance: float) -> void:
	if randf() >= chance * player.stat("luck"):
		return
	var rarity: String = _weighted(CHARM_RARITY)
	var pool: Array = GameData.charms.keys().filter(func(id: String) -> bool: return GameData.charms[id]["rarity"] == rarity)
	pickups.spawn_charm(pos, pool.pick_random())


func _on_charm_collected(charm_id: String) -> void:
	run_charms.append(charm_id)
	hud.show_banner(tr("CHARM_FOUND") % tr("CHARM_%s_NAME" % charm_id), 3.5)


## Opens a cat flap somewhere nearby, if none is open and it's not too
## early or too late in the run.
func _open_extraction(force: bool = false) -> void:
	if extraction != null or final_boss != null or _run_over:
		return
	if not force and spawner.elapsed < EXTRACT_FROM:
		return
	extraction = Extraction.new()
	extraction.main = self
	extraction.position = player.position + Vector2.from_angle(randf() * TAU) * randf_range(350.0, 500.0)
	extraction.escaped.connect(_end_run.bind("extract"))
	extraction.closed.connect(func() -> void:
		extraction = null
		hud.show_banner(tr("EXTRACT_CLOSED"), 2.5))
	add_child(extraction)
	hud.show_banner(tr("EXTRACT_OPEN"), 4.0)
	Audio.play("quest", -2.0, 0.0)


## Ends the run: "death", "extract" or "victory". Banks gold (with the
## streak bonus unless you died) and updates the streak.
func _end_run(kind: String) -> void:
	if _run_over:
		return
	_run_over = true
	_last_end = kind
	get_tree().paused = true
	Audio.stop_music()
	if _endless:
		_end_endless(kind)
		return
	var mult := Profile.streak_multiplier()
	var lines: Array[String] = []
	Profile.add_stat("runs")
	if _tutorial:
		Profile.set_flag("tutorial_done")
	Profile.set_stat_max("best_minutes", floori(spawner.elapsed / 60.0))
	Profile.set_stat_max("best_minutes:" + spawner.stage_id, floori(spawner.elapsed / 60.0))
	Profile.set_stat_max("best_level", player.level)
	Profile.set_stat_max("best_run_gold", floori(run_gold))
	# Quest book distance is in "metres" (16 px).
	Profile.add_stat("distance", floori(_distance / 16.0))
	_distance = 0.0
	if kind == "extract":
		Profile.add_stat("escapes")
	elif kind == "victory":
		Profile.add_stat("wins:" + spawner.stage_id)
		_victory_flags()
	var gold := 0
	match kind:
		"death":
			gold = floori(run_gold * DEATH_GOLD_KEPT)
			lines.append(tr("SUMMARY_GOLD_DEATH") % [gold, floori(run_gold)])
			if Profile.streak > 0:
				lines.append(tr("SUMMARY_STREAK_LOST") % Profile.streak)
			if not run_charms.is_empty():
				lines.append(tr("SUMMARY_CHARMS_LOST") % _charm_names())
			Profile.reset_streak()
			Audio.play("gameover", -2.0, 0.0)
			var cat_name := tr("CAT_%s_NAME" % player.cat_id)
			hud.show_game_over(spawner.elapsed, kills, tr("DEVIL_TOOK") % cat_name if player.killed_by_fatal else tr("GAME_OVER_TITLE") % cat_name)
		"extract":
			gold = floori(run_gold * mult)
			Profile.add_streak(1)
			lines.append(tr("SUMMARY_GOLD") % [gold, roundi((mult - 1.0) * 100.0)])
			lines.append(tr("SUMMARY_STREAK") % [Profile.streak, Profile.best_streak])
			Audio.play("victory", -2.0, 0.0)
			hud.show_extracted(spawner.elapsed, kills)
		"victory":
			for cat in _run_unlocks:
				lines.append(tr("SUMMARY_CAT_UNLOCKED") % tr("CAT_%s_NAME" % cat))
			gold = floori((run_gold + VICTORY_GOLD) * mult)
			Profile.add_streak(2)
			lines.append(tr("SUMMARY_GOLD") % [gold, roundi((mult - 1.0) * 100.0)])
			lines.append(tr("SUMMARY_STREAK") % [Profile.streak, Profile.best_streak])
			Audio.play("victory", -2.0, 0.0)
			hud.show_victory(kills)
			if Profile.clear_stage(spawner.stage_id):
				for wid: String in GameData.weapons:
					if GameData.weapons[wid].get("requires_stage", "") == spawner.stage_id:
						lines.append(tr("SUMMARY_WEAPON_UNLOCKED") % tr("WEAPON_%s_NAME" % wid))
				for id: String in GameData.stages:
					if GameData.stages[id].get("requires", "") == spawner.stage_id:
						hud.show_banner(tr("STAGE_UNLOCKED") % tr("STAGE_%s_NAME" % id), 6.0)
	if _has_page:
		if kind != "death":
			Profile.set_flag("page:" + spawner.stage_id)
			lines.append(tr("SUMMARY_PAGE_KEPT"))
		else:
			lines.append(tr("SUMMARY_PAGE_LOST"))
	if kind != "death" and not run_charms.is_empty():
		var refund := Profile.bank_charms(run_charms)
		lines.append(tr("SUMMARY_CHARMS_KEPT") % _charm_names())
		if refund > 0:
			lines.append(tr("SUMMARY_CHARMS_DUPES") % refund)
	if not Profile.challenges.is_empty():
		var bonus := floori(gold * (Profile.challenge_gold() - 1.0))
		gold += bonus
		lines.append(tr("SUMMARY_CHALLENGE") % [Profile.challenge_gold(), bonus])
	Profile.add_gold(gold)
	for id in Goals.check():
		lines.append(tr("GOAL_DONE") % [tr("GOAL_%s_NAME" % id), Goals.reward_text(id)])
	for entry in QuestBook.check():
		lines.append(QuestBook.completed_text(entry))
	lines.append(tr("SUMMARY_TOTAL") % Profile.gold)
	hud.show_summary(lines)


func _catch_up(seconds: float) -> void:
	var dev := DevPanel.new()
	dev.main = self
	var start := spawner.elapsed
	spawner.skip_to(0.0)
	dev._skip(seconds)
	spawner.skip_to(start)
	dev.free()


## The map's track: its night version from half way through the night.
func _map_music() -> String:
	var stage := spawner.stage()
	var day: String = stage.get("music", "music_apartment")
	if spawner.elapsed >= spawner.duration_minutes() * 60.0 * NIGHT_MUSIC_AT:
		return stage.get("music_night", day)
	return day


## Distance, time on the brink and the diary page, for the quest book.
func _track_run(delta: float) -> void:
	hud.update_page(_page_item.position if is_instance_valid(_page_item) else null)
	if _run_over or get_tree().paused or player.is_dead:
		return
	var step := player.position.distance_to(_last_pos)
	if step < 40.0:
		_distance += step
	_last_pos = player.position
	if player.hp < player.max_hp * 0.1:
		_brink_t += delta
		if _brink_t >= 30.0 and not _was_on_brink:
			_was_on_brink = true
			Profile.set_flag("brink")
	else:
		_brink_t = 0.0
	if not Profile.challenges.is_empty() and spawner.elapsed < 1.0 and not _challenge_shown:
		_challenge_shown = true
		hud.show_banner(tr("CHALLENGES_ON") % [", ".join(Profile.challenges.map(func(c: String) -> String: return tr("CHALLENGE_%s_NAME" % c))), Profile.challenge_gold()], 4.0)
	if _tutorial:
		_tutorial_tips()
	if not _champion_seen and int(Engine.get_process_frames()) % 30 == 0:
		for e in enemies.enemies:
			if e.champion != "":
				_champion_seen = true
				hud.show_banner(tr("CHAMPION_APPEARED") % tr("CHAMPION_%s_NAME" % e.champion), 3.0)
				break
	# Now and then a golden mouse scurries by.
	if final_boss == null and not _run_over:
		_golden_t -= delta
		if _golden_t <= 0.0:
			_golden_t = randf_range(GOLDEN_EVERY[0], GOLDEN_EVERY[1])
			enemies.spawn(GOLDEN_MOUSE, player.position + Vector2.from_angle(randf() * TAU) * 230.0)
			hud.show_banner(tr("GOLDEN_MOUSE_APPEARED"), 3.5)
			Audio.play("squeak", -2.0, 0.1)
	# Night falls: switch to the map's night track (not over a boss theme).
	if final_boss == null and not is_instance_valid(devil) and not _rescuing:
		var track := _map_music()
		if track != _music_track:
			_music_track = track
			Audio.crossfade_music(track, 3.0)
	if spawner.elapsed >= _page_time and final_boss == null:
		_page_time = INF
		_page_item = pickups.spawn_page(player.position + Vector2.from_angle(randf() * TAU) * randf_range(480.0, 640.0))
		hud.show_banner(tr("PAGE_APPEARED"), 4.0)
		Audio.play("quest", -2.0, 0.0)


## Tips for the very first night, each shown once when it becomes useful.
func _tutorial_tips() -> void:
	if get_tree().paused or _run_over:
		return
	var t := spawner.elapsed
	if t > 1.0:
		_tip("MOVE")
	if t > 7.0:
		_tip("WEAPONS")
	if t > 14.0 and pickups.items.size() > 0:
		_tip("XP")
	if player.level >= 2 and t > 20.0:
		_tip("LEVELS")
	if quests.active != null:
		_tip("QUEST")
	if extraction != null:
		_tip("FLAP")
	if t > 60.0:
		_tip("PAUSE")
	if _champion_seen:
		_tip("CHAMPION")


func _tip(id: String) -> void:
	if _tips_shown.has(id):
		return
	# One tip at a time: wait until the last one had a few seconds.
	for shown: float in _tips_shown.values():
		if Time.get_ticks_msec() / 1000.0 - shown < 5.0:
			return
	_tips_shown[id] = Time.get_ticks_msec() / 1000.0
	hud.show_banner(tr("TIP_%s" % id), 5.0)
	if _bot:
		print("BOT: tip ", id)


func _on_champion_killed(affix: String, pos: Vector2) -> void:
	Audio.play("sparkle", -6.0, 0.1)
	Profile.add_stat("champions")
	Profile.add_stat("champions:" + affix)
	pickups.spawn_named("coin", pos + Vector2(6, 0), 3.0)
	pickups.spawn_named("coin", pos + Vector2(-6, 0), 3.0)
	_maybe_drop_charm(pos + Vector2(0, 8), CHARM_CHANCE_ELITE * 0.5)


func _announce_quests(done: Array[Array]) -> void:
	for entry in done:
		hud.show_banner(QuestBook.completed_text(entry), 4.0)
		Audio.play("quest_done", -2.0, 0.0)
		var reward: Dictionary = QuestBook.lines()[entry[0]]["tiers"][entry[1] - 1]["reward"]
		if reward.has("cat"):
			hud.show_banner(tr("QUEST_UNLOCKED") % tr("CAT_%s_NAME" % reward["cat"]), 5.0)


func _announce_goals(ids: Array[String]) -> void:
	for id in ids:
		hud.show_banner(tr("GOAL_DONE") % [tr("GOAL_%s_NAME" % id), Goals.reward_text(id)], 4.0)
		Audio.play("quest_done", -2.0, 0.0)


func _charm_names() -> String:
	return ", ".join(run_charms.map(func(id: String) -> String: return tr("CHARM_%s_NAME" % id)))


func _on_player_died() -> void:
	if _angel_saves():
		return
	_end_run("death")


## Secret: on some maps, late in the run, a dying cat may be saved by an angel
## cat (a tiny chance, see "angel" in stages.json). Two saves in one run wake
## up the devil cat.
func _angel_saves() -> bool:
	# Nothing saves you from the devil.
	if player.killed_by_fatal:
		return false
	var angel: Dictionary = spawner.stage().get("angel", {})
	if angel.is_empty() or spawner.elapsed < float(angel["after_minute"]) * 60.0:
		return false
	if randf() >= float(_arg("--angel-chance=", str(angel["chance"]))):
		return false
	summon_angel()
	return true


## Plays the rescue (see AngelCat) with the game paused, then brings the cat
## back at full health.
func summon_angel() -> void:
	if _rescuing:
		return
	angel_saves += 1
	_rescuing = true
	if _bot:
		print("BOT: angel saves=%d" % angel_saves)
	Profile.set_flag("angel_seen")
	get_tree().paused = true
	Audio.pause_music(true)
	var fx := AngelCat.new()
	fx.position = player.position
	fx.cat_look = CatArt.look(player.cat_id)
	fx.facing = player.facing
	fx.revive_now.connect(_angel_revive)
	fx.finished.connect(_angel_done)
	add_child(fx)


func _angel_revive() -> void:
	player.revive(1.0, 4.0)
	# Enemies are frozen; shove the close ones away so the cat has room.
	for enemy in enemies.query_radius(player.position, 220.0):
		if not enemy.is_boss:
			enemy.position = player.position + (enemy.position - player.position).normalized() * 230.0
	# The devil can't be knocked back, so the angel sends it away instead.
	if is_instance_valid(devil):
		devil.position = player.position + (devil.position - player.position).normalized() * 380.0


func _angel_done() -> void:
	_rescuing = false
	Audio.pause_music(false)
	get_tree().paused = false
	player.shake(4.0, 0.5)
	if angel_saves >= 2 and not is_instance_valid(devil) and _devil_portal == null:
		get_tree().create_timer(DEVIL_DELAY, false).timeout.connect(summon_devil)


## The devil cat: chases you down and kills in a hit or two; it can't be hurt
## until the run reaches "mortal_from_minute".
func summon_devil() -> void:
	if _run_over or is_instance_valid(devil) or _devil_portal != null:
		return
	# A burning circle opens first; the devil climbs out when it's done.
	_devil_portal = DevilPortal.new()
	_devil_portal.position = player.position + Vector2.from_angle(randf() * TAU) * 140.0
	_devil_portal.opened.connect(_devil_rises)
	add_child(_devil_portal)
	hud.show_banner(tr("DEVIL_COMING"), 5.0)
	player.shake(6.0, 1.8)


func _devil_rises() -> void:
	Profile.set_flag("devil_met")
	devil = enemies.spawn(DEVIL_ID, _devil_portal.position)
	devil.immortal = spawner.elapsed < _devil_mortal_from()
	_devil_portal = null
	player.shake(10.0, 0.6)
	Audio.play_music(GameData.enemies[DEVIL_ID].get("music", "music_boss"))
	if _bot:
		print("BOT: devil summoned")


func _devil_mortal_from() -> float:
	return float(GameData.enemies[DEVIL_ID].get("mortal_from_minute", 30)) * 60.0


## Big boss deaths: strong shake and a tiny freeze so the moment lands.
func _boss_impact() -> void:
	player.shake(9.0, 0.6)
	if _bot:
		return
	Engine.time_scale = 0.08
	await get_tree().create_timer(0.14, true, false, true).timeout
	Engine.time_scale = _base_time_scale


## Expanding golden ring around the cat on level-up.
func _level_burst() -> void:
	var ring := RingWave.new()
	ring.enemies = enemies
	ring.position = player.position
	ring.max_radius = 60.0
	ring.expand_time = 0.35
	ring.damage = 0.0
	ring.knockback = 1.5
	add_child(ring)


## Special ways of winning, recorded as profile flags for the quest book.
func _victory_flags() -> void:
	var stage := spawner.stage_id
	Profile.set_flag("won_with:" + player.cat_id)
	if _hearts == 0:
		Profile.set_flag("win_no_hearts:" + stage)
	if player.weapon_count() <= 3:
		Profile.set_flag("win_few_weapons:" + stage)
	if _final_started > 0.0 and spawner.elapsed - _final_started <= 90.0:
		Profile.set_flag("fast_final:" + stage)
	if player.hp >= player.max_hp * 0.5:
		Profile.set_flag("win_healthy:" + stage)
	if _was_on_brink:
		Profile.set_flag("brink_win")
	for c in Profile.challenges:
		Profile.set_flag("win_challenge:" + c)
	if Profile.challenges.size() >= 3:
		Profile.set_flag("win_three_challenges")


func _on_final_boss(boss: Enemy) -> void:
	final_boss = boss
	_final_started = spawner.elapsed
	player.shake(8.0, 0.8)
	# The field was just cleared, so a running quest can't finish fairly.
	if quests.active != null:
		quests.active.fail()
	# No escaping from the final fight.
	if extraction != null:
		extraction.queue_free()
		extraction = null
	Audio.play("warning", 0.0, 0.0)
	Audio.play("roar", 2.0, 0.0)
	Audio.play_music(GameData.enemies[boss.id].get("music", "music_boss"))
	spawner.paused = true
	hud.show_banner(tr("FINAL_BOSS_WARNING") % tr("ENEMY_%s_NAME" % boss.id), 4.0)


## After a win, E keeps the night going: the final boss is gone, waves keep
## coming stronger and stronger, a boss drops in every few minutes. The win
## has been banked already; what you collect from now on is added on top.
func _start_endless() -> void:
	_endless = true
	_run_over = false
	_banked_gold = run_gold
	hud.hide_end_screens()
	final_boss = null
	spawner.start_endless()
	get_tree().paused = false
	Profile.add_stat("endless_runs")
	hud.show_banner(tr("ENDLESS_START"), 4.0)
	Audio.play("warning", -2.0, 0.0)
	_music_track = ""


## The end of an endless night: whatever it ends with, the extra gold is
## kept in full and the minutes count for records and quests.
func _end_endless(kind: String) -> void:
	var extra_minutes := floori(spawner.endless_minutes())
	Profile.set_stat_max("best_endless_minutes", extra_minutes)
	Profile.set_stat_max("best_minutes", floori(spawner.elapsed / 60.0))
	Profile.set_stat_max("best_level", player.level)
	Profile.add_stat("distance", floori(_distance / 16.0))
	var gold := floori(run_gold - _banked_gold)
	Profile.add_gold(gold)
	var lines: Array[String] = [tr("ENDLESS_SUMMARY") % [extra_minutes, gold]]
	if kind == "death":
		Audio.play("gameover", -2.0, 0.0)
		var cat_name := tr("CAT_%s_NAME" % player.cat_id)
		hud.show_game_over(spawner.elapsed, kills, tr("DEVIL_TOOK") % cat_name if player.killed_by_fatal else tr("GAME_OVER_TITLE") % cat_name)
	else:
		Audio.play("victory", -2.0, 0.0)
		hud.show_extracted(spawner.elapsed, kills)
	if _has_page and kind != "death":
		Profile.set_flag("page:" + spawner.stage_id)
		lines.append(tr("SUMMARY_PAGE_KEPT"))
	for id in Goals.check():
		lines.append(tr("GOAL_DONE") % [tr("GOAL_%s_NAME" % id), Goals.reward_text(id)])
	for entry in QuestBook.check():
		lines.append(QuestBook.completed_text(entry))
	lines.append(tr("SUMMARY_TOTAL") % Profile.gold)
	Profile.save()
	hud.show_summary(lines)


func _on_stage_cleared() -> void:
	_end_run("victory")
	if _bot and "--endless" in _args and not _endless:
		_start_endless.call_deferred()


## Picks from [[value, weight], ...] pairs.
func _weighted(pairs: Array) -> Variant:
	var total := 0.0
	for p: Array in pairs:
		total += p[1]
	var roll := randf() * total
	for p: Array in pairs:
		roll -= p[1]
		if roll <= 0.0:
			return p[0]
	return pairs[-1][0]


func _arg(prefix: String, default: String) -> String:
	for a: String in _args:
		if a.begins_with(prefix):
			return a.trim_prefix(prefix)
	return default


func _test_evolution() -> void:
	# Works for any cat: max out its starting weapon and add the partner passive.
	var w := player.weapons.get_child(0) as Weapon
	while w.level < w.max_level():
		w.level_up()
	player.add_passive(w.data["evolve"]["with"])
	print("TEST: evolution ready: ", Upgrades.find_evolution(player))
	print("TEST: chest: ", Upgrades.open_chest(player, 3))
	await get_tree().process_frame
	var ids: Array[String] = []
	for x: Weapon in player.weapons.get_children():
		ids.append("%s:%d" % [x.id, x.level])
	print("TEST: weapons after: ", ids)
	print("TEST: offers: ", Upgrades.roll(player, 20).map(func(o: Dictionary) -> String: return o["id"]))
	get_tree().quit()
