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
##   --bot-time=SECONDS how long the bot plays (default 300)
##   --start-minute=N   start the run at minute N
##   --all-weapons      start with every base weapon
##   --show-levelup     the bot leaves the level-up screen open
##   --test-evolution   maxes Scratch + Sharp Claws, opens a chest, prints, quits

const HEART_DROP_CHANCE := 0.005
const HEART_DROP_AMOUNT := 15.0
## Treasure size odds: [items, weight]
const CHEST_ROLLS := [[1, 70.0], [3, 25.0], [5, 5.0]]

var kills := 0
var props_broken := 0
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
	spawner.elapsed = float(_arg("--start-minute=", "0")) * 60.0
	night.setup(spawner, player)
	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.prop_broken.connect(_on_prop_broken)
	pickups.chest_collected.connect(_queue_modal.bind("chest"))
	spawner.boss_spawned.connect(func(_id: String) -> void: hud.show_banner(tr("BOSS_WARNING")))
	spawner.stage_cleared.connect(_on_stage_cleared)
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_queue_modal.bind("level"))
	player.xp_changed.connect(func() -> void: hud.update_xp(player))
	player.inventory_changed.connect(func() -> void: hud.update_inventory(player))
	hud.level_up.chosen.connect(_on_offer_chosen)
	hud.treasure.closed.connect(_next_modal)
	hud.update_xp(player)
	hud.update_inventory(player)
	if _bot:
		player.bot_mode = true
		Engine.time_scale = 4.0
	if "--test-evolution" in _args:
		_test_evolution.call_deferred()
	if "--all-weapons" in _args:
		for id: String in GameData.weapons:
			if not GameData.weapons[id].get("evolved", false) and player.get_weapon(id) == null:
				player.add_weapon(id)


func _process(_delta: float) -> void:
	hud.update_stats(spawner.elapsed, kills, enemies.enemies.size())
	if _bot and (spawner.elapsed >= _bot_time or _run_over):
		var weapons: Array[String] = []
		for w: Weapon in player.weapons.get_children():
			weapons.append("%s:%d" % [w.id, w.level])
		print("BOT: time=%.1f level=%d kills=%d hp=%.0f/%.0f enemies=%d dead=%s" % [
			spawner.elapsed, player.level, kills, player.hp, player.max_hp,
			enemies.enemies.size(), player.is_dead])
		print("BOT: weapons=%s passives=%s props_broken=%d bosses_killed=%d chests=%d won=%s" % [
			weapons, player.passives, props_broken, bosses_killed, chests_opened, _run_over and not player.is_dead])
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if _in_modal:
		return
	if _run_over:
		if event.is_action_pressed("restart"):
			get_tree().paused = false
			get_tree().reload_current_scene()
		return
	if event.is_action_pressed("language") and get_tree().paused:
		Settings.cycle_language()
		hud.show_pause(true)
		hud.update_inventory(player)
	elif event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		hud.show_pause(get_tree().paused)


func _on_enemy_killed(id: String, pos: Vector2, xp: float) -> void:
	kills += 1
	pickups.spawn_xp(pos, xp)
	if GameData.enemies[id].get("boss", false):
		bosses_killed += 1
		pickups.spawn_named("chest", pos, 0.0)
	elif randf() < HEART_DROP_CHANCE:
		pickups.spawn_named("heart", pos + Vector2(6, 0), HEART_DROP_AMOUNT)


func _on_prop_broken(_id: String, pos: Vector2) -> void:
	props_broken += 1
	var entry: Dictionary = _weighted(GameData.loot.map(func(e: Dictionary) -> Array: return [e, float(e["weight"])]))
	pickups.spawn_named(entry["kind"], pos, float(entry.get("value", 0.0)))


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
		chests_opened += 1
		var results := Upgrades.open_chest(player, _weighted(CHEST_ROLLS))
		if _bot:
			_next_modal.call_deferred()
		else:
			hud.treasure.open(results)
		return
	var offers := Upgrades.roll(player)
	if _bot and not "--show-levelup" in _args:
		_on_offer_chosen(offers[0])
		return
	hud.level_up.open(player.level - _modals.count("level"), offers)


func _on_offer_chosen(offer: Dictionary) -> void:
	Upgrades.apply(player, offer)
	_next_modal()


func _on_player_died() -> void:
	_run_over = true
	hud.show_game_over(spawner.elapsed, kills)
	get_tree().paused = true


func _on_stage_cleared() -> void:
	_run_over = true
	hud.show_victory(kills)
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
	var w := player.get_weapon("SCRATCH")
	while w.level < w.max_level():
		w.level_up()
	player.add_passive("MIGHT")
	print("TEST: evolution ready: ", Upgrades.find_evolution(player))
	print("TEST: chest: ", Upgrades.open_chest(player, 3))
	await get_tree().process_frame
	var ids: Array[String] = []
	for x: Weapon in player.weapons.get_children():
		ids.append("%s:%d" % [x.id, x.level])
	print("TEST: weapons after: ", ids)
	print("TEST: offers: ", Upgrades.roll(player, 20).map(func(o: Dictionary) -> String: return o["id"]))
	get_tree().quit()
