class_name Combos
extends RefCounted
## Weapon combos: owning two weapons that belong together gives an extra
## effect on top (not an evolution, both keep their slots). Evolutions count
## as their base weapon. Each combo needs one weapon from every group.
## Texts: COMBO_<ID>_NAME / _DESC. The effects live in Weapon.strike/area.

const WET := ["SPRINKLER", "WAVE", "MILK"]
const LIST := {
	# Water carries electricity: lightning on a wet enemy hits harder and jumps.
	"CONDUCT": [["ANTENNA"], WET],
	# Water freezes: the frozen fish turns a wet enemy to ice.
	"ICE": [["FROST_FISH"], WET],
	# Ice is brittle: the hammer hits a chilled enemy harder and splinters it.
	"SHATTER": [["SQUEAKY_HAMMER"], ["FROST_FISH"]],
	# Hammer on a bell: the blow rings out round the target.
	"RESONANCE": [["SQUEAKY_HAMMER"], ["BELL"]],
	# The laser dot marks a target and the toy mice chase it.
	"CHASE": [["LASER"], ["MOUSE_TOY"]],
	# Yarn threads catch in the cobwebs: yarn tangles and slows.
	"TANGLE": [["YARN"], ["COBWEB"]],
	# The antenna relays the drone's signal: drone shots may spark on.
	"SIGNAL": [["DRONE_BUDDY"], ["ANTENNA"]],
	# A soaked hairball is heavier: harder hit, bigger push.
	"HEAVY": [["HAIRBALL"], ["SPRINKLER"]],
	# A cat high on catnip plays rougher with the feather toy.
	"CATNIP_HIGH": [["CATNIP"], ["FEATHER"]],
	# Watered-down milk spreads wider.
	"THIN_MILK": [["MILK"], ["SPRINKLER"]],
}
const ICONS := {
	"CONDUCT": "ANTENNA", "ICE": "FROST_FISH", "SHATTER": "SQUEAKY_HAMMER", "RESONANCE": "BELL",
	"CHASE": "MOUSE_TOY", "TANGLE": "COBWEB", "SIGNAL": "DRONE_BUDDY", "HEAVY": "HAIRBALL",
	"CATNIP_HIGH": "FEATHER", "THIN_MILK": "MILK",
}

const SHATTER_BONUS := 0.5
const SHATTER_SPLINTER := 0.3
const SHATTER_RADIUS := 36.0
const RESONANCE_CHANCE := 0.3
const RESONANCE_DAMAGE := 0.4
const RESONANCE_RADIUS := 50.0
const CHASE_BONUS := 0.4
const CHASE_MARK := 3.0
const TANGLE_SLOW := 0.6
const TANGLE_SECONDS := 1.5
const SIGNAL_CHANCE := 0.2
const SIGNAL_DAMAGE := 0.5
const HEAVY_BONUS := 0.25
const CATNIP_BONUS := 0.3
const MILK_AREA := 0.25
const ICE_SECONDS := 1.2
## Same as the catnip weapon's own radius (scripts/weapons/catnip.gd).
const CATNIP_RADIUS := 46.0


## The combos `owned` base weapons make.
static func active(owned: Array) -> Array[String]:
	var out: Array[String] = []
	for id: String in LIST:
		var ok := true
		for group: Array in LIST[id]:
			if not group.any(func(w: String) -> bool: return w in owned):
				ok = false
				break
		if ok:
			out.append(id)
	return out


## Every combo `base` takes part in, with its partner groups (for the
## level-up card: "pairs with ...").
static func partners(base: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in LIST:
		var groups: Array = LIST[id]
		if groups.any(func(g: Array) -> bool: return base in g):
			out.append(id)
	return out
