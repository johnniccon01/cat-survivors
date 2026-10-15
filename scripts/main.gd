extends Node2D
## Wires the run together: player, enemies, pickups, spawner and HUD;
## handles level-ups, treasure chests, pause, game over, victory and restart.
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
##   --levels=N         start with N random level-up picks (to test late game)

const HEART_DROP_CHANCE := 0.005
const COIN_DROP_CHANCE := 0.015
const VICTORY_GOLD := 150
const HEART_DROP_AMOUNT := 15.0
## Treasure size odds: [items, weight]
const CHEST_ROLLS := [[1, 70.0], [3, 25.0], [5, 5.0]]
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const MAX_COMPANIONS := 1

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
var bosses_killed := 0
var chests_opened := 0

var _args := OS.get_cmdline_user_args()
var _bot := "--bot" in _args
var _bot_time := float(_arg("--bot-time=", "300"))
var _modals: Array[String] = []
var _in_modal := false
var _run_over := false

@onready var player: Player = $Player
@onready var enemies: EnemyManager = $Enemies
@onready var pickups: Pickups = $Pickups
@onready var spawner: Spawner = $Spawner
@onready var hud: Hud = $HUD
@onready var night: CanvasModulate = $Night


func _ready() -> void:
	enemies.player = player
	pickups.player = player
	spawner.setup(player, enemies)
	$Floor.theme = spawner.stage().get("theme", "apartment")
	if spawner.stage_id == "BASEMENT" and not Profile.is_unlocked("LUNA"):
		var intro := "STORY_BASEMENT_COLLAR" if Profile.has_flag("collar") else "STORY_BASEMENT_INTRO"
		hud.show_banner.call_deferred(tr(intro), 6.0)
	spawner.elapsed = float(_arg("--start-minute=", "0")) * 60.0
	_bot_time += spawner.elapsed
	night.setup(spawner, player)
	quests = QuestDirector.new()
	add_child(quests)
	quests.setup(self)
	quests.finished_quest.connect(func(ok: bool) -> void: quests_done += int(ok))
	var forced := _arg("--quest=", "")
	if forced != "":
		quests.force.call_deferred(forced)
	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.prop_broken.connect(_on_prop_broken)
	enemies.elite_killed.connect(func(pos: Vector2) -> void: pickups.spawn_named("coin", pos + Vector2(8, 0), 10.0))
	pickups.gold_collected.connect(func(amount: float) -> void: run_gold += amount * player.stat("greed") * player.stat("curse"))
	pickups.chest_collected.connect(_queue_modal.bind("chest"))
	spawner.boss_spawned.connect(func(_id: String) -> void:
		hud.show_banner(tr("BOSS_WARNING"))
		Audio.play("warning", -4.0, 0.0))
	spawner.stage_cleared.connect(_on_stage_cleared)
	spawner.final_boss_spawned.connect(_on_final_boss)
	spawner.event_started.connect(func(kind: String) -> void:
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
	hud.update_xp(player)
	hud.update_inventory(player)
	if _bot:
		player.controller = "bot"
		Engine.time_scale = 4.0
	for i in int(_arg("--levels=", "0")):
		Upgrades.apply(player, Upgrades.roll(player)[0])
	if OS.is_debug_build() and not _bot:
		var dev := DevPanel.new()
		dev.main = self
		add_child(dev)
	if "--test-evolution" in _args:
		_test_evolution.call_deferred()
	Audio.play_music("music_basement" if spawner.stage().get("theme", "") == "basement" else "music_apartment")
	if "--all-weapons" in _args:
		for id: String in GameData.weapons:
			if not GameData.weapons[id].get("evolved", false) and player.get_weapon(id) == null:
				player.add_weapon(id)


func _process(_delta: float) -> void:
	hud.update_stats(spawner.elapsed, kills, enemies.enemies.size())
	hud.update_gold(floori(run_gold))
	if _bot:
		var minute := floori(spawner.elapsed / 60.0)
		_xp_log[minute] = _xp_log.get(minute, 0.0) + pickups.total_xp - _xp_seen
		_xp_seen = pickups.total_xp
	hud.update_quest(quests.active)
	hud.update_boss(final_boss if is_instance_valid(final_boss) and not final_boss.dead else null)
	if _bot and (spawner.elapsed >= _bot_time or _run_over):
		var weapons: Array[String] = []
		for w: Weapon in player.weapons.get_children():
			weapons.append("%s:%d" % [w.id, w.level])
		if is_instance_valid(final_boss):
			print("BOT: final boss hp=%.0f/%.0f" % [final_boss.hp, final_boss.max_hp])
		print("BOT: time=%.1f level=%d kills=%d hp=%.0f/%.0f enemies=%d dead=%s" % [
			spawner.elapsed, player.level, kills, player.hp, player.max_hp,
			enemies.enemies.size(), player.is_dead])
		print("BOT: weapons=%s passives=%s props_broken=%d bosses_killed=%d chests=%d won=%s" % [
			weapons, player.passives, props_broken, bosses_killed, chests_opened, _run_over and not player.is_dead])
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
		var q := quests.active
		if q != null:
			print("BOT: active quest %s started=%s objective=%s" % [q.quest_id, q.started, q.objective()])
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if _in_modal:
		return
	if _run_over:
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
	elif event.is_action_pressed("language") and get_tree().paused:
		Settings.cycle_language()
		hud.show_pause(true)
		hud.update_inventory(player)
	elif event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		hud.show_pause(get_tree().paused)


func _on_enemy_killed(id: String, pos: Vector2, xp: float) -> void:
	kills += 1
	pickups.spawn_xp(pos, xp)
	if GameData.enemies[id].get("final", false):
		bosses_killed += 1
		_on_stage_cleared()
		return
	if GameData.enemies[id].get("boss", false):
		bosses_killed += 1
		pickups.spawn_named("chest", pos, 0.0)
		pickups.spawn_named("coin", pos + Vector2(14, 6), 25.0)
	elif randf() < HEART_DROP_CHANCE:
		pickups.spawn_named("heart", pos + Vector2(6, 0), HEART_DROP_AMOUNT)
	elif randf() < COIN_DROP_CHANCE:
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
		hud.show_banner("%s
%s" % [tr("QUEST_JOINED") % cat_name, tr("QUEST_UNLOCKED") % cat_name], 4.0)
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
		var results := Upgrades.open_chest(player, _weighted(CHEST_ROLLS))
		if _bot:
			_next_modal.call_deferred()
		else:
			hud.treasure.open(results)
		return
	Audio.play("levelup", -4.0, 0.0)
	var offers := Upgrades.roll(player)
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
	hud.level_up.open(_shown_level, Upgrades.roll(player), player.rerolls_left)


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


## Banks the run's gold into the profile and returns the amount.
func _bank_gold(bonus: int) -> int:
	var total := floori(run_gold) + bonus
	Profile.add_gold(total)
	return total


func _on_player_died() -> void:
	_run_over = true
	hud.show_gold_earned(_bank_gold(0))
	Audio.stop_music()
	Audio.play("gameover", -2.0, 0.0)
	hud.show_game_over(spawner.elapsed, kills)
	get_tree().paused = true


func _on_final_boss(boss: Enemy) -> void:
	final_boss = boss
	Audio.play("warning", 0.0, 0.0)
	Audio.play_music("music_boss")
	spawner.paused = true
	hud.show_banner(tr("FINAL_BOSS_WARNING") % tr("ENEMY_%s_NAME" % boss.id), 4.0)


func _on_stage_cleared() -> void:
	_run_over = true
	hud.show_gold_earned(_bank_gold(VICTORY_GOLD))
	Audio.stop_music()
	Audio.play("victory", -2.0, 0.0)
	hud.show_victory(kills)
	if Profile.clear_stage(spawner.stage_id):
		for id: String in GameData.stages:
			if GameData.stages[id].get("requires", "") == spawner.stage_id:
				hud.show_banner(tr("STAGE_UNLOCKED") % tr("STAGE_%s_NAME" % id), 6.0)
	get_tree().paused = true


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
