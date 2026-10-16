extends Weapon
## Kropič: a garden sprinkler on the cat's back. For `duration` seconds it
## spins `amount` water jets around the cat that knock back and hurt whatever
## they sweep over; then it rests until the next cooldown. Monsoon never rests.

const BASE_LENGTH := 70.0
const BASE_SPIN := 2.4
const TICK := 0.25

var _spin: SprinklerSpin


## One spin per cooldown, with every jet at once.
func shots() -> int:
	return 1


func shoot(_index: int) -> void:
	if is_instance_valid(_spin):
		_spin.lifetime = maxf(_spin.lifetime, duration())
		_spin.arms = amount()
		return
	Audio.play("splash", -12.0 - (6.0 if player.is_companion() else 0.0))
	_spin = SprinklerSpin.new()
	_spin.source = self
	_spin.enemies = enemies
	_spin.follow = player
	_spin.arms = amount()
	_spin.length = BASE_LENGTH * area()
	_spin.spin_speed = BASE_SPIN * proj_speed()
	_spin.damage = damage()
	_spin.knockback = stat("knockback", 0.8)
	_spin.tick = TICK
	_spin.lifetime = duration()
	world.add_child(_spin)
