class_name Items
## Gear the cat wears (data/items.json): five slots, a base item per slot
## with its own main stat, and a rarity. A common item has just its main
## stat; a rare one is stronger and rolls one more random stat. Every final
## boss drops its own legendary item with fixed stats and an ability.
## An item is a Dictionary: {"uid", "base", "slot", "rarity", "stats"}.

## Stats shown as a percentage (the rest are flat numbers).
const PERCENT := ["might", "speed", "area", "cooldown", "greed", "luck", "crit_chance", "crit_mult", "duration", "proj_speed", "growth"]
## Ability timers: two items with one keep the shorter, they don't add up.
const TIMERS := ["freeze_every", "pulse_magnet"]


static func data() -> Dictionary:
	return GameData.items


static func slots() -> Array:
	return data()["slots"]


## A random item; `luck` makes rare ones likelier, `rarity` forces one.
static func roll(luck: float = 1.0, rarity: String = "") -> Dictionary:
	if rarity == "":
		rarity = pick_rarity(luck)
	var bases: Array = data()["bases"].keys()
	var base: String = bases.pick_random()
	var info: Dictionary = data()["bases"][base]
	var r: Dictionary = data()["rarities"][rarity]
	var stats := {}
	var main: String = info["stat"]
	stats[main] = _roll_value(main, float(r["mult"]))
	var others: Array = data()["affixes"].keys().filter(func(s: String) -> bool: return s != main)
	others.shuffle()
	for i in int(r["extra"]):
		stats[others[i]] = _roll_value(others[i], float(r["mult"]))
	return {"uid": 0, "base": base, "slot": info["slot"], "rarity": rarity, "stats": stats}


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
	return {"uid": 0, "base": id, "slot": info["slot"], "rarity": "legendary", "stats": (info["stats"] as Dictionary).duplicate()}


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
	return TranslationServer.translate("ITEM_%s_NAME" % item.get("base", ""))


## "+6 % damage" for one stat of an item.
static func stat_text(stat: String, value: float) -> String:
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
	lines.append("%s · %s" % [TranslationServer.translate("RARITY_" + String(item["rarity"]).to_upper()), TranslationServer.translate("ITEM_SLOT_" + String(item["slot"]))])
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
	return "\n".join(lines)


## Gold for melting an item down.
static func salvage_gold(item: Dictionary) -> int:
	return int(data()["rarities"][item.get("rarity", "common")]["salvage"])


## A rough worth, to keep the best item when only one can be saved.
static func worth(item: Dictionary) -> int:
	return {"common": 1, "rare": 2, "legendary": 3}.get(item.get("rarity", "common"), 1)
