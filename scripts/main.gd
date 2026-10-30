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
##   --show-choice      the bot leaves story and shrine choices open
##   --test-evolution   maxes the starting weapon + its partner passive, opens a chest, prints, quits
##   --quest=ID         starts quest ID next to the cat (LUNA, TIGER, RED_DOT...)
##   --teleport=X,Y     moves the cat there at the start ("trail": to the end of
##                      the map's secret blood trail; tests for secrets)
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
##   --dev-endless      the dev panel's "Endless night now" (skips the night, tests)
##   --god              the cat can't be hurt (performance checks)
##   --perf             print frame timings every 2 s
##   --bot-speed=N      game speed while the bot plays (default 4)
##   --drop-charm       drop a random charm next to the cat at the start
##   --catch-up         with --start-minute: level the cat like the dev panel's skip does
##   --traps            place one of every trap next to the cat
##   --choice=N         the bot answers story choices with option N
##   --daily            play today's daily night (map and challenges by date)
##   --seed=N           fixed random seed (same map layout; performance checks)
##   --no-vsync         frame rate not capped by the monitor (performance checks)
##   --shot=SECONDS     save a screenshot to user://shot_N.png every SECONDS
##   --strong           dev panel: every weapon that fits and 40 level-ups
##   --dev-boss=ID      dev panel: clear the field and fight boss ID (progress not saved)
##   --dev-panel        open the dev panel (F1) right away
##   --no-arena         no arena or rings of enemies in final boss fights
##   --boss-hp=F        with --dev-boss: the boss starts at this share of its health
##   --items-test       check the gear system (tools/items_check.gd)
##   --item-chance=F    a boss or elite drops gear with this chance
##   --legendary-chance=F  a final boss drops its legendary with this chance
##   --gear=ID,rare     own and wear these legendaries / random items of a rarity
##   --drop-item=ID     start the run with this legendary (or a random item of a rarity) in the bag
##   --expect=a,b       test runs: fail unless these BotLog events happen (--expect-not=)
##   --boss-rush        dev panel: every boss one after another
##   --dev-quest=ID     dev panel: start quest ID, or CHAIN#N for step N of a story chain
##   --dev-quest-all    dev panel: start every quest and story step in turn, 5 s each (tests)
##   --dev-next-terrain=N  dev panel: press "Terrain" N times (tests)

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
const CHARM_CHANCE_ELITE := 0.03
const CHARM_CHANCE_BOSS := 0.35
## Gear (see Items): a wave boss drops an item this often, an elite this
## often (both x luck). A final boss drops its own legendary with
## LEGENDARY_CHANCE (x luck, at most LEGENDARY_CHANCE_MAX), only while you
## don't own it yet; otherwise it drops a rare item.
const ITEM_CHANCE_BOSS := 0.5
const ITEM_CHANCE_ELITE := 0.06
const LEGENDARY_CHANCE := 0.3
const LEGENDARY_CHANCE_MAX := 0.45
const CHARM_CHANCE_QUEST := 0.15
## Rarity weights when a charm drops.
const CHARM_RARITY := [["common", 70.0], ["rare", 25.0], ["epic", 5.0]]
const HEART_DROP_AMOUNT := 15.0
## Treasure size odds: [items, weight]
const CHEST_ROLLS := [[1, 70.0], [3, 25.0], [5, 5.0]]
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const MAX_COMPANIONS := 1
const DEVIL_ID := "DEVIL_CAT"
## Angel: a dying cat with no lives left may be saved once per run, from
## ANGEL_AFTER_MINUTE on; every life the cat already used makes it likelier
## (3 used = 10 %). Dying again after that brings Death (the devil cat) in
## half the cases: the cat gets up once more, but Death hunts it.
const ANGEL_AFTER_MINUTE := 5.0
const ANGEL_CHANCE := 0.01
const ANGEL_CHANCE_PER_LIFE := 0.03
const DEATH_AFTER_ANGEL := 0.5
const GOLDEN_MOUSE := "GOLDEN_MOUSE"
const HYPER_SPEED := 1.25
## Seconds between golden mouse visits (random in this range).
const GOLDEN_EVERY := [150.0, 260.0]
const GOLDEN_COINS := 10
## Share of the night after which the map's night track plays.
const NIGHT_MUSIC_AT := 0.5
## The devil moves this much faster than the cat's current speed.
const DEVIL_SPEED_OVER_CAT := 1.25
## Winning on the cat's home map adds this share of the gold.
const HOME_WIN_GOLD := 0.25
## Full moon: a boss comes every this many seconds, final bosses with this
## share of their health.
const MOON_BOSS_EVERY := 180.0
const MOON_FINAL_HP := 0.4
## A hunting nemesis that is another map's final boss has this share of its health.
const NEMESIS_HUNT_FINAL_HP := 0.3

var kills := 0
var props_broken := 0
var companions: Array[Player] = []
var quests: QuestDirector
var quests_done := 0
var final_boss: Enemy
## A boss test from the dev panel: a final boss falling doesn't end the night.
var dev_test := false
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
## Quality (1-4) of each charm in run_charms.
var run_charm_quality: Array[int] = []
## Items found this run: kept on an escape or a win; on a death the well
## saves only the best one.
var run_items: Array = []
## Chance of each charm quality when one is picked up (better with luck).
const CHARM_QUALITY := [[1, 60.0], [2, 27.0], [3, 10.0], [4, 3.0]]
var _flap_index := 0
var _flap_times: Array[float] = []
var _goal_check := 2.0
var chests_opened := 0

var _args := GameData.args()
var _bot := "--bot" in _args
## Dev builds: a death asks whether to revive (see _dev_revive_asks).
var dev_revive := false
## --perf: prints frame timings every 2 s (real time).
var _perf := "--perf" in _args
var _perf_t := 2.0
## Effect saver: seconds the frame rate has been low (or fine again).
var _slow_t := 0.0
## Run log for slowdowns: every 10 s (real time) one line with fps, the crowd
## and which kinds of nodes fill the world, e.g. a pile of toy mice. Written
## to user://perf.log, overwritten each run.
var _perf_log: FileAccess
var _perf_log_t := 10.0
## Longest frame (ms) since the last perf.log line: shows hitches.
var _worst_frame := 0.0
var _fast_t := 0.0
const SLOW_FPS := 40
const SLOW_FOR := 4.0
const FAST_FPS := 56
const FAST_FOR := 30.0
var _bot_time := float(_arg("--bot-time=", "300"))
var _modals: Array[String] = []
var _in_modal := false
var _run_over := false
## Secret: times the angel cat saved you this run, and the devil it brings.
## lives_used counts the revives the cat's own items gave it.
var lives_used := 0
var angel_saves := 0
var devil: Enemy
var _devil_portal: Node2D
## Death can be hurt from this second of the night (5 minutes after it came).
var _devil_mortal_at := INF
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
## Artifact timers (hourglass, magnet core) and their strength.
## A shrine turns up after SHRINE_FIRST seconds, then every SHRINE_EVERY.
const SHRINE_FIRST := 70.0
const SHRINE_EVERY := [80.0, 120.0]
## Chance (times luck) that a boss chest gives all three upgrades.
const BOSS_CHEST_JACKPOT := 0.05
## Enemy health while a story ally walks with you.
const ALLY_HP_MULT := 1.25
## Bosses with at least this much base health drop a great chest.
const STRONG_BOSS_HP := 2500.0
const HOURGLASS_RADIUS := 360.0
const HOURGLASS_SECONDS := 3.0
const THORN_RADIUS := 80.0
const THORN_DAMAGE := 20.0
var _freeze_t := 0.0
var _rex_calm := false
## Endless minutes already announced.
var _endless_shown := 0
## The story choices waiting in the modal queue (the first one is on screen).
var _choices: Array[Dictionary] = []
var _choice: Dictionary = {}
var _magnet_t := 0.0
var _page_item: Pickup
var _has_page := false
## The map track playing now (day or night).
var _music_track := ""
## The day track picked for this run (see _map_music).
var _day_music := ""
var _darkness_shown := false
## The level-up cards on screen (rerolls and banishes replace them).
var _shown_offers: Array[Dictionary] = []
var _golden_t: float = GOLDEN_EVERY[0]
## Shrines: the one on the map now, and when the next one turns up.
var shrine: Shrine
var _shrine_t: float = SHRINE_FIRST
## Game speed (Turbo challenge, 4x for the bot), restored after hit-stops.
var _base_time_scale := 1.0
## Endless night: whether it's on, and the gold already banked at the win.
var _endless := false
var _banked_gold := 0.0
var _last_end := ""
var _champion_seen := false
var _challenge_shown := false
var _report_shown := false
## When (seconds into the night) your nemesis comes hunting, or -1.
var _nemesis_at := -1.0
## Summary lines about nemeses from this night.
var _nemesis_lines: Array[String] = []
var _nemesis_planned := false
var _nemesis_boss: Enemy
## Full moon night: bosses still to come, and whether home is set up yet.
## Territory flags of tonight's map, and how many are taken.
var _flags: Array[TerritoryFlag] = []
var _flags_taken := 0
var _flags_placed := false
## Night trip: the gates still to come (seconds) and the maps passed so far.
const TRIP_GATES := [420.0, 840.0]
var _trip_gates: Array = []
var _trip_route: Array[String] = []
var _moon_bosses: Array[String] = []
var _moon_ready := false
var _moon_next := MOON_BOSS_EVERY
var _home_shown := false
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
	Sprites.warm()
	enemies.player = player
	pickups.player = player
	enemies.numbers = DamageNumbers.new()
	add_child(enemies.numbers)
	player.hurt.connect(hud.flash_hurt)
	player.hurt.connect(_on_player_hurt)
	spawner.setup(player, enemies)
	$Floor.theme = spawner.stage().get("theme", "apartment")
	var terrain_kind: String = _arg("--terrain=", spawner.stage().get("terrain", ""))
	if terrain_kind != "":
		var terrain := Terrain.new()
		terrain.setup(terrain_kind, self)
		add_child(terrain)
		move_child(terrain, $Floor.get_index() + 1)
	_setup_hazard()
	if spawner.stage_id == "BASEMENT" and not Profile.is_unlocked("LUNA"):
		var intro := "STORY_BASEMENT_COLLAR" if Profile.has_flag("collar") else "STORY_BASEMENT_INTRO"
		hud.show_banner.call_deferred(tr(intro), 6.0)
	elif spawner.stage_id not in ["LIVING_ROOM", "BASEMENT"] and spawner.stage_id not in Profile.cleared_stages:
		hud.show_banner.call_deferred(tr("STORY_%s_INTRO" % spawner.stage_id), 6.0)
	spawner.skip_to(float(_arg("--start-minute=", "0")) * 60.0)
	if "--catch-up" in _args:
		_catch_up.call_deferred(spawner.elapsed)
	_bot_time += spawner.elapsed
	night.setup(spawner, player)
	_start_weather()
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
	if _arg("--shrine=", "") != "":
		_shrine_t = 1.0
	if "--god" in _args:
		player.god = true
	if "--endless-now" in _args:
		_start_endless.call_deferred()
	if "--items-test" in _args:
		var check: Node = load("res://tools/items_check.gd").new()
		check.run(self)
		check.free()
	if "--devil" in _args:
		summon_devil.call_deferred()
	var forced := _arg("--quest=", "")
	if forced != "":
		quests.force.call_deferred(forced)
	var teleport := _arg("--teleport=", "")
	if teleport != "":
		var to: Vector2 = quests.trail_end() if teleport == "trail" else Vector2(teleport.get_slice(",", 0).to_float(), teleport.get_slice(",", 1).to_float())
		player.position = to
	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.prop_broken.connect(_on_prop_broken)
	enemies.champion_killed.connect(_on_champion_killed)
	enemies.escaped.connect(func(enemy_id: String, _pos: Vector2) -> void:
		if enemy_id == GOLDEN_MOUSE:
			hud.show_banner(tr("GOLDEN_MOUSE_GONE"), 3.0))
	enemies.elite_killed.connect(func(pos: Vector2) -> void:
		pickups.spawn_named("coin", pos + Vector2(8, 0), 10.0)
		_maybe_drop_charm(pos + Vector2(-8, 0), CHARM_CHANCE_ELITE)
		_maybe_find_item(ITEM_CHANCE_ELITE))
	pickups.charm_collected.connect(_on_charm_collected)
	pickups.magnet_pulled.connect(func(count: int, xp: float) -> void:
		if count > 0:
			hud.show_banner(tr("MAGNET_PULLED") % [count, roundi(xp)], 2.5))
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
	pickups.chest_collected.connect(func(value: float) -> void: _queue_modal("great_chest" if value >= 2.0 else "boss_chest" if value >= 1.0 else "chest"))
	spawner.boss_spawned.connect(func(_id: String) -> void:
		Audio.play("roar", -2.0, 0.1)
		player.shake(5.0, 0.5)
		hud.show_banner(tr("BOSS_WARNING"))
		Audio.play("warning", -4.0, 0.0))
	spawner.stage_cleared.connect(_on_stage_cleared)
	spawner.final_boss_spawned.connect(_on_final_boss)
	enemies.boss_event.connect(_on_boss_event)
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
	hud.level_up.banish_requested.connect(_on_banish)
	player.revived.connect(_on_revived)
	hud.treasure.closed.connect(_next_modal)
	hud.choice.chosen.connect(func(index: int) -> void:
		var callback: Callable = _choice["callback"]
		callback.call(index)
		_next_modal())
	MapFeature.place_all(self, spawner.stage_id, player.position)
	hud.resume_pressed.connect(func() -> void:
		get_tree().paused = false
		hud.show_pause(false))
	hud.discard_pressed.connect(_ask_discard)
	hud.give_up_pressed.connect(func() -> void:
		hud.show_pause(false)
		_end_run("death"))
	hud.update_xp(player)
	hud.update_inventory(player)
	if _bot:
		player.controller = "bot"
	_base_time_scale = (float(_arg("--bot-speed=", "4")) if _bot else 1.0) * (HYPER_SPEED if Profile.has_challenge("HYPER") else 1.0)
	Engine.time_scale = _base_time_scale
	for i in int(_arg("--levels=", "0")):
		Upgrades.apply(player, Upgrades.roll(player)[0])
	var dev_flags := ["--strong", "--boss-rush", "--dev-quest-all", "--dev-panel", "--dev-endless"].any(func(f: String) -> bool: return f in _args) or _arg("--dev-boss=", "") != "" or _arg("--dev-next-terrain=", "") != "" or _arg("--dev-quest=", "") != ""
	if OS.is_debug_build() and (not _bot or dev_flags):
		var dev := DevPanel.new()
		dev.main = self
		add_child(dev)
		_dev_start.call_deferred(dev)
		dev_revive = true
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
	# `--drop-item=RAT_CROWN` / `--drop-item=rare`: the cat starts with that
	# item in its bag (tests).
	var drop_item := _arg("--drop-item=", "")
	if drop_item != "":
		_find_item.call_deferred(Items.legendary(drop_item) if GameData.items["legendaries"].has(drop_item) else Items.roll(1.0, drop_item))
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


## Turns the effect saver on while the game runs slowly for a few seconds
## (big late-game crowds on a laptop) and off again once it's smooth.
func _watch_frame_rate(real_delta: float) -> void:
	if get_tree().paused:
		return
	var fps := Engine.get_frames_per_second()
	_slow_t = _slow_t + real_delta if fps < SLOW_FPS else 0.0
	_fast_t = _fast_t + real_delta if fps >= FAST_FPS else 0.0
	if not Settings.auto_low and _slow_t > SLOW_FOR:
		Settings.auto_low = true
		if _perf:
			print("PERF: effect saver on")
	elif Settings.auto_low and _fast_t > FAST_FOR:
		Settings.auto_low = false


func _write_perf_log(real_delta: float) -> void:
	_perf_log_t -= real_delta
	if not get_tree().paused:
		_worst_frame = maxf(_worst_frame, real_delta * 1000.0)
	if _perf_log_t > 0.0 or get_tree().paused:
		return
	_perf_log_t = 10.0
	if _perf_log == null:
		_perf_log = FileAccess.open("user://perf.log", FileAccess.WRITE)
		if _perf_log == null:
			return
		_perf_log.store_line("stage=%s cat=%s" % [Profile.selected_stage, player.cat_id])
	var kinds: Dictionary = {}
	for node in player.get_parent().get_children():
		var s: Script = node.get_script()
		var kind: String = s.resource_path.get_file().get_basename() if s != null else node.get_class()
		kinds[kind] = kinds.get(kind, 0) + 1
	var top: Array = kinds.keys()
	top.sort_custom(func(a: String, b: String) -> bool: return kinds[a] > kinds[b])
	var parts: PackedStringArray = []
	for k: String in top.slice(0, 6):
		parts.append("%s=%d" % [k, kinds[k]])
	var arms: PackedStringArray = []
	for w: Node in player.weapons.get_children():
		if w is Weapon:
			arms.append("%s%d" % [w.id, w.level])
	var worst := _worst_frame
	_worst_frame = 0.0
	_perf_log.store_line("t=%d fps=%d worst=%.0fms proc=%.1fms draws=%d nodes=%d enemies=%d calm=%s saver=%s | %s | %s" % [
		int(spawner.elapsed), Engine.get_frames_per_second(), worst,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT), enemies.enemies.size(),
		Enemy.calm, Settings.effects_scale() < 1.0, " ".join(arms), " ".join(parts)])
	_perf_log.flush()


## --shot=SECONDS: saves a screenshot to user://shot_<n>.png every SECONDS
## (real time), for checking how things look.
var _shot_every := float(_arg("--shot=", "0"))
var _shot_t := 0.0
var _shot_n := 0


func _take_shots(real_delta: float) -> void:
	if _shot_every <= 0.0:
		return
	_shot_t += real_delta
	if _shot_t >= _shot_every:
		_shot_t = 0.0
		_shot_n += 1
		get_viewport().get_texture().get_image().save_png("user://shot_%d.png" % _shot_n)


func _process(delta: float) -> void:
	_watch_frame_rate(delta / maxf(Engine.time_scale, 0.01))
	_write_perf_log(delta / maxf(Engine.time_scale, 0.01))
	_take_shots(delta / maxf(Engine.time_scale, 0.01))
	if _perf:
		_perf_t -= delta / Engine.time_scale
		if _perf_t <= 0.0:
			_perf_t = 2.0
			print("PERF: fps=%d process=%.1fms physics=%.1fms draw_calls=%d objects=%d nodes=%d enemies=%d" % [
				Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
				enemies.enemies.size()])
	if _kill_every > 0.0 and not is_instance_valid(devil) and not _rescuing and not player.is_dead:
		if _next_kill == INF:
			_next_kill = spawner.elapsed + _kill_every
		elif spawner.elapsed >= _next_kill:
			_next_kill = spawner.elapsed + _kill_every
			player.take_damage(player.hp + 9999.0)
	# The devil is always a bit faster than the cat: it can't be outrun.
	if is_instance_valid(devil):
		devil.speed = maxf(float(GameData.enemies[DEVIL_ID]["speed"]), Player.BASE_SPEED * player.stat("speed") * DEVIL_SPEED_OVER_CAT)
	if is_instance_valid(devil) and devil.immortal and spawner.elapsed >= _devil_mortal_at:
		devil.immortal = false
		hud.show_banner(tr("DEVIL_WEAK"), 4.0)
	_track_run(delta)
	# Long-term goals can complete mid-run; announce them as they happen.
	_goal_check -= delta
	if _goal_check <= 0.0 and not _run_over:
		_goal_check = 2.0
		_announce_goals(Goals.check())
		for id in Achievements.check():
			hud.show_banner(tr("ACH_EARNED") % tr("ACH_%s_NAME" % id), 4.0)
			Audio.play("sparkle", -2.0, 0.0)
		_announce_quests(QuestBook.check())
	if OS.is_debug_build():
		hud.debug_extra = " · budget %d/%d (x%.2f)" % [roundi(enemies.budget_used), spawner.alive_cap(), spawner.intensity()]
	hud.update_stats(spawner.elapsed, kills, enemies.enemies.size())
	hud.update_gold(floori(run_gold), run_charms.size())
	hud.update_blessings(player)
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
		BotLog.verify()
		if is_instance_valid(final_boss):
			print("BOT: final boss hp=%.0f/%.0f" % [final_boss.hp, final_boss.max_hp])
		if is_instance_valid(_nemesis_boss) and not _nemesis_boss.dead:
			print("NEMESIS: still alive at %d %% health, %d px away" % [roundi(_nemesis_boss.hp / _nemesis_boss.max_hp * 100.0), roundi(_nemesis_boss.position.distance_to(player.position))])
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
		print("BOT: run items=%s owned items=%d worn=%s" % [run_items.map(func(i: Dictionary) -> String: return "%s:%s" % [i["base"], i["rarity"]]), Profile.items.size(), Profile.equipped_items])
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
		print("BOT: chains=%s" % Profile.chains)
		for c: Player in companions:
			print("BOT: companion %s weapons=%s" % [c.cat_id, c.weapons.get_children().map(func(w: Node) -> String: return "%s:%d" % [w.get("id"), w.get("level")])])
		print("BOT: page carried=%s kept=%s questbook=%s" % [_has_page, Profile.has_flag("page:" + spawner.stage_id), Profile.questbook])
		var q := quests.active
		if q != null:
			print("BOT: active quest %s started=%s objective=%s" % [q.quest_id, q.started, q.objective()])
		get_tree().quit()


func _exit_tree() -> void:
	# The daily night ends with its scene (restart, menu): your own challenges
	# come back.
	Profile.end_daily()
	Profile.end_report()
	Profile.end_moon()
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
		# Texts that only change on an event, now in the new language.
		hud.update_xp(player)
		hud.update_blessings(player)
	elif event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		hud.show_pause(get_tree().paused)


func _on_enemy_killed(id: String, pos: Vector2, xp: float) -> void:
	kills += 1
	Profile.add_stat("kills")
	Profile.add_stat("kills:" + id)
	pickups.spawn_xp(pos, xp)
	if GameData.enemies[id].get("boss", false) or GameData.enemies[id].get("final", false):
		_nemesis_revenge(id, pos)
	# Only this map's own final boss ends the night (a hunting nemesis from
	# another map is just a boss here).
	if GameData.enemies[id].get("final", false) and id == GameData.stages[spawner.stage_id].get("final_boss", "") and not dev_test:
		bosses_killed += 1
		var cat: String = GameData.enemies[id].get("cat", "")
		if cat != "" and Profile.unlock(cat):
			_run_unlocks.append(cat)
		ChainStep.final_defeated(self, spawner.stage_id)
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
		Profile.add_stat("bosses_cat:" + player.cat_id)
		# Strong bosses drop a great chest: all three upgrades, more gold.
		var great := float(GameData.enemies[id].get("hp", 0)) >= STRONG_BOSS_HP
		pickups.spawn_named("chest", pos, 2.0 if great else 1.0)
		pickups.spawn_named("coin", pos + Vector2(14, 6), 60.0 if great else 25.0)
		_maybe_drop_charm(pos + Vector2(-14, 6), CHARM_CHANCE_BOSS)
		var legend := Items.legendary_of(id)
		if legend != "":
			_final_boss_loot(legend)
		else:
			# In a dev test every boss leaves an item, so loot can be tried out.
			_maybe_find_item(1.0 if dev_test else ITEM_CHANCE_BOSS)
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


## A cat won over in a story asks to come along; with him the enemies are tougher.
func offer_ally(cat_id: String) -> void:
	var cat_name := tr("CAT_%s_NAME" % cat_id)
	ask_choice(tr("ALLY_OFFER_TITLE") % cat_name, tr("ALLY_OFFER_ASK"),
			[tr("ALLY_OFFER_YES") % cat_name, tr("ALLY_OFFER_NO")],
			func(index: int) -> void:
				if index == 0:
					spawner.ally_hp_mult = ALLY_HP_MULT
					cat_joined(cat_id))


## Spawns a rescued cat that has to be walked to safety.
func spawn_escort(cat_id: String, at: Vector2, hp: float) -> Player:
	var cat: Player = PLAYER_SCENE.instantiate()
	cat.controller = "escort"
	cat.cat_id = cat_id
	cat.leader = player
	# Enemies grow through the night, and so does the cat being walked home.
	cat.escort_hp = hp * (1.0 + spawner.elapsed / 60.0 * 0.2)
	cat.process_mode = Node.PROCESS_MODE_PAUSABLE
	cat.position = at
	add_child(cat)
	move_child(cat, player.get_index())
	enemies.escorts.append(cat)
	return cat


## A story choice (pauses like a level-up); `callback` gets the answer's index
## (-1 when `cancel` shows a back button and it is used).
func ask_choice(title: String, prompt: String, options: Array, callback: Callable, cancel: bool = false) -> void:
	_choices.append({"title": title, "prompt": prompt, "options": options, "callback": callback, "cancel": cancel})
	_queue_modal("choice")


func _queue_modal(kind: String) -> void:
	_modals.append(kind)
	if not _in_modal:
		# Claimed right away, so a shrine and a level-up in the same frame
		# open one after the other, not both at once.
		_in_modal = true
		get_tree().paused = true
		_next_modal.call_deferred()


## Opens the next queued level-up or chest, or resumes the game.
func _next_modal() -> void:
	if _run_over:
		# The run ended from a choice (or with one queued): let the game-over
		# screen take keys again.
		_in_modal = false
		_modals.clear()
		_choices.clear()
		return
	if _modals.is_empty():
		_in_modal = false
		get_tree().paused = false
		return
	_in_modal = true
	get_tree().paused = true
	var kind: String = _modals.pop_front()
	if kind == "choice":
		_choice = _choices.pop_front()
		if _bot and not "--show-choice" in _args:
			var callback: Callable = _choice["callback"]
			callback.call(int(_arg("--choice=", "0")))
			_next_modal.call_deferred()
		else:
			hud.choice.open(_choice["title"], _choice["prompt"], _choice["options"], _choice.get("cancel", false))
		return
	if kind == "boss_chest" and Upgrades.find_evolution(player).is_empty() and randf() >= BOSS_CHEST_JACKPOT * player.stat("luck"):
		# A boss chest: pick one of three upgrades of what you already have.
		Audio.play("chest", -2.0, 0.0)
		chests_opened += 1
		Profile.add_stat("chests")
		var picks := Upgrades.roll(player, 3, true)
		if _bot:
			_on_offer_chosen(picks[0])
			return
		hud.level_up.open(player.level, picks, 0, tr("BOSS_CHEST_TITLE"))
		return
	if kind == "chest" or kind == "boss_chest" or kind == "great_chest":
		Audio.play("chest", -2.0, 0.0)
		chests_opened += 1
		Profile.add_stat("chests")
		# One upgrade (an evolution first, if one is ready); a boss chest that
		# hits the jackpot gives all three.
		var count := 3 if kind == "great_chest" or (kind == "boss_chest" and Upgrades.find_evolution(player).is_empty()) else 1
		var results := Upgrades.open_chest(player, count)
		if kind == "great_chest":
			hud.show_banner(tr("GREAT_CHEST"), 3.0)
		elif count == 3:
			hud.show_banner(tr("BOSS_CHEST_JACKPOT"), 3.0)
		if _bot:
			_next_modal.call_deferred()
		else:
			hud.treasure.open(results, kind)
		return
	Audio.play("levelup", -4.0, 0.0)
	Audio.play("meow", -9.0, 0.15)
	_level_burst()
	# Luck above 1.0 is the chance of a fourth card.
	var offers := Upgrades.roll(player, 4 if randf() < player.stat("luck") - 1.0 else 3)
	if _bot and not "--show-levelup" in _args:
		# --banish: the bot banishes its first card while it can (tests).
		if "--banish" in _args and player.banish_left > 0 and Upgrades.banish_key(offers[0]) != "":
			player.banish_left -= 1
			player.banished.append(Upgrades.banish_key(offers[0]))
			print("BOT: banished %s" % player.banished[-1])
			offers = Upgrades.roll(player, 3)
		if int(offers[0].get("grade", 0)) > 0:
			print("BOT: grade %d %s:%s" % [offers[0]["grade"], offers[0]["kind"], offers[0]["id"]])
		_on_offer_chosen(offers[0])
		return
	_shown_level = player.level - _modals.count("level")
	_shown_offers = offers
	hud.level_up.open(_shown_level, offers, player.rerolls_left, "", player.banish_left)


func _on_reroll() -> void:
	if player.rerolls_left <= 0:
		return
	player.rerolls_left -= 1
	Audio.play("magnet", -6.0, 0.0)
	_shown_offers = Upgrades.roll(player, 4 if randf() < player.stat("luck") - 1.0 else 3)
	hud.level_up.open(_shown_level, _shown_offers, player.rerolls_left, "", player.banish_left)


## Banishes a level-up card: that item never shows up again this run, and
## the card is replaced by another one.
func _on_banish(index: int) -> void:
	var key := Upgrades.banish_key(_shown_offers[index])
	if player.banish_left <= 0 or key == "":
		return
	player.banish_left -= 1
	player.banished.append(key)
	Audio.play("break", -6.0, 0.1)
	var shown: Array[String] = []
	for o in _shown_offers:
		shown.append(Upgrades.banish_key(o))
	var fresh := Upgrades.roll(player, 6).filter(func(o: Dictionary) -> bool: return Upgrades.banish_key(o) == "" or Upgrades.banish_key(o) not in shown)
	if fresh.is_empty():
		_shown_offers.remove_at(index)
		if _shown_offers.is_empty():
			_shown_offers.append({"kind": "heal", "id": "HEAL", "level": 0})
	else:
		_shown_offers[index] = fresh[0]
	hud.level_up.open(_shown_level, _shown_offers, player.rerolls_left, "", player.banish_left)


## Revival power-up: back on your feet, and everything nearby is blown away.
func _on_revived() -> void:
	lives_used += 1
	hud.show_banner(tr("REVIVED"), 3.0)
	Audio.play("levelup", 0.0, 0.0)
	for enemy in enemies.query_radius(player.position, 140.0):
		enemy.hit(0.0, enemy.position - player.position, 5.0)


func _on_offer_chosen(offer: Dictionary) -> void:
	Audio.play("select", -6.0, 0.0)
	if int(offer.get("grade", 0)) >= 3:
		Profile.add_stat("legendary_cards")
	Upgrades.apply(player, offer)
	_next_modal()


## Every charm already found tonight makes the next one rarer.
func _maybe_drop_charm(pos: Vector2, chance: float) -> void:
	var found := run_charms.size() + pickups.count_kind(Pickup.Kind.CHARM)
	if randf() >= chance * player.stat("luck") / (1.0 + found * 0.35):
		return
	var rarity: String = _weighted(CHARM_RARITY)
	var pool: Array = GameData.charms.keys().filter(func(id: String) -> bool: return GameData.charms[id]["rarity"] == rarity)
	pickups.spawn_charm(pos, pool.pick_random())


## A final boss fell: maybe its legendary (see LEGENDARY_CHANCE), else a rare.
func _final_boss_loot(legend: String) -> void:
	var forced := _arg("--legendary-chance=", "")
	var chance := float(forced) if forced != "" else minf(LEGENDARY_CHANCE * player.stat("luck"), LEGENDARY_CHANCE_MAX)
	var owned := Profile.owns_item(legend) or run_items.any(func(i: Dictionary) -> bool: return i["base"] == legend)
	if not owned and randf() < chance:
		_find_item(Items.legendary(legend))
	else:
		_find_item(Items.roll(player.stat("luck"), "rare"))


func _maybe_find_item(chance: float) -> void:
	# Curses make loot likelier and better.
	var curse := 1.0 + Profile.challenge_loot()
	if randf() < float(_arg("--item-chance=", str(chance))) * player.stat("luck") * curse:
		_find_item(Items.roll(player.stat("luck") * curse))


## A boss or an elite left an item: it goes straight into the cat's bag for
## this run (see run_items).
func _find_item(item: Dictionary) -> void:
	run_items.append(item)
	BotLog.event("item_found")
	var legendary: bool = item["rarity"] == "legendary"
	hud.show_banner(tr("ITEM_FOUND") % [Items.item_name(item), tr("RARITY_" + String(item["rarity"]).to_upper())], 5.0 if legendary else 3.5)
	if legendary:
		BotLog.event("item_legendary")
		# A legendary gets its own fanfare and a burst of gold round the cat.
		Audio.play("legendary", 0.0, 0.0)
		var burst := LegendaryBurst.new()
		burst.position = player.position
		add_child(burst)
	else:
		Audio.play("sparkle", -2.0, 0.0)


## Brings the run's items home. On a death the well saves just the best one.
func _bank_items(kind: String, lines: Array[String]) -> void:
	if run_items.is_empty():
		return
	var kept := run_items
	if kind == "death":
		var best: Dictionary = run_items[0]
		for item: Dictionary in run_items:
			if Items.worth(item) > Items.worth(best):
				best = item
		kept = [best]
		lines.append(tr("SUMMARY_ITEM_WELL") % Items.item_name(best))
	else:
		lines.append(tr("SUMMARY_ITEMS_KEPT") % ", ".join(kept.map(func(i: Dictionary) -> String: return Items.item_name(i))))
	# (A dev test never saves the profile, so this stays in memory.)
	var melted := Profile.bank_items(kept)
	BotLog.event("items_banked")
	if melted > 0:
		lines.append(tr("SUMMARY_ITEMS_MELTED") % melted)


func _on_charm_collected(charm_id: String) -> void:
	# Luck shifts the odds towards the better qualities.
	var weights := []
	for entry: Array in CHARM_QUALITY:
		weights.append([entry[0], float(entry[1]) * (pow(player.stat("luck"), entry[0] - 1))])
	var forced := _arg("--charm-quality=", "")
	var quality: int = int(forced) if forced != "" else int(_weighted(weights))
	run_charms.append(charm_id)
	run_charm_quality.append(quality)
	hud.show_banner(tr("CHARM_FOUND_QUALITY") % [tr("CHARM_%s_NAME" % charm_id), CharmPanel.stars(quality)], 3.5)


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
	extraction.position = Terrain.fix(extraction.position, 40.0)
	extraction.escaped.connect(_end_run.bind("extract"))
	extraction.closed.connect(func() -> void:
		extraction = null
		hud.show_banner(tr("EXTRACT_CLOSED"), 2.5))
	add_child(extraction)
	hud.show_banner(tr("EXTRACT_OPEN"), 4.0)
	Audio.play("quest", -2.0, 0.0)


## Ends the run: "death", "extract" or "victory". Banks gold (with the
## streak bonus unless you died) and updates the streak.
## What tonight's night report asks of you, for the banner.
func _report_goal(rep: Dictionary) -> String:
	match rep["kind"]:
		"defend":
			return tr("REPORT_WIN_DEFEND") % [Profile.REPORT_DEFEND_MINUTES, Profile.REPORT_DEFEND_GOLD]
		"hunt":
			return tr("REPORT_WIN_HUNT") % Profile.REPORT_HUNT_GOLD
		"trip":
			return tr("REPORT_WIN_TRIP") % Profile.TRIP_GOLD
		"rescue":
			return tr("REPORT_WIN_RESCUE") % [Profile.REPORT_DEFEND_MINUTES, tr("CAT_%s_NAME" % Profile.kidnapped)]
	return tr("REPORT_WIN_GOLD")


## Gold for tonight's night report (0 if none or not earned), with a line
## for the summary.
func _report_reward(kind: String, gold: int, lines: Array[String]) -> int:
	var rep := Profile.active_report()
	if rep.is_empty():
		return 0
	var place := tr("STAGE_%s_NAME" % rep["stage"])
	match rep["kind"]:
		"defend":
			if kind == "victory" or spawner.elapsed >= Profile.REPORT_DEFEND_MINUTES * 60.0:
				lines.append(tr("SUMMARY_REPORT_DEFEND") % [place, Profile.REPORT_DEFEND_GOLD])
				return Profile.REPORT_DEFEND_GOLD
			# Lost before the time was up: the map is raided after all.
			var gold_before := Profile.gold
			var news := Profile.raid(place)
			lines.append(tr(news[0]) % news.slice(1))
			var lost := gold_before - Profile.gold
			Profile.gold = gold_before
			return -lost
		"trip":
			if _trip_route.size() > 1:
				Profile.last_trip = _trip_route.duplicate()
			if kind == "victory":
				lines.append(tr("SUMMARY_REPORT_TRIP") % [" – ".join(_trip_route.map(func(s: String) -> String: return tr("STAGE_%s_NAME" % s))), Profile.TRIP_GOLD])
				return Profile.TRIP_GOLD
		"rescue":
			if kind == "victory" or spawner.elapsed >= Profile.REPORT_DEFEND_MINUTES * 60.0:
				var cat := Profile.kidnapped
				Profile.kidnapped = ""
				lines.append(tr("SUMMARY_REPORT_RESCUE") % [tr("CAT_%s_NAME" % cat), Profile.RESCUE_GOLD])
				return Profile.RESCUE_GOLD
		"hunt":
			if kind == "victory":
				lines.append(tr("SUMMARY_REPORT_HUNT") % Profile.REPORT_HUNT_GOLD)
				return Profile.REPORT_HUNT_GOLD
		"gold":
			lines.append(tr("SUMMARY_REPORT_GOLD") % gold)
			return gold
	return 0


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
	Profile.set_stat_max("best_level_cat:" + player.cat_id, player.level)
	Profile.set_stat_max("best_run_gold", floori(run_gold))
	# Quest book distance is in "metres" (16 px).
	Profile.add_stat("distance", floori(_distance / 16.0))
	_distance = 0.0
	if kind == "extract":
		Profile.add_stat("escapes")
	elif kind == "victory":
		Profile.add_stat("wins:" + spawner.stage_id)
		Profile.add_stat("wins_cat:" + player.cat_id)
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
			hud.show_victory(kills, tr("CAT_%s_NAME" % player.cat_id))
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
	_bank_items(kind, lines)
	if kind != "death" and not run_charms.is_empty():
		var upgraded: Array[String] = []
		var refund := Profile.bank_charms(run_charms, run_charm_quality, upgraded)
		lines.append(tr("SUMMARY_CHARMS_KEPT") % _charm_names())
		for id in upgraded:
			lines.append(tr("SUMMARY_CHARM_UPGRADED") % [tr("CHARM_%s_NAME" % id), CharmPanel.stars(Profile.quality_of(id))])
		if refund > 0:
			lines.append(tr("SUMMARY_CHARMS_DUPES") % refund)
	if spawner.darkness > 0:
		var dark_bonus := floori(gold * Spawner.DARKNESS_GOLD * spawner.darkness)
		gold += dark_bonus
		lines.append(tr("SUMMARY_DARKNESS") % [spawner.darkness, dark_bonus])
		if kind == "victory":
			Profile.add_stat("darkness_wins")
			Profile.set_stat_max("best_darkness", spawner.darkness)
			if Profile.win_darkness(spawner.stage_id, spawner.darkness):
				lines.append(tr("SUMMARY_DARKNESS_WON") % spawner.darkness)
	elif kind == "victory" and Profile.max_darkness(spawner.stage_id) > 0 and int(Profile.darkness_best.get(spawner.stage_id, 0)) == 0:
		lines.append(tr("SUMMARY_DARKNESS_OPEN"))
	if not Profile.challenges.is_empty():
		var bonus := floori(gold * (Profile.challenge_gold() - 1.0))
		gold += bonus
		lines.append(tr("SUMMARY_CHALLENGE") % [Profile.challenge_gold(), bonus])
	if Profile.daily and kind == "victory" and not Profile.has_flag("daily_win:" + Profile.today()):
		Profile.set_flag("daily_win:" + Profile.today())
		Profile.add_stat("daily_wins")
		gold += Profile.DAILY_GOLD
		lines.append(tr("SUMMARY_DAILY") % Profile.DAILY_GOLD)
	if kind == "victory" and player.is_home():
		var home_gold := floori(gold * HOME_WIN_GOLD)
		gold += home_gold
		lines.append(tr("SUMMARY_HOME") % home_gold)
	gold += _report_reward(kind, gold, lines)
	if kind == "victory" and _flags_taken >= Profile.TERRITORY_FLAGS and Profile.conquer(spawner.stage_id):
		lines.append(tr("SUMMARY_TERRITORY") % [tr("STAGE_%s_NAME" % spawner.stage_id), DistrictMap.stats_text(Profile.TERRITORY_BONUS[spawner.stage_id])])
		print("TERRITORY: %s conquered" % spawner.stage_id)
		BotLog.event("territory_won")
	if Profile.moon_on:
		if kind == "victory":
			gold += Profile.MOON_GOLD
			lines.append(tr("SUMMARY_MOON_WON") % Profile.MOON_GOLD)
		else:
			var theft := mini(floori(Profile.gold * Profile.MOON_THEFT), Profile.MOON_THEFT_MAX)
			gold -= theft
			lines.append(tr("SUMMARY_MOON_LOST") % theft)
	Profile.add_gold(gold)
	# The night has passed for the whole neighbourhood.
	Profile.pass_night()
	for news: Array in Profile.report_news:
		lines.append(tr(news[0]) % news.slice(1) if news.size() > 1 else tr(news[0]))
	Profile.report_news.clear()
	lines.append_array(_nemesis_lines)
	Achievements.check()
	if _bot:
		print("BOT: summary %s" % " | ".join(lines))
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


## Now and then a cat shrine turns up somewhere near (see Shrine).
func _tick_shrines(delta: float) -> void:
	if is_instance_valid(shrine) or final_boss != null or _run_over:
		return
	_shrine_t -= delta
	if _shrine_t > 0.0:
		return
	_shrine_t = randf_range(SHRINE_EVERY[0], SHRINE_EVERY[1])
	shrine = Shrine.new()
	shrine.main = self
	var forced := _arg("--shrine=", "")
	shrine.kind = forced if forced != "" else Shrine.random_kind()
	shrine.position = player.position + (Vector2(70, 0) if forced != "" else Vector2.from_angle(randf() * TAU) * randf_range(330.0, 430.0))
	shrine.position = Terrain.fix(shrine.position, 34.0)
	add_child(shrine)
	hud.show_banner(tr("SHRINE_APPEARED") % tr("SHRINE_%s_NAME" % shrine.kind), 3.5)


## The map's track: its night version from half way through the night.
func _map_music() -> String:
	var stage := spawner.stage()
	if _day_music == "":
		# Each map has two day tracks in different styles; one per run
		# (--music=alt / --music=main picks it).
		var pick := _arg("--music=", "alt" if randf() < 0.5 else "main")
		_day_music = stage.get("music_alt", "") if pick == "alt" else ""
		if _day_music == "":
			_day_music = stage.get("music", "music_apartment")
	var day := _day_music
	if spawner.elapsed >= spawner.duration_minutes() * 60.0 * NIGHT_MUSIC_AT:
		return stage.get("music_night", day)
	return day


## Distance, time on the brink and the diary page, for the quest book.
## Artifacts with a timer: the hourglass freezes the enemies around the cat,
## the magnet core pulls in every kibble.
func _tick_artifacts(delta: float) -> void:
	var every := player.stat("freeze_every")
	if every > 0.0:
		_freeze_t += delta
		if _freeze_t >= every:
			_freeze_t = 0.0
			for e: Enemy in enemies.query_radius(player.position, HOURGLASS_RADIUS):
				if not e.is_boss:
					e.slow_down(0.0, HOURGLASS_SECONDS)
					e.chill(HOURGLASS_SECONDS)
			Audio.play("sparkle", -4.0, 0.0)
	every = player.stat("pulse_magnet")
	if every > 0.0:
		_magnet_t += delta
		if _magnet_t >= every:
			_magnet_t = 0.0
			pickups.pull_all_xp()


## Thorn collar: getting hurt pricks every enemy close to the cat.
func _on_player_hurt() -> void:
	var thorns := player.stat("thorns")
	if thorns <= 0.0:
		return
	var dmg := THORN_DAMAGE * thorns * player.stat("might") * (1.0 + player.level * 0.05)
	for e: Enemy in enemies.query_radius(player.position, THORN_RADIUS):
		e.hit(dmg, e.position - player.position, 1.0, false)
	Audio.play("scratch", -8.0, 0.1)


func _track_run(delta: float) -> void:
	hud.update_page(_page_item.position if is_instance_valid(_page_item) else null)
	if _run_over or get_tree().paused or player.is_dead:
		return
	var step := player.position.distance_to(_last_pos)
	if step < 40.0:
		_distance += step
	_last_pos = player.position
	_tick_artifacts(delta)
	# Endless night: every minute survived is announced with the record.
	if _endless and floori(spawner.endless_minutes()) > _endless_shown:
		_endless_shown = floori(spawner.endless_minutes())
		var best := maxi(Profile.get_stat("best_endless_minutes"), _endless_shown)
		hud.show_banner(tr("ENDLESS_MINUTE") % [_endless_shown, best, floori(run_gold - _banked_gold)], 3.0)
	# Rex, once you have won his respect, gives up half way through the fight.
	if final_boss != null and final_boss.id == "GUARD_DOG" and not _rex_calm and ChainStep.is_done("REX_RESPECT") and final_boss.hp < final_boss.max_hp * 0.5:
		_rex_calm = true
		hud.show_banner(tr("REX_GIVES_UP"), 5.0)
		final_boss.hit(final_boss.hp + 1.0, Vector2.ZERO, 0.0, false)
	if player.hp < player.max_hp * 0.1:
		_brink_t += delta
		if _brink_t >= 30.0 and not _was_on_brink:
			_was_on_brink = true
			Profile.set_flag("brink")
	else:
		_brink_t = 0.0
	if Profile.daily and spawner.elapsed < 1.0 and not _challenge_shown:
		_challenge_shown = true
		hud.show_banner(tr("DAILY_ON") % ", ".join(Profile.challenges.map(func(c: String) -> String: return tr("CHALLENGE_%s_NAME" % c))), 4.0)
	if spawner.darkness > 0 and spawner.elapsed < 1.0 and not _darkness_shown:
		_darkness_shown = true
		hud.show_banner(tr("DARKNESS_ON") % [spawner.darkness, roundi(Spawner.DARKNESS_HP * spawner.darkness * 100.0), roundi(Spawner.DARKNESS_GOLD * spawner.darkness * 100.0)], 4.5)
	if not Profile.challenges.is_empty() and spawner.elapsed < 1.0 and not _challenge_shown:
		_challenge_shown = true
		hud.show_banner(tr("CHALLENGES_ON") % [", ".join(Profile.challenges.map(func(c: String) -> String: return tr("CHALLENGE_%s_NAME" % c))), Profile.challenge_gold()], 4.0)
	if Profile.moon_on and not _run_over:
		_tick_moon()
	if not _flags_placed and spawner.elapsed >= 1.0:
		_flags_placed = true
		_place_flags()
	if not _trip_gates.is_empty() and spawner.elapsed >= float(_trip_gates[0]) and not _run_over and not get_tree().paused:
		_trip_gates.pop_front()
		_trip_gate()
	if _nemesis_at < 0.0 and not _nemesis_planned:
		if Profile.active_report().get("kind", "") == "trip":
			_start_trip()
		_nemesis_planned = true
		_plan_nemesis_hunt()
	if _nemesis_at >= 0.0 and spawner.elapsed >= _nemesis_at and not _run_over:
		_nemesis_hunt()
	# After the challenge banner: tonight's night report, then the home bonus.
	if not _report_shown and spawner.elapsed >= 4.5 and not Profile.active_report().is_empty():
		_report_shown = true
		var rep := Profile.active_report()
		hud.show_banner("%s – %s" % [tr("REPORT_%s_NAME" % rep["kind"].to_upper()), _report_goal(rep)], 4.5)
	if not _home_shown and spawner.elapsed >= 9.0 and player.is_home():
		_home_shown = true
		hud.show_banner(tr("HOME_ON") % DistrictMap.home_text(player.cat_id), 4.0)
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
	_tick_shrines(delta)
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
	if _angel_saves() or _dev_revive_asks():
		return
	_remember_killer()
	_end_run("death")


## The boss closest to the cat when it fell (if one was near) becomes, or
## grows as, a nemesis.
func _remember_killer() -> void:
	if dev_test:
		return
	var killer: Enemy = null
	var best := 700.0 * 700.0
	for e in enemies.enemies:
		if e.is_boss and not e.dead and e.position.distance_squared_to(player.position) < best:
			best = e.position.distance_squared_to(player.position)
			killer = e
	if killer == null:
		return
	var level := Profile.add_nemesis(killer.id)
	_nemesis_lines.append(tr("NEMESIS_NEW") % [tr("ENEMY_%s_NAME" % killer.id), tr("NEMESIS_TITLE_%d" % level), level])
	print("NEMESIS: %s level %d" % [killer.id, level])
	BotLog.event("nemesis_new")


## The full moon night: home is set up (traps, guard cats), then the
## bosses of every map come one after another.
func _tick_moon() -> void:
	if not _moon_ready and spawner.elapsed >= 0.5:
		_moon_ready = true
		for id: String in GameData.stages:
			var boss: String = GameData.stages[id].get("final_boss", "")
			if id != spawner.stage_id and boss != "" and Profile.is_stage_unlocked(id):
				_moon_bosses.append(boss)
		if _moon_bosses.is_empty():
			_moon_bosses.append("RAT_KING")
		for i in Profile.moon_traps:
			var trap := Trap.new()
			trap.friendly = true
			trap.position = Terrain.fix(player.position + Vector2.from_angle(TAU * i / maxf(Profile.moon_traps, 1.0) + 0.4) * 130.0, 30.0)
			trap.setup("MOUSETRAP", self)
			add_child(trap)
		for cat_id: String in Profile.moon_guards:
			var cat: Player = PLAYER_SCENE.instantiate()
			cat.controller = "follow"
			cat.cat_id = cat_id
			cat.leader = player
			cat.process_mode = Node.PROCESS_MODE_PAUSABLE
			cat.position = player.position + Vector2(randf_range(-30, 30), 24)
			add_child(cat)
			move_child(cat, player.get_index())
			companions.append(cat)
		hud.show_banner(tr("MOON_ON") % _moon_bosses.size(), 4.5)
		BotLog.event("moon_start")
	if _moon_bosses.is_empty() or spawner.elapsed < _moon_next:
		return
	_moon_next += MOON_BOSS_EVERY
	var id: String = _moon_bosses.pop_front()
	var boss := spawner.spawn_boss_as_in_run(id, player.position + Vector2.from_angle(randf() * TAU) * 380.0)
	if boss == null:
		return
	if GameData.enemies[id].get("final", false):
		boss.max_hp *= MOON_FINAL_HP
		boss.hp = boss.max_hp
	player.shake(5.0, 0.5)
	Audio.play("roar", 0.0, 0.0)
	hud.show_banner(tr("MOON_BOSS") % tr("ENEMY_%s_NAME" % id), 3.5)
	print("MOON: %s comes" % id)
	BotLog.event("moon_boss")


## On a map not yet conquered, the boss's flags stand around the start.
func _place_flags() -> void:
	var id := spawner.stage_id
	if dev_test or _endless or Profile.moon_on or id in Profile.territories or not Profile.TERRITORY_BONUS.has(id):
		return
	if Profile.active_report().get("kind", "") == "trip":
		return
	var dist := float(_arg("--flag-dist=", "600"))
	var turn := randf() * TAU
	for i in Profile.TERRITORY_FLAGS:
		var flag := TerritoryFlag.new()
		flag.main = self
		flag.capture_time = float(_arg("--flag-time=", str(TerritoryFlag.CAPTURE_TIME)))
		flag.position = Terrain.fix(player.position + Vector2.from_angle(turn + TAU * i / Profile.TERRITORY_FLAGS) * dist * randf_range(0.9, 1.1), 40.0)
		flag.captured.connect(_on_flag_taken.bind(flag))
		add_child(flag)
		move_child(flag, $Floor.get_index() + 1)
		_flags.append(flag)
	print("TERRITORY: %d flags on %s" % [_flags.size(), id])


func _on_flag_taken(flag: TerritoryFlag) -> void:
	_flags_taken += 1
	player.heal(player.max_hp * 0.2)
	for i in 8:
		pickups.spawn_named("coin", flag.position + Vector2.from_angle(TAU * i / 8.0) * 24.0, 5.0)
	Audio.play("sparkle", 0.0, 0.0)
	var all := _flags_taken >= Profile.TERRITORY_FLAGS
	hud.show_banner(tr("TERRITORY_ALL") if all else tr("TERRITORY_FLAG") % [_flags_taken, Profile.TERRITORY_FLAGS], 4.0)
	print("TERRITORY: flag %d/%d" % [_flags_taken, Profile.TERRITORY_FLAGS])
	BotLog.event("flag_taken")


## A night trip starts: two gates will come during the night.
func _start_trip() -> void:
	_trip_route.assign([spawner.stage_id])
	var forced := GameData.arg("--trip-at=", "")
	if forced != "":
		_trip_gates = [float(forced), float(forced) * 2.0]
	else:
		_trip_gates = TRIP_GATES.duplicate()
	BotLog.event("trip_start")


## A gate: choose the left or the right way, and the night moves there.
func _trip_gate() -> void:
	var open: Array = GameData.stages.keys().filter(func(s: String) -> bool:
		return Profile.is_stage_unlocked(s) and s not in _trip_route)
	open.shuffle()
	if open.is_empty():
		return
	var ways: Array = open.slice(0, 2)
	var options: Array = []
	for i in ways.size():
		options.append(tr("TRIP_GATE_LEFT" if i == 0 else "TRIP_GATE_RIGHT") % tr("STAGE_%s_NAME" % ways[i]))
	Audio.play("bell", -2.0, 0.0)
	ask_choice(tr("TRIP_GATE_TITLE"), tr("TRIP_GATE_ASK"), options, func(index: int) -> void:
		_go_through_gate(ways[clampi(index, 0, ways.size() - 1)]))


## The night carries on in another map: its floor, terrain, enemies and music.
func _go_through_gate(id: String) -> void:
	_trip_route.append(id)
	spawner.change_stage(id)
	$Floor.set_theme(spawner.stage().get("theme", "apartment"))
	if Terrain.current != null:
		Terrain.current.queue_free()
		Terrain.current = null
	var kind: String = spawner.stage().get("terrain", "")
	if kind != "":
		var terrain := Terrain.new()
		terrain.setup(kind, self)
		add_child(terrain)
		move_child(terrain, $Floor.get_index() + 1)
	_setup_hazard()
	_day_music = ""
	Audio.play_music(_map_music())
	player.shake(4.0, 0.4)
	hud.show_banner(tr("TRIP_ARRIVED") % tr("STAGE_%s_NAME" % id), 4.0)
	print("TRIP: through the gate to %s" % id)
	BotLog.event("trip_gate")


## The map's own special event (a train, the tide's treasures...), if it has one.
func _setup_hazard() -> void:
	if MapHazard.current != null:
		MapHazard.current.queue_free()
		MapHazard.current = null
	var kind: String = _arg("--hazard=", spawner.stage().get("hazard", ""))
	if kind == "" or kind == "none":
		return
	var hazard := MapHazard.new()
	hazard.setup(kind, self)
	add_child(hazard)


## Tonight's weather over the map (none under a roof, in tests or endless).
func _start_weather() -> void:
	var kind := Weather.for_stage(spawner.stage_id)
	if kind == "CLEAR" or kind == "" or (dev_test and GameData.arg("--weather=", "") == ""):
		return
	var w := Weather.new()
	w.kind = kind
	w.player = player
	w.enemies = enemies
	add_child(w)
	if not player.blessings.is_empty():
		player.blessings[-1]["desc"] = tr("WEATHER_%s_DESC" % kind)


## Your nemesis may turn up to hunt you, some minutes into another night.
## Never on a full moon, played or skipped: with a siege waiting that would be
## a third threat at once.
func _plan_nemesis_hunt() -> void:
	var id := Profile.top_nemesis()
	if id == "" or dev_test or _endless or Profile.moon_on or Profile.moon_full():
		return
	if id == GameData.stages[spawner.stage_id].get("final_boss", ""):
		return
	var forced := GameData.arg("--nemesis-at=", "")
	if forced != "":
		_nemesis_at = float(forced)
	elif randf() < Profile.NEMESIS_HUNT_CHANCE:
		_nemesis_at = randf_range(480.0, 720.0)


func _nemesis_hunt() -> void:
	_nemesis_at = -1.0
	var id := Profile.top_nemesis()
	if id == "":
		return
	var boss := spawner.spawn_boss_as_in_run(id, player.position + Vector2.from_angle(randf() * TAU) * 360.0)
	if boss == null:
		return
	_nemesis_boss = boss
	# A final boss from another map comes as a hunter, not as a whole night's
	# finale: much less health than at the end of its own night.
	if GameData.enemies[id].get("final", false):
		boss.max_hp *= NEMESIS_HUNT_FINAL_HP
		boss.hp = boss.max_hp
	player.shake(6.0, 0.6)
	Audio.play("roar", 0.0, 0.0)
	hud.show_banner(tr("NEMESIS_HUNTS") % [tr("ENEMY_%s_NAME" % id), tr("NEMESIS_TITLE_%d" % Profile.nemesis_level(id))], 5.0)
	print("NEMESIS: %s hunts" % id)
	BotLog.event("nemesis_hunt")


## Beating a nemesis: it forgets you, and you get a boss chest and gold.
func _nemesis_revenge(id: String, pos: Vector2) -> void:
	if not Profile.nemesis.has(id) or dev_test:
		return
	Profile.nemesis.erase(id)
	Profile.add_stat("revenges")
	Profile.save()
	pickups.spawn_named("chest", pos, 1.0)
	for i in 12:
		pickups.spawn_named("coin", pos + Vector2.from_angle(TAU * i / 12.0) * 30.0, 5.0)
	run_gold += Profile.NEMESIS_REVENGE_GOLD
	hud.show_banner(tr("NEMESIS_REVENGE") % [tr("ENEMY_%s_NAME" % id), Profile.NEMESIS_REVENGE_GOLD], 5.0)
	_nemesis_lines.append(tr("SUMMARY_NEMESIS_REVENGE") % [tr("ENEMY_%s_NAME" % id), Profile.NEMESIS_REVENGE_GOLD])
	print("NEMESIS: %s beaten" % id)
	BotLog.event("nemesis_beaten")


## Pause menu: pick an owned weapon or passive to throw away for good.
func _ask_discard() -> void:
	var picks: Array[Array] = []
	for w: Weapon in player.weapons.get_children():
		picks.append(["weapon", w.id])
	for id: String in player.passives:
		picks.append(["passive", id])
	if picks.is_empty() or player.discard_left <= 0:
		return
	hud.show_pause(false)
	var names: Array = picks.map(func(p: Array) -> String: return Upgrades.item_name(p[0], p[1]))
	var options: Array = []
	for i in picks.size():
		var key := "%s_%s_DESC" % [String(picks[i][0]).to_upper(), picks[i][1]]
		var desc := tr(key)
		options.append({"title": names[i], "desc": "" if desc == key else desc})
	ask_choice(tr("DISCARD_TITLE"), tr("DISCARD_PROMPT") % player.discard_left, options, func(index: int) -> void:
		if index >= 0 and index < picks.size():
			player.discard(picks[index][0], picks[index][1])
			hud.update_inventory(player)
			hud.show_banner(tr("DISCARD_DONE") % names[index], 3.0), true)


## Dev builds with the dev panel ask before the night ends, so a test can
## go on after a death (the dev panel's "Revive on death" switch).
func _dev_revive_asks() -> bool:
	if not dev_revive or _bot:
		return false
	ask_choice("DEV", "The cat died. Revive it? (dev builds only)", ["Revive (full health)", "Die"], func(index: int) -> void:
		if index == 0:
			player.revive(1.0, 3.0)
		else:
			_end_run("death"))
	return true


## Secret: a dying cat may be saved by an angel cat (see ANGEL_CHANCE), and
## dying again after that may bring Death.
func _angel_saves() -> bool:
	# Nothing saves you from the devil.
	if player.killed_by_fatal or is_instance_valid(devil) or _devil_portal != null:
		return false
	if angel_saves > 0:
		if randf() >= float(_arg("--death-chance=", str(DEATH_AFTER_ANGEL))):
			return false
		_death_comes()
		return true
	if spawner.elapsed < ANGEL_AFTER_MINUTE * 60.0:
		return false
	# The Moon Windows story makes the angel come twice as often.
	var chance := ANGEL_CHANCE + ANGEL_CHANCE_PER_LIFE * lives_used
	chance = float(_arg("--angel-chance=", str(chance))) * (2.0 if Profile.has_flag("angel_hint") else 1.0)
	if randf() >= chance:
		return false
	summon_angel()
	return true


## The cat died again after the angel: Death won't let it go that easily.
## It gets up once more, but Death rises right next to it and hunts it.
func _death_comes() -> void:
	if _bot:
		print("BOT: death comes")
	player.revive(0.6, 3.0)
	summon_devil()


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


## The devil cat: chases you down and kills in a hit or two; it can't be hurt
## for its first "immortal_seconds" (5 minutes).
func summon_devil() -> void:
	if _run_over or is_instance_valid(devil) or _devil_portal != null:
		return
	# The world stops for Death's arrival (DeathArrival): it tears the floor
	# open, climbs out and reaps every enemy, then the hunt begins.
	get_tree().paused = true
	Audio.pause_music(true)
	var arrival := DeathArrival.new()
	arrival.position = player.position + Vector2.from_angle(randf() * TAU) * 150.0
	arrival.cat_pos = player.position
	arrival.survive_seconds = _devil_immortal_seconds()
	arrival.reap.connect(_death_reaps)
	arrival.finished.connect(func() -> void:
		Audio.pause_music(false)
		get_tree().paused = _in_modal or _run_over
		_devil_rises())
	_devil_portal = arrival
	add_child(arrival)
	hud.show_banner(tr("DEVIL_COMING"), 5.0)
	player.shake(6.0, 1.8)


## Death's arrival kills everything on the map but the cat (and the final
## boss, whose fight decides the night); the waves pause for a breath.
func _death_reaps() -> void:
	player.shake(14.0, 1.0)
	enemies.clear_all()
	spawner.calm = maxf(spawner.calm, 6.0)


func _devil_rises() -> void:
	Profile.set_flag("devil_met")
	devil = enemies.spawn(DEVIL_ID, _devil_portal.position, spawner.final_hp_multiplier())
	spawner.toughen(devil, 0.5)
	# It can't be hurt for its first minutes: survive them, then fight back.
	var shield := _devil_immortal_seconds()
	_devil_mortal_at = spawner.elapsed + shield
	devil.immortal = shield > 0.0
	if shield > 0.0:
		player.bless({}, shield, "DEVIL_SHIELD", Color("ff4a3a"))
	_devil_portal = null
	player.shake(10.0, 0.6)
	Audio.play_music(GameData.enemies[DEVIL_ID].get("music", "music_boss"))
	if _bot:
		print("BOT: devil summoned")


## How long Death can't be hurt after it came (--devil-shield=S for tests).
func _devil_immortal_seconds() -> float:
	return float(_arg("--devil-shield=", str(GameData.enemies[DEVIL_ID].get("immortal_seconds", 300))))


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


## A final boss's fight moves on (see Enemy.fight): a pack runs through, or
## it changes its attacks at half health.
func _on_boss_event(boss: Enemy, kind: String) -> void:
	var boss_name := tr("ENEMY_%s_NAME" % boss.id)
	match kind:
		"pack":
			spawner.send_pack()
			hud.show_banner(tr("BOSS_PACK") % boss_name, 2.5)
		"phase2":
			hud.show_banner(tr("BOSS_PHASE2") % boss_name, 2.5)
	player.shake(6.0, 0.5)
	Audio.play("roar", 0.0, 0.1)


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
	hud.show_banner(tr("ENDLESS_START") % Profile.get_stat("best_endless_minutes"), 7.0)
	_endless_shown = 0
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
	Achievements.check()
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


## The dev panel's tests straight from the command line (see the list above).
func _dev_start(dev: DevPanel) -> void:
	if "--strong" in _args:
		dev._strong_build()
	if _arg("--dev-go-minute=", "") != "":
		dev._go_to_minute(float(_arg("--dev-go-minute=", "0")))
		print("BOT: went to minute %.1f at level %d with %d weapons" % [spawner.elapsed / 60.0, player.level, player.weapon_count()])
	if _arg("--dev-boss=", "") != "":
		dev.fight(_arg("--dev-boss=", ""))
	elif "--boss-rush" in _args:
		dev.start_boss_rush()
	if _arg("--dev-quest=", "") != "":
		dev._test_quest(_arg("--dev-quest=", ""))
	if "--dev-quest-all" in _args:
		dev.cycle_quests()
	if "--dev-endless" in _args:
		dev._endless_now()
	if "--dev-panel" in _args:
		dev._open()
	for i in int(_arg("--dev-next-terrain=", "0")):
		dev._next_terrain()
