extends Node2D
## Wires the run together: player, enemies, pickups, spawner and HUD;
## handles level-ups, pause, game over and restart.
##
## Run with `-- --bot` to let the cat play on its own at 4x speed (it always
## takes the first level-up offer); it prints a summary and quits after
## BOT_DURATION seconds of game time (used for tests).

const BOT_DURATION := 300.0
const HEART_DROP_CHANCE := 0.005
const HEART_DROP_AMOUNT := 15.0

var kills := 0
var props_broken := 0

var _bot := "--bot" in OS.get_cmdline_user_args()
var _pending_level_ups := 0
var _choosing := false

@onready var player: Player = $Player
@onready var enemies: EnemyManager = $Enemies
@onready var pickups: Pickups = $Pickups
@onready var spawner: Spawner = $Spawner
@onready var hud: Hud = $HUD


func _ready() -> void:
	enemies.player = player
	pickups.player = player
	spawner.setup(player, enemies)
	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.prop_broken.connect(_on_prop_broken)
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_level_up)
	player.xp_changed.connect(func() -> void: hud.update_xp(player))
	player.inventory_changed.connect(func() -> void: hud.update_inventory(player))
	hud.level_up.chosen.connect(_on_offer_chosen)
	hud.update_xp(player)
	hud.update_inventory(player)
	if _bot:
		player.bot_mode = true
		Engine.time_scale = 4.0
	if "--all-weapons" in OS.get_cmdline_user_args():
		for id: String in GameData.weapons:
			if player.get_weapon(id) == null:
				player.add_weapon(id)


func _process(_delta: float) -> void:
	hud.update_stats(spawner.elapsed, kills, enemies.enemies.size())
	if _bot and (spawner.elapsed >= BOT_DURATION or player.is_dead):
		var weapons: Array[String] = []
		for w: Weapon in player.weapons.get_children():
			weapons.append("%s:%d" % [w.id, w.level])
		print("BOT: time=%.1f level=%d kills=%d hp=%.0f/%.0f enemies=%d dead=%s" % [
			spawner.elapsed, player.level, kills, player.hp, player.max_hp,
			enemies.enemies.size(), player.is_dead])
		print("BOT: weapons=%s passives=%s props_broken=%d" % [weapons, player.passives, props_broken])
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if _choosing:
		return
	if event.is_action_pressed("language") and get_tree().paused and not player.is_dead:
		Settings.cycle_language()
		hud.show_pause(true)
		hud.update_inventory(player)
	elif event.is_action_pressed("pause") and not player.is_dead:
		get_tree().paused = not get_tree().paused
		hud.show_pause(get_tree().paused)
	elif event.is_action_pressed("restart") and player.is_dead:
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_enemy_killed(_id: String, pos: Vector2, xp: float) -> void:
	kills += 1
	pickups.spawn_xp(pos, xp)
	if randf() < HEART_DROP_CHANCE:
		pickups.spawn_named("heart", pos + Vector2(6, 0), HEART_DROP_AMOUNT)


func _on_prop_broken(_id: String, pos: Vector2) -> void:
	props_broken += 1
	var total := 0.0
	for entry: Dictionary in GameData.loot:
		total += float(entry["weight"])
	var roll := randf() * total
	for entry: Dictionary in GameData.loot:
		roll -= float(entry["weight"])
		if roll <= 0.0:
			pickups.spawn_named(entry["kind"], pos, float(entry.get("value", 0.0)))
			return


func _on_level_up() -> void:
	_pending_level_ups += 1
	if not _choosing:
		_open_level_up.call_deferred()


func _open_level_up() -> void:
	if player.is_dead:
		return
	_choosing = true
	var offers := Upgrades.roll(player)
	if _bot and not "--show-levelup" in OS.get_cmdline_user_args():
		_on_offer_chosen(offers[0])
		return
	get_tree().paused = true
	hud.level_up.open(player.level - _pending_level_ups + 1, offers)


func _on_offer_chosen(offer: Dictionary) -> void:
	Upgrades.apply(player, offer)
	_pending_level_ups -= 1
	if _pending_level_ups > 0:
		_open_level_up()
	else:
		_choosing = false
		get_tree().paused = false


func _on_player_died() -> void:
	hud.show_game_over(spawner.elapsed, kills)
	get_tree().paused = true
