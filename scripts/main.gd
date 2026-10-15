extends Node2D
## Wires the run together: player, enemies, spawner and HUD; handles pause,
## game over and restart.
##
## Run with `-- --bot` to let the cat walk on its own at 4x speed; it prints a
## summary and quits after BOT_DURATION seconds of game time (used for tests).

const BOT_DURATION := 120.0

var kills := 0

var _bot := "--bot" in OS.get_cmdline_user_args()

@onready var player: Player = $Player
@onready var enemies: EnemyManager = $Enemies
@onready var spawner: Spawner = $Spawner
@onready var hud: Hud = $HUD


func _ready() -> void:
	enemies.player = player
	spawner.setup(player, enemies)
	enemies.enemy_killed.connect(_on_enemy_killed)
	player.died.connect(_on_player_died)
	if _bot:
		player.bot_mode = true
		Engine.time_scale = 4.0


func _process(_delta: float) -> void:
	hud.update_stats(spawner.elapsed, kills, enemies.enemies.size())
	if _bot and (spawner.elapsed >= BOT_DURATION or player.is_dead):
		print("BOT: time=%.1f kills=%d hp=%.0f enemies=%d dead=%s" % [
			spawner.elapsed, kills, player.hp, enemies.enemies.size(), player.is_dead])
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not player.is_dead:
		get_tree().paused = not get_tree().paused
		hud.show_pause(get_tree().paused)
	elif event.is_action_pressed("restart") and player.is_dead:
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_enemy_killed(_id: String, _pos: Vector2, _xp: float) -> void:
	kills += 1


func _on_player_died() -> void:
	hud.show_game_over(spawner.elapsed, kills)
	get_tree().paused = true
