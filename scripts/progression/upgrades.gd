class_name Upgrades
## Builds the level-up offers and applies the chosen one.
## An offer is a Dictionary: { kind: "weapon"|"passive"|"heal", id, level }.

const HEAL_AMOUNT := 30.0
## Weapon levels at which a branch, and its second rank, can be offered.
const BRANCH_FROM := 3
const BRANCH_RANK2_FROM := 6

## Translation key for each weapon stat shown in level-up descriptions.
const STAT_TEXT := {
	"damage": "STAT_DAMAGE",
	"amount": "STAT_AMOUNT",
	"pierce": "STAT_PIERCE",
	"area": "STAT_AREA",
	"speed": "STAT_SPEED",
	"duration": "STAT_DURATION",
	"interval": "STAT_INTERVAL",
	"freeze": "STAT_FREEZE",
}
const PERCENT_STATS := ["area", "speed", "duration"]
## Upgrades of what you already have come up more often than new things, so
## weapons keep growing (Vampire Survivors-like pace).
const OWNED_WEAPON_WEIGHT := 2.5
const OWNED_PASSIVE_WEIGHT := 1.5
## Rarity of a level-up card (Death Must Die-like): a rare, epic or
## legendary card gives 1, 2 or 3 extra levels at once. Chances x luck.
const GRADE_CHANCE := [0.0, 0.12, 0.04, 0.012]
const GRADE_COLORS := [Color("6b5480"), Color("4aa3ff"), Color("b06aff"), Color("ff9a2a")]


## Picks `count` random offers. With `owned_only`, only items the cat
## already has can show up (used by treasure chests).
static func roll(player: Player, count: int = 3, owned_only: bool = false) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	# The Stray (no weapon) gets passives until its "fragile_until" level (3), then weapons.
	var weaponless := player.weapon_count() == 0 and not owned_only
	var no_weapons_yet := weaponless and player.level < int(GameData.cats[player.cat_id].get("fragile_until", 0))
	for id: String in GameData.weapons:
		var data: Dictionary = GameData.weapons[id]
		# Evolved weapons only come by evolving, but keep leveling up after.
		if data.get("evolved", false) and player.get_weapon(id) == null:
			continue
		# Some weapons only show up once their map has been cleared.
		if data.has("requires_stage") and data["requires_stage"] not in Profile.cleared_stages and player.get_weapon(id) == null:
			continue
		var owned := player.get_weapon(id)
		if "weapon:" + id in player.banished:
			continue
		if owned != null:
			if owned.level < owned.max_level():
				pool.append({"kind": "weapon", "id": id, "level": owned.level + 1, "weight": data.get("rarity", 100) * OWNED_WEAPON_WEIGHT, "owned": true})
		elif not owned_only and not no_weapons_yet and player.weapon_count() < player.max_weapons() and not _has_evolution_of(player, id):
			pool.append({"kind": "weapon", "id": id, "level": 1, "weight": data.get("rarity", 100)})
	_add_branch_offers(player, pool)
	for id: String in GameData.passives if not weaponless or no_weapons_yet else []:
		var data: Dictionary = GameData.passives[id]
		var lvl: int = player.passives.get(id, 0)
		if "passive:" + id in player.banished:
			continue
		if lvl == 0 and (owned_only or player.passives.size() >= Player.MAX_PASSIVES):
			continue
		if lvl < data["levels"].size():
			pool.append({"kind": "passive", "id": id, "level": lvl + 1, "weight": data.get("rarity", 100) * (OWNED_PASSIVE_WEIGHT if lvl > 0 else 1.0)})

	var offers: Array[Dictionary] = []
	while offers.size() < count and not pool.is_empty():
		var pick := _weighted_pick(pool)
		offers.append(pool[pick])
		pool.remove_at(pick)
	# Every level-up offers at least one upgrade of a weapon you already have.
	if not offers.is_empty() and not offers.any(func(o: Dictionary) -> bool: return o.get("owned", false)):
		var owned_left := pool.filter(func(o: Dictionary) -> bool: return o.get("owned", false))
		if not owned_left.is_empty():
			offers[offers.size() - 1] = owned_left.pick_random()
	if offers.is_empty():
		offers.append({"kind": "heal", "id": "HEAL", "level": 0})
	for offer in offers:
		_roll_grade(player, offer)
	return offers


## Rolls the card's rarity, capped by the levels the item has left.
static func _roll_grade(player: Player, offer: Dictionary) -> void:
	var room := 0
	match offer["kind"]:
		"weapon":
			room = GameData.weapons[offer["id"]]["levels"].size() - int(offer["level"])
		"passive":
			room = GameData.passives[offer["id"]]["levels"].size() - int(offer["level"])
	var forced := int(GameData.arg("--grade=", "-1"))
	var grade := 0
	if forced >= 0:
		grade = forced
	else:
		var r := randf()
		var luck := player.stat("luck")
		for g in [3, 2, 1]:
			if r < GRADE_CHANCE[g] * luck:
				grade = g
				break
	offer["grade"] = mini(grade, room)


## "weapon:ID" / "passive:ID" for banishing, "" if the card can't be.
static func banish_key(offer: Dictionary) -> String:
	if offer["kind"] in ["weapon", "passive"]:
		return "%s:%s" % [offer["kind"], offer["id"]]
	return ""


## Branches: from weapon level 3 one of three branches can be picked (the
## others then close); from level 6, or once evolved, it can reach rank 2.
static func _add_branch_offers(player: Player, pool: Array[Dictionary]) -> void:
	for weapon: Weapon in player.weapons.get_children():
		var branches: Dictionary = GameData.branches.get(weapon.base_id(), {})
		if branches.is_empty():
			continue
		var evolved: bool = weapon.data.get("evolved", false)
		if weapon.branch == "":
			if weapon.level >= BRANCH_FROM or evolved:
				for b: String in branches:
					pool.append({"kind": "branch", "id": weapon.id, "base": weapon.base_id(), "branch": b, "level": 1, "weight": 45})
		elif weapon.branch_rank == 1 and (weapon.level >= BRANCH_RANK2_FROM or evolved):
			pool.append({"kind": "branch", "id": weapon.id, "branch": weapon.branch, "level": 2, "weight": 60})


static func apply(player: Player, offer: Dictionary) -> void:
	match offer["kind"]:
		"branch":
			player.choose_branch(offer["id"], offer["branch"])
		"weapon":
			if offer["level"] == 1:
				player.add_weapon(offer["id"])
			else:
				player.level_up_weapon(offer["id"])
			for i in int(offer.get("grade", 0)):
				player.level_up_weapon(offer["id"])
		"passive":
			for i in 1 + int(offer.get("grade", 0)):
				player.add_passive(offer["id"])
		"heal":
			player.heal(HEAL_AMOUNT)


## Opens a treasure chest: evolves a ready weapon first, otherwise levels up
## random owned items. Returns the applied offers (evolutions have
## "evolved": true) for the treasure screen.
static func open_chest(player: Player, count: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for i in count:
		var evo := find_evolution(player)
		if not evo.is_empty():
			player.evolve_weapon(evo["from"], evo["into"])
			results.append({"kind": "weapon", "id": evo["into"], "level": 1, "evolved": true})
			continue
		var offer: Dictionary = roll(player, 1, true)[0]
		apply(player, offer)
		results.append(offer)
	return results


## A weapon at max level whose partner passive is owned, or {} if none.
static func find_evolution(player: Player) -> Dictionary:
	for weapon: Weapon in player.weapons.get_children():
		var evolve: Dictionary = weapon.data.get("evolve", {})
		if evolve.is_empty() or weapon.level < weapon.max_level():
			continue
		if player.passives.has(evolve["with"]):
			return {"from": weapon.id, "into": evolve["into"]}
	return {}


static func _has_evolution_of(player: Player, id: String) -> bool:
	var evolve: Dictionary = GameData.weapons[id].get("evolve", {})
	return not evolve.is_empty() and player.get_weapon(evolve["into"]) != null


## Ids an offer touches, for marking them in the "your weapons" box: the
## item itself and, for a passive, the weapons it can evolve.
static func related_ids(offers: Array[Dictionary]) -> Array:
	var ids := []
	for offer in offers:
		ids.append(offer["id"])
		if offer["kind"] == "passive":
			for id: String in GameData.weapons:
				if GameData.weapons[id].get("evolve", {}).get("with", "") == offer["id"]:
					ids.append(id)
	return ids


## Lines for a card about what the cat already has: the weapon's current
## level, or for a passive the weapons it evolves and whether the cat has
## them. Each line is [text, owned].
static func owned_notes(player: Player, offer: Dictionary) -> Array:
	var notes := []
	match offer["kind"]:
		"weapon", "branch":
			var w := player.get_weapon(offer["id"])
			if w != null:
				notes.append([_t("CARD_OWNED") % [w.level, w.max_level()], true])
			else:
				notes.append([_t("CARD_NOT_OWNED"), false])
		"passive":
			for id: String in GameData.weapons:
				if GameData.weapons[id].get("evolve", {}).get("with", "") != offer["id"]:
					continue
				var w := player.get_weapon(id)
				var into: String = GameData.weapons[id]["evolve"]["into"]
				if w == null and player.get_weapon(into) != null:
					notes.append([_t("CARD_EVOLVED_ALREADY") % [item_name("weapon", id), item_name("weapon", into)], true])
				elif w != null:
					notes.append([_t("CARD_EVOLVES_HAVE") % [item_name("weapon", id), w.level, w.max_level()], true])
				else:
					notes.append([_t("CARD_EVOLVES_MISSING") % item_name("weapon", id), false])
	return notes


## Translated name of a weapon or passive.
static func item_name(kind: String, id: String) -> String:
	return _t("%s_%s_NAME" % [kind.to_upper(), id])


static func title(offer: Dictionary) -> String:
	if offer["kind"] == "heal":
		return _t("HEAL_NAME")
	if offer["kind"] == "branch":
		return _t("BRANCH_%s_NAME" % offer["branch"])
	return item_name(offer["kind"], offer["id"])


static func tag(offer: Dictionary) -> String:
	if offer["kind"] == "heal":
		return ""
	if offer["kind"] == "branch":
		return "%s · %s" % [_t("TAG_BRANCH_2" if offer["level"] == 2 else "TAG_BRANCH"), item_name("weapon", offer["id"])]
	var grade := int(offer.get("grade", 0))
	if grade > 0:
		return _t("GRADE_%d" % grade) % (int(offer["level"]) + grade)
	if offer["level"] == 1:
		return _t("TAG_NEW")
	return _t("TAG_LEVEL") % offer["level"]


## `pair_hint` = false leaves out "Can evolve X" (the card shows it with owned_notes).
static func description(offer: Dictionary, pair_hint: bool = true) -> String:
	var text := _base_description(offer)
	var hint := _evolution_hint(offer) if pair_hint or offer["kind"] != "passive" else ""
	return text if hint == "" else "%s
%s" % [text, hint]


## Tells which passive evolves a weapon (shown at its last level) and which
## weapon a passive can evolve.
static func _evolution_hint(offer: Dictionary) -> String:
	match offer["kind"]:
		"weapon":
			var data: Dictionary = GameData.weapons[offer["id"]]
			var evolve: Dictionary = data.get("evolve", {})
			if not evolve.is_empty() and offer["level"] == data["levels"].size():
				return _t("EVOLVE_HINT") % item_name("passive", evolve["with"])
		"passive":
			var names: Array[String] = []
			for id: String in GameData.weapons:
				var evolve: Dictionary = GameData.weapons[id].get("evolve", {})
				if evolve.get("with", "") == offer["id"]:
					names.append(item_name("weapon", id))
			if not names.is_empty():
				return _t("EVOLVE_PAIR") % ", ".join(names)
	return ""


static func _base_description(offer: Dictionary) -> String:
	var kind: String = offer["kind"]
	if kind == "branch":
		var desc := _t("BRANCH_%s_DESC" % offer["branch"])
		if offer["level"] == 2:
			return _t("BRANCH_RANK2") % desc
		# Name the branches that close, so the pick is clear.
		var others: Array[String] = []
		for b: String in GameData.branches.get(offer.get("base", offer["id"]), {}):
			if b != offer["branch"]:
				others.append(_t("BRANCH_%s_NAME" % b))
		return "%s\n%s" % [desc, _t("BRANCH_CHOOSE") % ", ".join(others)]
	if kind == "heal":
		return _t("HEAL_DESC") % HEAL_AMOUNT
	if kind == "passive" or offer["level"] == 1:
		return _t("%s_%s_DESC" % [kind.to_upper(), offer["id"]])
	var lv: Dictionary = GameData.weapons[offer["id"]]["levels"][offer["level"] - 1]
	var parts: Array[String] = []
	for key: String in lv:
		if not STAT_TEXT.has(key):
			continue
		var value: float = lv[key]
		var shown: String
		if key in PERCENT_STATS:
			shown = str(roundi(value * 100.0))
		elif key == "interval" or key == "freeze":
			shown = ("%+.1f" % value).replace(".", _t("DECIMAL_SEP"))
		else:
			shown = str(roundi(value))
		parts.append(_t(STAT_TEXT[key]) % shown)
	return ", ".join(parts)


static func _t(key: String) -> String:
	return String(TranslationServer.translate(key))


static func _weighted_pick(pool: Array[Dictionary]) -> int:
	var total := 0.0
	for o in pool:
		total += float(o["weight"])
	var r := randf() * total
	for i in pool.size():
		r -= float(pool[i]["weight"])
		if r <= 0.0:
			return i
	return pool.size() - 1
