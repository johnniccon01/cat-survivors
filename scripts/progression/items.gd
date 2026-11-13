class_name Items
## Gear the cats wear (data/items.json, shared by all cats): eight slots, a
## base item per slot with its own main stat, a rarity and an item level.
## Common has just its main stat; uncommon, rare and epic roll 1, 2 or 3
## more stats and are stronger; an epic one may belong to a set. Extra stats
## can be for one weapon ("+18 % damage: Yarn", "+1 projectile: Feather").
## The item level comes from the map (and its darkness) it was found on and
## makes every number bigger. Every final boss drops its own legendary item
## with fixed stats and an ability; dreams drop dream gear of dream sets.
## An item is a Dictionary: {"uid", "base", "slot", "rarity", "stats",
## "ilvl", and maybe "set" and "locked"}.

## Stats shown as a percentage (the rest are flat numbers).
const PERCENT := ["low_hp_guard", "might", "speed", "area", "cooldown", "greed", "luck", "crit_chance", "crit_mult", "duration", "proj_speed", "growth", "boss_damage", "heal_power"]
## Rarities from worst to best (for sorting and worth).
const ORDER := ["common", "uncommon", "rare", "epic", "dream", "legendary"]
## Each item level above 1 makes the item's numbers this much bigger.
const LEVEL_STEP := 0.06
const MAX_LEVEL := 15
## Share of the extra stats that are for one weapon.
const WEAPON_AFFIX_CHANCE := 0.3
## Ability timers: two items with one keep the shorter, they don't add up.
const TIMERS := ["freeze_every", "pulse_magnet"]


static func data() -> Dictionary:
	return GameData.items


static func slots() -> Array:
	return data()["slots"]


## A random item; `luck` makes the better rarities likelier, `rarity`
## forces one, `ilvl` is the item level (see item_level).
static func roll(luck: float = 1.0, rarity: String = "", ilvl: int = 1) -> Dictionary:
	if rarity == "":
		rarity = pick_rarity(luck)
	var bases: Array = data()["bases"].keys()
	var base: String = bases.pick_random()
	var info: Dictionary = data()["bases"][base]
	var r: Dictionary = data()["rarities"][rarity]
	ilvl = clampi(ilvl, 1, MAX_LEVEL)
	var mult := float(r["mult"]) * (1.0 + LEVEL_STEP * (ilvl - 1))
	var stats := {}
	var main: String = info["stat"]
	stats[main] = _roll_value(main, mult)
	var others: Array = data()["affixes"].keys().filter(func(st: String) -> bool: return st != main)
	others.shuffle()
	for i in int(r["extra"]):
		if randf() < WEAPON_AFFIX_CHANCE:
			var key := _weapon_affix(rarity)
			if not stats.has(key):
				stats[key] = _roll_value(key, mult)
				continue
		stats[others[i]] = _roll_value(others[i], mult)
	var item := {"uid": 0, "base": base, "slot": info["slot"], "rarity": rarity, "stats": stats, "ilvl": ilvl}
	# Dream gear always belongs to a dream set; epic gear may belong to one of
	# the sets that drop at night. Two or three pieces of a set worn give a
	# bonus on top (SETS).
	if rarity == "dream":
		item["set"] = DREAM_SETS.pick_random()
	elif randf() < float(r.get("set_chance", 0.0)):
		item["set"] = NIGHT_SETS.pick_random()
	return item


## A stat for one weapon: "wd:YARN" (more damage) or, rarer and only on
## rare gear and better, "wa:YARN" (one more projectile).
static func _weapon_affix(rarity: String) -> String:
	var ids: Array = GameData.weapons.keys().filter(func(id: String) -> bool: return not GameData.weapons[id].get("evolved", false))
	var weapon: String = ids.pick_random()
	if ORDER.find(rarity) >= ORDER.find("rare") and randf() < 0.25:
		return "wa:" + weapon
	return "wd:" + weapon


## The item level of gear found tonight: grows over the maps in their order
## (1 on the first, 10 on the last) and with the darkness and dream depth.
static func item_level(stage_id: String, darkness: int = 0, dream_depth: int = 0) -> int:
	var ids: Array = GameData.stages.keys()
	var i := maxi(ids.find(stage_id), 0)
	var base := 1 + floori(float(i) * 9.0 / maxf(ids.size() - 1, 1))
	return clampi(base + darkness + dream_depth / 2, 1, MAX_LEVEL)


static func pick_rarity(luck: float = 1.0) -> String:
	var total := 0.0
	var weights := {}
	for id: String in data()["rarities"]:
		var w := float(data()["rarities"][id]["weight"])
		if id != "common":
			w *= luck
		weights[id] = w
		total += w
	var x := randf() * total
	for id: String in weights:
		x -= weights[id]
		if x < 0.0:
			return id
	return "common"


static func _roll_value(stat: String, mult: float) -> float:
	if ":" in stat:
		var kind := stat.get_slice(":", 0)
		if kind == "wa":
			return 1.0
		var wr: Array = data()["weapon_affixes"][kind]
		return snappedf(randf_range(float(wr[0]), float(wr[1])) * mult, 0.01)
	var range_: Array = data()["affixes"][stat]
	var v := randf_range(float(range_[0]), float(range_[1])) * mult
	# Flat stats in whole numbers (armor 1-2, +18 health), the rest rounded.
	if stat in PERCENT or stat == "regen":
		return snappedf(v, 0.01)
	return float(roundi(v))


## The legendary item a boss drops ("" when it has none).
static func legendary_of(boss_id: String) -> String:
	for id: String in data()["legendaries"]:
		if data()["legendaries"][id]["boss"] == boss_id:
			return id
	return ""


static func legendary(id: String) -> Dictionary:
	var info: Dictionary = data()["legendaries"][id]
	return {"uid": 0, "base": id, "slot": info["slot"], "rarity": "legendary", "stats": (info["stats"] as Dictionary).duplicate(), "ilvl": 1}


static func info(item: Dictionary) -> Dictionary:
	var base: String = item.get("base", "")
	if data()["legendaries"].has(base):
		return data()["legendaries"][base]
	return data()["bases"].get(base, {})


static func color(item: Dictionary) -> Color:
	return Color(info(item).get("color", "#ffffff"))


static func rarity_color(item: Dictionary) -> Color:
	return Color(data()["rarities"][item.get("rarity", "common")]["color"])


static func item_name(item: Dictionary) -> String:
	var name := TranslationServer.translate("ITEM_%s_NAME" % item.get("base", ""))
	if item.has("set"):
		return TranslationServer.translate("SET_%s_ITEM" % item["set"]) % name
	return name


## Sets: the bonus for two pieces worn (three give it twice). The dream
## sets drop only in Cat Dreams, the others on epic gear at night.
const SETS := {
	"MOON": {"crit_chance": 0.08, "crit_mult": 0.2},
	"STAR": {"might": 0.1, "area": 0.06},
	"CLOUD": {"max_hp": 30.0, "regen": 0.5},
	"SAILOR": {"greed": 0.12, "luck": 0.08},
	"HUNTER": {"crit_chance": 0.06, "boss_damage": 0.1},
	"GUARDIAN": {"armor": 2.0, "max_hp": 25.0},
	"STORM": {"cooldown": -0.05, "proj_speed": 0.12},
	"GARDEN": {"regen": 0.4, "heal_power": 0.12},
	"NIGHT": {"might": 0.08, "speed": 0.06},
}
const DREAM_SETS := ["MOON", "STAR", "CLOUD"]
const NIGHT_SETS := ["SAILOR", "HUNTER", "GUARDIAN", "STORM", "GARDEN", "NIGHT"]


## The set bonus of the items worn: {stat: value}.
static func set_bonus(worn: Array) -> Dictionary:
	var count := {}
	for item: Dictionary in worn:
		if item.has("set"):
			count[item["set"]] = int(count.get(item["set"], 0)) + 1
	var out := {}
	for set_id: String in count:
		var times := 0 if count[set_id] < 2 else (1 if count[set_id] < 3 else 2)
		for stat: String in SETS.get(set_id, {}):
			out[stat] = float(out.get(stat, 0.0)) + float(SETS[set_id][stat]) * times
	return out


## "+6 % damage" for one stat of an item.
static func stat_text(stat: String, value: float) -> String:
	if ":" in stat:
		var weapon := Upgrades.item_name("weapon", stat.get_slice(":", 1))
		if stat.begins_with("wa:"):
			return TranslationServer.translate("ISTAT_WA") % [str(roundi(value)), weapon]
		return TranslationServer.translate("ISTAT_WD") % [str(roundi(value * 100.0)), weapon]
	var key := "ISTAT_" + stat.to_upper()
	if stat == "cooldown":
		return TranslationServer.translate(key) % str(roundi(-value * 100.0))
	if stat in PERCENT:
		return TranslationServer.translate(key) % str(roundi(value * 100.0))
	if stat == "regen":
		return TranslationServer.translate(key) % str(snappedf(value, 0.01))
	return TranslationServer.translate(key) % str(roundi(value))


## What the item does, one line per stat (a legendary describes its ability).
static func describe(item: Dictionary) -> String:
	var lines: Array[String] = []
	var head := "%s · %s" % [TranslationServer.translate("RARITY_" + String(item["rarity"]).to_upper()), TranslationServer.translate("ITEM_SLOT_" + String(item["slot"]))]
	if item.get("rarity", "") != "legendary":
		head += " · " + TranslationServer.translate("ITEM_LEVEL") % int(item.get("ilvl", 1))
	lines.append(head)
	if item["rarity"] == "legendary":
		lines.append(TranslationServer.translate("ITEM_%s_DESC" % item["base"]))
		if item["base"] == Profile.SOUL_BELL:
			var b := Profile.soul_bonus(Profile.soul_charge)
			lines.append(TranslationServer.translate("SOUL_BELL_CHARGE") % [roundi(Profile.soul_charge), roundi(Profile.SOUL_FULL), roundi(float(b["might"]) * 100.0), roundi(float(b["greed"]) * 100.0)])
		return "\n".join(lines)
	var stats: Dictionary = item["stats"]
	var parts: Array[String] = []
	for stat: String in stats:
		parts.append(stat_text(stat, float(stats[stat])))
	lines.append(", ".join(parts))
	if item.has("set"):
		var bonus: Array[String] = []
		for stat: String in SETS.get(item["set"], {}):
			bonus.append(stat_text(stat, float(SETS[item["set"]][stat])))
		lines.append(TranslationServer.translate("ITEM_SET_BONUS") % [TranslationServer.translate("SET_%s_NAME" % item["set"]), ", ".join(bonus)])
	return "\n".join(lines)


## How the chosen item compares with the one worn: [[stat, difference]]
## for every stat either has, in a steady order.
static func compare(item: Dictionary, worn: Dictionary) -> Array:
	var a: Dictionary = item.get("stats", {})
	var b: Dictionary = worn.get("stats", {})
	var keys: Array = a.keys()
	for k: String in b:
		if k not in keys:
			keys.append(k)
	var out: Array = []
	for k: String in keys:
		out.append([k, float(a.get(k, 0.0)) - float(b.get(k, 0.0))])
	return out


## Gold for melting an item down.
static func salvage_gold(item: Dictionary) -> int:
	return int(data()["rarities"][item.get("rarity", "common")]["salvage"])


## A rough worth, to keep the best item when only one can be saved.
static func worth(item: Dictionary) -> int:
	return (ORDER.find(item.get("rarity", "common")) + 1) * 100 + int(item.get("ilvl", 1))


# --- Workshop (see WorkshopPanel): what the four workshops do to an item -----

## Each district's workshop and what it does.
const WORKSHOPS := {"cats": "SEW", "dogs": "SMITH", "wild": "HERBS", "company": "LAB"}
## Rarities the laboratory can raise an item through.
const RAISE := ["common", "uncommon", "rare", "epic"]
const RAISE_COST := [100, 200, 350]


## Whether `action` can be done to `item` ("" if it can, else why not, as a
## translation key).
static func work_problem(item: Dictionary, action: String) -> String:
	if item.is_empty():
		return "ITEMS_EMPTY"
	if item.get("rarity", "") in ["legendary"]:
		return "WORKSHOP_NOT_LEGENDARY"
	match action:
		"SMITH":
			if int(item.get("ilvl", 1)) >= MAX_LEVEL:
				return "WORKSHOP_MAX_LEVEL"
		"SEW":
			if _extras(item).is_empty():
				return "WORKSHOP_NO_EXTRA"
		"HERBS":
			if item.get("enchanted", false):
				return "WORKSHOP_ALREADY_ADDED"
		"LAB":
			if item.get("rarity", "") not in RAISE or item["rarity"] == RAISE[-1]:
				return "WORKSHOP_MAX_RARITY"
	return ""


## Material it costs.
static func work_cost(item: Dictionary, action: String) -> int:
	match action:
		"SMITH":
			return 30 + 15 * int(item.get("ilvl", 1))
		"SEW":
			return 60
		"HERBS":
			return 120
		"LAB":
			var i := RAISE.find(String(item.get("rarity", "")))
			return RAISE_COST[clampi(i, 0, RAISE_COST.size() - 1)]
	return 0


## Material back for taking an item apart (more for better ones).
static func salvage_materials(item: Dictionary) -> int:
	return maxi(5, roundi(salvage_gold(item) * 0.6 + int(item.get("ilvl", 1)) * 2))


## Does `action` to `item` (in place). Check work_problem first.
static func work(item: Dictionary, action: String) -> void:
	var stats: Dictionary = item["stats"]
	match action:
		"SMITH":
			var old := int(item.get("ilvl", 1))
			_scale(stats, (1.0 + LEVEL_STEP * old) / (1.0 + LEVEL_STEP * (old - 1)))
			item["ilvl"] = old + 1
		"SEW":
			var extras := _extras(item)
			var gone: String = extras.pick_random()
			stats.erase(gone)
			var key := _new_stat(item)
			stats[key] = _roll_value(key, _mult(item))
		"HERBS":
			var key := _new_stat(item)
			stats[key] = _roll_value(key, _mult(item))
			item["enchanted"] = true
		"LAB":
			var from: String = item["rarity"]
			var to: String = RAISE[RAISE.find(from) + 1]
			_scale(stats, float(data()["rarities"][to]["mult"]) / float(data()["rarities"][from]["mult"]))
			item["rarity"] = to
			var key := _new_stat(item)
			stats[key] = _roll_value(key, _mult(item))
			if to == "epic" and not item.has("set") and randf() < float(data()["rarities"]["epic"].get("set_chance", 0.0)):
				item["set"] = NIGHT_SETS.pick_random()


## The stats an item has besides its main one.
static func _extras(item: Dictionary) -> Array:
	var main: String = info(item).get("stat", "")
	return (item["stats"] as Dictionary).keys().filter(func(k: String) -> bool: return k != main)


## The size an item's new stat rolls at (its rarity and level).
static func _mult(item: Dictionary) -> float:
	return float(data()["rarities"][item["rarity"]]["mult"]) * (1.0 + LEVEL_STEP * (int(item.get("ilvl", 1)) - 1))


## A stat the item doesn't have yet (sometimes one for a weapon).
static func _new_stat(item: Dictionary) -> String:
	var stats: Dictionary = item["stats"]
	if randf() < WEAPON_AFFIX_CHANCE:
		var key := _weapon_affix(item["rarity"])
		if not stats.has(key):
			return key
	var free: Array = data()["affixes"].keys().filter(func(k: String) -> bool: return not stats.has(k))
	return free.pick_random() if not free.is_empty() else data()["affixes"].keys().pick_random()


## Makes every number bigger by `k` (flat stats stay whole, +1 projectile stays 1).
static func _scale(stats: Dictionary, k: float) -> void:
	for key: String in stats.keys():
		if key.begins_with("wa:"):
			continue
		var v := float(stats[key]) * k
		stats[key] = snappedf(v, 0.01) if (key in PERCENT or key == "regen" or key.begins_with("wd:")) else float(roundi(v))
