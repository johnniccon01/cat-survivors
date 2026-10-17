class_name Achievements
## Achievements (data/achievements.json): one-time badges with no reward,
## just the pride. Each has one condition:
##   stats + target   the sum of lifetime counters reaches target
##   all_stats        every listed counter is at least 1
##   flag / all_flags a flag, or every listed flag, is set
##   flags_prefix     how many flags start with the prefix (target)
##   chains           how many stories are finished (target, or "all")
##   cats / artifacts how many cats are unlocked / artifacts owned (target)
## "secret" ones show as ??? until earned. Profile.achievements keeps the
## earned ids.


static func all() -> Dictionary:
	return GameData.achievements


static func is_earned(id: String) -> bool:
	return id in Profile.achievements


static func target(id: String) -> int:
	var a: Dictionary = all()[id]
	if a.has("all_stats"):
		return (a["all_stats"] as Array).size()
	if a.has("all_flags"):
		return (a["all_flags"] as Array).size()
	if a.get("all", false) and a.has("chains"):
		return GameData.chains.size()
	return int(a.get("target", 1))


static func progress(id: String) -> int:
	var a: Dictionary = all()[id]
	if a.has("stats"):
		var total := 0
		for key: String in a["stats"]:
			total += Profile.get_stat(key)
		return total
	if a.has("all_stats"):
		return (a["all_stats"] as Array).filter(func(k: String) -> bool: return Profile.get_stat(k) > 0).size()
	if a.has("flag"):
		return 1 if Profile.has_flag(a["flag"]) else 0
	if a.has("all_flags"):
		return (a["all_flags"] as Array).filter(func(f: String) -> bool: return Profile.has_flag(f)).size()
	if a.has("flags_prefix"):
		var prefix: String = a["flags_prefix"]
		return Profile.flags.filter(func(f: String) -> bool: return f.begins_with(prefix)).size()
	if a.has("chains"):
		return GameData.chains.keys().filter(func(c: String) -> bool: return ChainStep.is_done(c)).size()
	if a.has("cats"):
		return GameData.cats.keys().filter(func(c: String) -> bool: return not GameData.cats[c].get("npc", false) and Profile.is_unlocked(c)).size()
	if a.has("artifacts"):
		return Profile.artifacts.size()
	return 0


## Marks every newly reached achievement as earned and returns their ids.
static func check() -> Array[String]:
	var earned: Array[String] = []
	for id: String in all():
		if not is_earned(id) and progress(id) >= target(id):
			Profile.achievements.append(id)
			earned.append(id)
	if not earned.is_empty():
		Profile.save()
	return earned
