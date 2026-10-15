extends Weapon
## Šanta: a permanent aura around the cat that hurts everything inside it
## every `interval` seconds (like Garlic).

const BASE_RADIUS := 32.0

var _aura: CatnipAura


func _ready() -> void:
	super()
	_aura = CatnipAura.new()
	_aura.player = player
	world.add_child.call_deferred(_aura)


func _exit_tree() -> void:
	if is_instance_valid(_aura):
		_aura.queue_free()


func _process(_delta: float) -> void:
	if is_instance_valid(_aura):
		_aura.radius = BASE_RADIUS * area()


func shots() -> int:
	return 1


func shoot(_index: int) -> void:
	var r := BASE_RADIUS * area()
	var hits := enemies.query_radius(player.position, r)
	for enemy in hits:
		enemy.hit(damage(), enemy.position - player.position, stat("knockback", 0.3))
	if not hits.is_empty() and stat("heal_per_tick") > 0.0:
		player.heal(stat("heal_per_tick"))
	if is_instance_valid(_aura):
		_aura.pulse()
