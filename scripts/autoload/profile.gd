extends Node
## Progress that survives between runs: gold, bought power-ups, unlocked
## cats, cleared stages, story flags and the last picked cat and stage.
## Stored in user://profile.cfg.

const PATH := "user://profile.cfg"
## The previous save, kept in case the main file gets damaged.
const BACKUP := "user://profile.bak.cfg"

var unlocked: Array[String] = []
var selected_cat := "MICA"
var selected_stage := "LIVING_ROOM"
var cleared_stages: Array[String] = []
var flags: Array[String] = []
var gold := 0
## Successful escapes/wins in a row (a death resets it) and the record.
var streak := 0
## Charms found and brought home, and the ones worn on the collar.
const CHARM_SLOTS := 3
## Gold given instead when you bring home a charm you already own.
const DUPLICATE_CHARM_GOLD := 50
var charms: Array[String] = []
## Charm quality 1-4 (Death Must Die-like item quality): each step above 1
## makes the charm 35 % stronger. Finding a better copy upgrades yours.
const MAX_CHARM_QUALITY := 4
const CHARM_QUALITY_STEP := 0.35
var charm_quality: Dictionary = {}
## Lifetime counters for long-term goals ("kills", "kills:SOCK", "escapes"...)
var stats: Dictionary = {}
var goals_done: Array[String] = []
var equipped_charms: Array[String] = []
var best_streak := 0
## Gold spent on power-ups (refunded in full on request).
var spent := 0
## power-up id -> bought rank
var powerups: Dictionary = {}
## Quest book: line id -> steps done
var questbook: Dictionary = {}
## Challenges switched on for the next nights.
var challenges: Array[String] = []
## Artifacts earned from the quest book, and the ones taken into the night.
const ARTIFACT_SLOTS := 2
var artifacts: Array[String] = []
var equipped_artifacts: Array[String] = []
## Gear (see Items): every item you own, which one is worn in each slot
## (slot -> uid), and the next uid to give out. The stash holds ITEM_STASH
## items; anything brought home past that is melted into gold.
const ITEM_STASH := 40
## At most this many legendary items worn at once.
const LEGENDARY_WORN := 2
var items: Array = []
var equipped_items: Dictionary = {}
var next_item_uid := 1
## The daily night: while it runs, `challenges` holds today's challenges and
## the player's own choice waits in _daily_backup (and is what gets saved).
const DAILY_GOLD := 500
var daily := false
var _daily_backup: Array[String] = []
## Quest chains: chain id -> steps done.
var chains: Dictionary = {}
## Earned achievement ids.
var achievements: Array[String] = []
## Darkness (Death Must Die-like): per map, the level picked for the next
## night and the highest level won there. Each level makes enemies tougher
## and pays more gold; winning one opens the next.
const MAX_DARKNESS := 5
var darkness: Dictionary = {}
var darkness_best: Dictionary = {}


func _ready() -> void:
	var cfg := ConfigFile.new()
	# Automated tests start from a fresh profile, so their results don't depend
	# on how far the player has got.
	var args := GameData.args()
	var fresh := "--bot" in args or "--ui-test" in args
	var loaded := false
	if not fresh:
		loaded = cfg.load(PATH) == OK
		if not loaded and FileAccess.file_exists(BACKUP):
			# The profile is missing or broken: fall back to the last good one.
			loaded = cfg.load(BACKUP) == OK
			if loaded:
				push_warning("Profile: %s could not be read, using the backup" % PATH)
	if loaded:
		for id: String in cfg.get_value("cats", "unlocked", []):
			unlocked.append(id)
		selected_cat = cfg.get_value("cats", "selected", selected_cat)
		selected_stage = cfg.get_value("stages", "selected", selected_stage)
		for id: String in cfg.get_value("stages", "cleared", []):
			cleared_stages.append(id)
		darkness = cfg.get_value("darkness", "selected", {})
		darkness_best = cfg.get_value("darkness", "best", {})
		for flag: String in cfg.get_value("story", "flags", []):
			flags.append(flag)
		gold = cfg.get_value("shop", "gold", 0)
		streak = cfg.get_value("streak", "current", 0)
		for id: String in cfg.get_value("charms", "owned", []):
			charms.append(id)
		charm_quality = cfg.get_value("charms", "quality", {})
		stats = cfg.get_value("stats", "counters", {})
		for id: String in cfg.get_value("stats", "goals_done", []):
			goals_done.append(id)
		for id: String in cfg.get_value("charms", "equipped", []):
			equipped_charms.append(id)
		best_streak = cfg.get_value("streak", "best", 0)
		spent = cfg.get_value("shop", "spent", 0)
		powerups = cfg.get_value("shop", "powerups", {})
		questbook = cfg.get_value("questbook", "steps", {})
		for id: String in cfg.get_value("challenge", "active", []):
			if GameData.challenges.has(id):
				challenges.append(id)
		for r: Dictionary in cfg.get_value("reports", "list", []):
			if GameData.stages.has(r.get("stage", "")):
				reports.append(r)
		report_news = cfg.get_value("reports", "news", [])
		siege_calm = cfg.get_value("reports", "calm", 0)
		for c: String in cfg.get_value("residents", "services", []):
			services.append(c)
		kidnapped = cfg.get_value("residents", "kidnapped", "")
		for id: String in cfg.get_value("trip", "last", []):
			last_trip.append(id)
		for id: String in cfg.get_value("territory", "conquered", []):
			territories.append(id)
		moon_night = cfg.get_value("moon", "night", 0)
		weather_today = cfg.get_value("weather", "today", "")
		weather_tomorrow = cfg.get_value("weather", "tomorrow", "")
		moon_traps = cfg.get_value("moon", "traps", 0)
		for c: String in cfg.get_value("moon", "guards", []):
			moon_guards.append(c)
		for id: String in cfg.get_value("nemesis", "bosses", {}):
			if GameData.enemies.has(id):
				nemesis[id] = cfg.get_value("nemesis", "bosses", {})[id]
		chains = cfg.get_value("chains", "steps", {})
		for id: String in cfg.get_value("achievements", "earned", []):
			achievements.append(id)
		for id: String in cfg.get_value("artifacts", "owned", []):
			if GameData.artifacts.has(id):
				artifacts.append(id)
		items = cfg.get_value("items", "owned", [])
		equipped_items = cfg.get_value("items", "equipped", {})
		next_item_uid = cfg.get_value("items", "next_uid", 1)
		_clean_items()
		for id: String in cfg.get_value("artifacts", "equipped", []):
			if id in artifacts:
				equipped_artifacts.append(id)
	for id: String in GameData.cats:
		if GameData.cats[id].get("unlocked", false) and id not in unlocked:
			unlocked.append(id)
	if selected_cat not in unlocked:
		selected_cat = "MICA"
	if not is_stage_unlocked(selected_stage):
		selected_stage = "LIVING_ROOM"
	# Debug: `-- --cat=LUNA` / `-- --stage=BASEMENT` skip unlocking,
	# `-- --challenges=HYPER,GLASS` sets challenges for this run.
	for arg: String in GameData.args():
		if arg.begins_with("--challenges="):
			challenges.clear()
			for id in arg.trim_prefix("--challenges=").split(",", false):
				challenges.append(id)
		if arg == "--daily":
			start_daily()
		# `-- --chain-step=KIBBLE_THIEF:2` marks two steps of a chain done.
		if arg.begins_with("--chain-step="):
			var parts := arg.trim_prefix("--chain-step=").split(":")
			chains[parts[0]] = int(parts[1])
		# `-- --artifacts=HOURGLASS,THORN_COLLAR` owns and wears them.
		if arg.begins_with("--artifacts="):
			for id in arg.trim_prefix("--artifacts=").split(",", false):
				artifacts.append(id)
				equipped_artifacts.append(id)
		# `-- --gear=RAT_CROWN,rare` owns and wears those legendaries and
		# random items of those rarities.
		if arg.begins_with("--gear="):
			for id in arg.trim_prefix("--gear=").split(",", false):
				var item := Items.legendary(id) if GameData.items["legendaries"].has(id) else Items.roll(1.0, id)
				item["uid"] = next_item_uid
				next_item_uid += 1
				items.append(item)
				if item["rarity"] != "legendary" or legendaries_worn(item["slot"]) < LEGENDARY_WORN:
					equipped_items[item["slot"]] = item["uid"]
		if arg.begins_with("--cat="):
			selected_cat = arg.trim_prefix("--cat=")
		elif arg.begins_with("--stage="):
			selected_stage = arg.trim_prefix("--stage=")
	# `-- --moon` plays a full moon night with two traps and a guard (tests).
	if "--moon" in GameData.args():
		moon_night = MOON_CYCLE - 1
		moon_traps = 2
		moon_guards.assign(["LUNA"])
		start_moon()
	# `-- --service=OLD_CAT` buys that service for free; `--kidnapped=CAT`
	# and `--report=rescue` play a rescue night (tests).
	var service := GameData.arg("--service=", "")
	if RESIDENTS.has(service):
		services.append(service)
	var taken := GameData.arg("--kidnapped=", "")
	if RESIDENTS.has(taken):
		kidnapped = taken
	# `-- --nemesis=RAT_KING` makes that boss a nemesis (tests).
	var nem := GameData.arg("--nemesis=", "")
	if nem != "" and GameData.enemies.has(nem):
		nemesis[nem] = {"level": 1, "order": 1}
	# `-- --cleared=LIVING_ROOM,BASEMENT` marks maps as won (tests).
	for id in GameData.arg("--cleared=", "").split(",", false):
		if GameData.stages.has(id) and id not in cleared_stages:
			cleared_stages.append(id)
	ensure_weather()
	# `-- --report=defend` plays a night report of that kind (tests).
	var kind := GameData.arg("--report=", "")
	if kind != "":
		make_reports()
		for i in reports.size():
			if reports[i]["kind"] == kind:
				start_report(i)


func is_unlocked(cat_id: String) -> bool:
	return cat_id in unlocked


## Returns true if the cat was newly unlocked.
func unlock(cat_id: String) -> bool:
	if cat_id in unlocked:
		return false
	unlocked.append(cat_id)
	save()
	return true


func select(cat_id: String) -> void:
	selected_cat = cat_id
	save()


func select_stage(stage_id: String) -> void:
	selected_stage = stage_id
	save()


## The highest darkness that can be picked on a map: one above the best
## won there, once the map has been cleared at all.
func max_darkness(stage_id: String) -> int:
	if stage_id not in cleared_stages:
		return 0
	return mini(int(darkness_best.get(stage_id, 0)) + 1, MAX_DARKNESS)


## The darkness of the next night on `stage_id` (--darkness=N in tests;
## the daily night is always plain).
func darkness_for(stage_id: String) -> int:
	var forced := GameData.arg("--darkness=", "")
	if forced != "":
		return int(forced)
	if daily:
		return 0
	return clampi(int(darkness.get(stage_id, 0)), 0, max_darkness(stage_id))


func set_darkness(stage_id: String, level: int) -> void:
	darkness[stage_id] = clampi(level, 0, max_darkness(stage_id))
	save()


## Records a won darkness; true if it was a new best.
func win_darkness(stage_id: String, level: int) -> bool:
	if level <= int(darkness_best.get(stage_id, 0)):
		return false
	darkness_best[stage_id] = level
	save()
	return true


## A stage is open when the stage it requires has been cleared.
func is_stage_unlocked(stage_id: String) -> bool:
	var stage: Dictionary = GameData.stages.get(stage_id, {})
	var required: String = stage.get("requires", "")
	return required == "" or required in cleared_stages


## Returns true if this was the first clear.
func clear_stage(stage_id: String) -> bool:
	if stage_id in cleared_stages:
		return false
	cleared_stages.append(stage_id)
	save()
	return true


## Bumps a lifetime counter in memory (saved with the next save()).
func add_stat(key: String, amount: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + amount


func set_stat_max(key: String, value: int) -> void:
	stats[key] = maxi(int(stats.get(key, 0)), value)


## Counter value; a few are computed from other profile data.
func get_stat(key: String) -> int:
	match key:
		"best_streak":
			return best_streak
		"cats_unlocked":
			return unlocked.size()
	return int(stats.get(key, 0))


## Today's date, e.g. "2026-10-18" (the daily night's seed).
static func today() -> String:
	return Time.get_date_string_from_system()


## Today's map (an open one) and two challenges, the same all day.
func daily_plan() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("daily" + today())
	var maps: Array = GameData.stages.keys().filter(func(s: String) -> bool: return is_stage_unlocked(s))
	var pool: Array = GameData.challenges.keys()
	var picked: Array[String] = []
	while picked.size() < mini(2, pool.size()):
		var c: String = pool[rng.randi() % pool.size()]
		if c not in picked:
			picked.append(c)
	return {"stage": maps[rng.randi() % maps.size()], "challenges": picked, "seed": hash("night" + today())}


func start_daily() -> void:
	var plan := daily_plan()
	daily = true
	_daily_backup = challenges.duplicate()
	challenges.clear()
	for c: String in plan["challenges"]:
		challenges.append(c)
	selected_stage = plan["stage"]


func end_daily() -> void:
	if not daily:
		return
	daily = false
	challenges = _daily_backup.duplicate()
	_daily_backup.clear()


# --- night reports (the neighbourhood) ---------------------------------------
## Offers wait on the neighbourhood before every night: hold a map you won
## against a siege, hunt a boss, or a golden night. You play one (or any
## other night); the rest settle themselves: a golden night passes, a boss
## hunt waits a few nights. A siege is rare and patient: it comes only every
## few nights, on one of the maps you won last, and waits REPORT_DEFEND_NIGHTS
## nights before the map is robbed. Conquered maps are never besieged.

const REPORT_DEFEND_GOLD := 150
const REPORT_DEFEND_MINUTES := 10
## How many nights a siege waits for you before the map is robbed.
const REPORT_DEFEND_NIGHTS := 2
## Quiet nights after a siege before the next one: a random count in range.
const SIEGE_CALM := [2, 3]
const REPORT_HUNT_GOLD := 250
const REPORT_HUNT_NIGHTS := 3
## An undefended map loses this share of your gold, at most REPORT_THEFT_MAX.
const REPORT_THEFT := 0.05
const REPORT_THEFT_MAX := 120

## [{kind, stage, challenge, nights}]; kind is "defend", "hunt" or "gold".
var reports: Array = []
## The report played this night (index into `reports`), or -1.
var report := -1
## What happened to the other reports while you were out: [[key, args...]].
var report_news: Array = []
## Quiet nights left before the next siege can come.
var siege_calm := 0
var _report_backup: Array[String] = []
## True from start_report until the night's scene ends (challenges swapped).
var _report_on := false


## Tops the reports up to one of each kind, each on a different open map.
func make_reports() -> void:
	var open: Array = GameData.stages.keys().filter(func(s: String) -> bool: return is_stage_unlocked(s))
	if open.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var kinds := ["defend", "hunt", "gold"]
	# A night trip needs three open maps to wander through.
	if open.size() >= 3:
		kinds.append("trip")
	if kidnapped != "":
		kinds.push_front("rescue")
	for kind: String in kinds:
		if reports.any(func(r: Dictionary) -> bool: return r["kind"] == kind):
			continue
		# Sieges wait out their quiet nights (a test asking for one skips it).
		if kind == "defend" and siege_calm > 0 and GameData.arg("--report=", "") != "defend":
			continue
		var used: Array = reports.map(func(r: Dictionary) -> String: return r["stage"])
		var pool: Array = open.filter(func(s: String) -> bool: return s not in used)
		if kind == "defend":
			# Only the two maps won last, never a conquered one: nobody has to
			# go all the way back to the first maps to guard them.
			var held: Array = cleared_stages.filter(func(s: String) -> bool: return s in open and s not in territories)
			pool = held.slice(maxi(held.size() - 2, 0)).filter(func(s: String) -> bool: return s in pool)
		elif kind == "hunt" and pool.any(func(s: String) -> bool: return s not in cleared_stages):
			pool = pool.filter(func(s: String) -> bool: return s not in cleared_stages)
		if pool.is_empty():
			continue
		var all: Array = GameData.challenges.keys()
		reports.append({"kind": kind, "stage": pool[rng.randi() % pool.size()],
			"challenge": all[rng.randi() % all.size()] if not all.is_empty() and kind != "rescue" else "", "nights": 0})


func active_report() -> Dictionary:
	return reports[report] if report >= 0 and report < reports.size() else {}


## Plays report `i` tonight: its map, and its challenge instead of yours.
func start_report(i: int) -> void:
	if i < 0 or i >= reports.size():
		return
	report = i
	_report_on = true
	_report_backup = challenges.duplicate()
	challenges.clear()
	if reports[i]["challenge"] != "":
		challenges.append(reports[i]["challenge"])
	selected_stage = reports[i]["stage"]
	print("REPORT: %s on %s, challenge %s" % [reports[i]["kind"], selected_stage, reports[i]["challenge"]])


## The night's scene is gone: your own challenges come back.
func end_report() -> void:
	if not _report_on:
		return
	_report_on = false
	report = -1
	challenges = _report_backup.duplicate()
	_report_backup.clear()


## A night has passed: the played report is done, the others settle
## themselves, and new ones come in.
func pass_night() -> void:
	var keep: Array = []
	siege_calm = maxi(siege_calm - 1, 0)
	for i in reports.size():
		var r: Dictionary = reports[i]
		if i == report:
			if r["kind"] == "defend":
				siege_calm = randi_range(SIEGE_CALM[0], SIEGE_CALM[1])
			continue
		var place := TranslationServer.translate("STAGE_%s_NAME" % r["stage"])
		match r["kind"]:
			"defend":
				# The siege waits a while; only then is the map robbed.
				r["nights"] = int(r["nights"]) + 1
				if r["nights"] < REPORT_DEFEND_NIGHTS and r["stage"] not in territories:
					keep.append(r)
				else:
					if r["stage"] not in territories:
						report_news.append(raid(place))
					siege_calm = randi_range(SIEGE_CALM[0], SIEGE_CALM[1])
			"rescue":
				# A kidnapped friend waits for you as long as it takes.
				if kidnapped != "":
					keep.append(r)
			"gold":
				report_news.append(["REPORT_NEWS_GONE", place])
			_:
				r["nights"] = int(r["nights"]) + 1
				if r["nights"] < REPORT_HUNT_NIGHTS:
					keep.append(r)
	reports = keep
	services.clear()
	make_reports()
	_moon_night_passed()
	_weather_night_passed()
	# The played one is gone from the list now.
	report = -1
	save()


# --- residents of the neighbourhood -------------------------------------------
## Cats you have won over live in the neighbourhood and each offers a service
## for the next night, for gold. An undefended map gets a resident kidnapped
## (its service closes) until a rescue night brings it home.

## cat -> [service stats for one night, price in gold].
const RESIDENTS := {
	"OLD_CAT": [{"max_hp": 30.0, "regen": 0.5}, 60],
	"BOLT": [{"might": 0.15}, 100],
	"TUCKO": [{"reroll": 1.0, "banish": 1.0}, 50],
	"KAPITAN": [{"magnet": 50.0, "speed": 0.1}, 70],
	"CLOVER": [{"luck": 0.2}, 60],
}
const RESCUE_GOLD := 120

# --- conquered territory ------------------------------------------------------
## Take every flag of a map in one night and win it: the map is conquered and
## its bonus helps in every night after.
const TERRITORY_FLAGS := 3
const TERRITORY_BONUS := {
	"LIVING_ROOM": {"max_hp": 10.0}, "BASEMENT": {"magnet": 15.0}, "GARDEN": {"regen": 0.3},
	"ROOFTOP": {"speed": 0.05}, "SUPERMARKET": {"luck": 0.1}, "HARBOR": {"area": 0.05},
	"FACTORY": {"might": 0.05}, "PARK": {"growth": 0.05}, "CEMETERY": {"cooldown": -0.03}, "STATION": {"magnet": 15.0}, "ISLAND": {"proj_speed": 0.05},
}
var territories: Array[String] = []


func territory_bonus() -> Dictionary:
	var out := {}
	for id in territories:
		var b: Dictionary = TERRITORY_BONUS.get(id, {})
		for key: String in b:
			out[key] = float(out.get(key, 0.0)) + float(b[key])
	return out


func conquer(stage_id: String) -> bool:
	if stage_id in territories:
		return false
	territories.append(stage_id)
	save()
	return true


## The maps of the last night trip, in order (drawn on the neighbourhood).
var last_trip: Array[String] = []
const TRIP_GOLD := 200

## Services bought for the next night.
var services: Array[String] = []
## The resident held by the enemies ("" if none).
var kidnapped := ""


## Residents at home: unlocked, not your cat tonight, not kidnapped.
func residents() -> Array[String]:
	var out: Array[String] = []
	for cat: String in RESIDENTS:
		if is_unlocked(cat) and cat != kidnapped:
			out.append(cat)
	return out


func buy_service(cat: String) -> bool:
	if cat not in residents() or cat in services or gold < int(RESIDENTS[cat][1]):
		return false
	gold -= int(RESIDENTS[cat][1])
	services.append(cat)
	save()
	return true


## Stats from tonight's bought services.
func service_bonus() -> Dictionary:
	var out := {}
	for cat in services:
		var stats: Dictionary = RESIDENTS.get(cat, [{}])[0]
		for key: String in stats:
			out[key] = float(out.get(key, 0.0)) + float(stats[key])
	return out


## A map was not held: a resident is taken if there is one to take, or else
## you are robbed. Returns the news line ([key, args...]).
func raid(place: String) -> Array:
	var home := residents()
	if kidnapped == "" and not home.is_empty():
		kidnapped = home.pick_random()
		return ["REPORT_NEWS_KIDNAP", place, TranslationServer.translate("CAT_%s_NAME" % kidnapped)]
	var theft := mini(floori(gold * REPORT_THEFT), REPORT_THEFT_MAX)
	gold -= theft
	return ["REPORT_NEWS_THEFT", place, theft]


# --- the full moon ------------------------------------------------------------
## Every MOON_CYCLE nights the moon is full and every boss comes for your home
## at once. During the week you get ready: traps that only hurt enemies, and
## guard cats that fight beside you. Win the full moon night for a big
## reward; skip it or lose it and your home is raided.

const MOON_CYCLE := 7
const MOON_GOLD := 500
const MOON_THEFT := 0.1
const MOON_THEFT_MAX := 200
const MOON_TRAP_PRICE := 60
const MOON_TRAPS_MAX := 4
const MOON_GUARD_PRICE := 120
const MOON_GUARDS_MAX := 2

## Nights since the last full moon.
var moon_night := 0
var moon_traps := 0
var moon_guards: Array[String] = []
## Tonight is the full moon night (from start_moon until the scene ends).
var moon_on := false


func nights_to_moon() -> int:
	return maxi(MOON_CYCLE - 1 - moon_night, 0)


func moon_full() -> bool:
	return nights_to_moon() == 0


func start_moon() -> void:
	moon_on = true
	selected_stage = "LIVING_ROOM"
	print("MOON: full moon night, %d traps, guards %s" % [moon_traps, moon_guards])


func end_moon() -> void:
	moon_on = false


## Buys one trap for the full moon; false if there's no gold or no room.
func buy_moon_trap() -> bool:
	if moon_traps >= MOON_TRAPS_MAX or gold < MOON_TRAP_PRICE:
		return false
	gold -= MOON_TRAP_PRICE
	moon_traps += 1
	save()
	return true


## Calls one of your other cats to guard home on the full moon; "" if none.
func buy_moon_guard() -> String:
	if moon_guards.size() >= MOON_GUARDS_MAX or gold < MOON_GUARD_PRICE:
		return ""
	var pool: Array = unlocked.filter(func(c: String) -> bool:
		return c != selected_cat and c not in moon_guards and GameData.cats.has(c) and not GameData.cats[c].get("npc", false))
	if pool.is_empty():
		return ""
	var cat: String = pool.pick_random()
	gold -= MOON_GUARD_PRICE
	moon_guards.append(cat)
	save()
	return cat


# --- weather ------------------------------------------------------------------
## One weather for the whole neighbourhood each night, and a forecast for the
## next one (see Weather).
var weather_today := ""
var weather_tomorrow := ""


## Fills in the forecast the first time (old profiles have none).
func ensure_weather() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if weather_today == "":
		weather_today = "CLEAR"
	if weather_tomorrow == "":
		weather_tomorrow = Weather.pick(rng)


func _weather_night_passed() -> void:
	ensure_weather()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	weather_today = weather_tomorrow
	weather_tomorrow = Weather.pick(rng)


## The moon moves on after every night (pass_night).
func _moon_night_passed() -> void:
	if moon_on:
		moon_night = 0
	elif moon_full():
		# The full moon came and you weren't home.
		var theft := mini(floori(gold * MOON_THEFT), MOON_THEFT_MAX)
		gold -= theft
		report_news.append(["MOON_NEWS_RAIDED", theft])
		moon_night = 0
	else:
		moon_night += 1
		return
	moon_traps = 0
	moon_guards.clear()


# --- nemesis bosses ----------------------------------------------------------
## A boss that kills the cat remembers it: it becomes a nemesis, grows a level
## stronger with every kill (up to NEMESIS_MAX_LEVEL), may turn up in other
## nights to hunt you, and pays a big reward when you finally beat it.

const NEMESIS_MAX_LEVEL := 3
const NEMESIS_HUNT_CHANCE := 0.35
const NEMESIS_REVENGE_GOLD := 300
## Per level: more health, harder hits, faster.
const NEMESIS_HP := 0.2
const NEMESIS_DAMAGE := 0.1
const NEMESIS_SPEED := 0.08

## boss id -> {"level": int, "order": int} (order: the most recent is highest).
var nemesis: Dictionary = {}


## `boss_id` just killed the cat: it becomes (or grows as) a nemesis.
func add_nemesis(boss_id: String) -> int:
	var order := 0
	for id: String in nemesis:
		order = maxi(order, int(nemesis[id].get("order", 0)))
	var level := mini(int(nemesis.get(boss_id, {}).get("level", 0)) + 1, NEMESIS_MAX_LEVEL)
	nemesis[boss_id] = {"level": level, "order": order + 1}
	save()
	return level


func nemesis_level(boss_id: String) -> int:
	return int(nemesis.get(boss_id, {}).get("level", 0))


## The nemesis to show and to hunt you: the strongest, then the newest.
func top_nemesis() -> String:
	var best := ""
	for id: String in nemesis:
		if best == "" or [nemesis_level(id), int(nemesis[id]["order"])] > [nemesis_level(best), int(nemesis[best]["order"])]:
			best = id
	return best


func has_challenge(id: String) -> bool:
	return id in challenges


func toggle_challenge(id: String) -> void:
	if id in challenges:
		challenges.erase(id)
	else:
		challenges.append(id)
	save()


## Gold multiplier of all challenges switched on.
func challenge_gold() -> float:
	var mult := 1.0
	for id in challenges:
		mult *= float(GameData.challenges.get(id, {}).get("gold", 1.0))
	return mult


func has_charm(id: String) -> bool:
	return id in charms


func quality_of(id: String) -> int:
	return int(charm_quality.get(id, 1))


## How much stronger a charm of this quality is than a plain one.
static func quality_mult(quality: int) -> float:
	return 1.0 + CHARM_QUALITY_STEP * (quality - 1)


## Brings charms home after an escape or a win (`quality` matches `found`).
## A better copy of a charm you own upgrades it; any other copy pays gold.
## Returns the gold paid for duplicates; `upgraded` gets the improved ids.
func bank_charms(found: Array[String], quality: Array[int] = [], upgraded: Array[String] = []) -> int:
	var gold_back := 0
	for i in found.size():
		var id := found[i]
		var q: int = quality[i] if i < quality.size() else 1
		if id in charms:
			if q > quality_of(id):
				charm_quality[id] = q
				upgraded.append(id)
			else:
				gold_back += DUPLICATE_CHARM_GOLD
		else:
			charms.append(id)
			charm_quality[id] = q
	gold += gold_back
	save()
	return gold_back


## Wears or takes off a charm. Returns false when all slots are full.
func toggle_charm(id: String) -> bool:
	if not has_charm(id):
		return false
	if id in equipped_charms:
		equipped_charms.erase(id)
	elif equipped_charms.size() >= CHARM_SLOTS:
		return false
	else:
		equipped_charms.append(id)
	save()
	return true


func has_artifact(id: String) -> bool:
	return id in artifacts


## Returns true if the artifact is new.
func give_artifact(id: String) -> bool:
	if id in artifacts:
		return false
	artifacts.append(id)
	save()
	return true


## Takes an artifact along or leaves it home. Returns false when both slots
## are full.
func toggle_artifact(id: String) -> bool:
	if not has_artifact(id):
		return false
	if id in equipped_artifacts:
		equipped_artifacts.erase(id)
	elif equipped_artifacts.size() >= ARTIFACT_SLOTS:
		return false
	else:
		equipped_artifacts.append(id)
	save()
	return true


## Sum of the equipped artifacts per stat.
func artifact_bonus() -> Dictionary:
	var total := {}
	for id in equipped_artifacts:
		var bonus: Dictionary = GameData.artifacts.get(id, {}).get("stats", {})
		for key: String in bonus:
			total[key] = float(total.get(key, 0.0)) + float(bonus[key])
	return total


## Brings items home from a run (gets them uids). Past the stash size they
## are melted into gold; returns that gold.
func bank_items(found: Array) -> int:
	var gold_back := 0
	for item: Dictionary in found:
		if items.size() >= ITEM_STASH:
			gold_back += Items.salvage_gold(item)
			continue
		var kept := item.duplicate(true)
		kept["uid"] = next_item_uid
		next_item_uid += 1
		items.append(kept)
	add_gold(gold_back)
	save()
	return gold_back


func item_by_uid(uid: int) -> Dictionary:
	for item: Dictionary in items:
		if int(item["uid"]) == uid:
			return item
	return {}


## The item worn in a slot (empty when none).
func worn_item(slot: String) -> Dictionary:
	return item_by_uid(int(equipped_items.get(slot, 0)))


func owns_item(base: String) -> bool:
	return items.any(func(item: Dictionary) -> bool: return item["base"] == base)


## Legendary items worn right now, leaving out `slot`.
func legendaries_worn(except_slot: String = "") -> int:
	var n := 0
	for slot: String in equipped_items:
		if slot != except_slot and worn_item(slot).get("rarity", "") == "legendary":
			n += 1
	return n


## Puts an item on (taking off whatever was in its slot), or takes it off
## when it is already worn. Returns false when it can't go on: at most
## LEGENDARY_WORN legendaries at once.
func toggle_item(uid: int) -> bool:
	var item := item_by_uid(uid)
	if item.is_empty():
		return false
	var slot: String = item["slot"]
	if int(equipped_items.get(slot, 0)) == uid:
		equipped_items.erase(slot)
	elif item["rarity"] == "legendary" and legendaries_worn(slot) >= LEGENDARY_WORN:
		return false
	else:
		equipped_items[slot] = uid
	save()
	return true


## Melts an item down for gold (taking it off first).
func salvage_item(uid: int) -> int:
	var item := item_by_uid(uid)
	if item.is_empty():
		return 0
	if int(equipped_items.get(item["slot"], 0)) == uid:
		equipped_items.erase(item["slot"])
	items.erase(item)
	var gold_back := Items.salvage_gold(item)
	add_gold(gold_back)
	save()
	return gold_back


## Sum of the worn items per stat.
func item_bonus() -> Dictionary:
	var bonus := {}
	for slot: String in equipped_items:
		var item := worn_item(slot)
		if item.is_empty():
			continue
		var stats: Dictionary = item["stats"]
		for key: String in stats:
			if key in Items.TIMERS and bonus.has(key):
				bonus[key] = minf(float(bonus[key]), float(stats[key]))
			else:
				bonus[key] = float(bonus.get(key, 0.0)) + float(stats[key])
	return bonus


## Drops items whose base no longer exists, slots pointing at nothing and
## legendaries over the limit,
## so a changed items.json or rule never breaks an old profile.
func _clean_items() -> void:
	items = items.filter(func(item: Variant) -> bool: return item is Dictionary and not Items.info(item).is_empty())
	for slot: String in equipped_items.keys():
		if worn_item(slot).is_empty():
			equipped_items.erase(slot)
	# More legendaries worn than allowed (an older save): the extra come off.
	for slot: String in equipped_items.keys():
		if worn_item(slot).get("rarity", "") == "legendary" and legendaries_worn(slot) >= LEGENDARY_WORN:
			equipped_items.erase(slot)


## Sum of the worn charms per stat.
func charm_bonus() -> Dictionary:
	var bonus := {}
	for id in equipped_charms:
		var data: Dictionary = GameData.charms.get(id, {})
		if not data.is_empty():
			bonus[data["stat"]] = bonus.get(data["stat"], 0.0) + float(data["value"]) * quality_mult(quality_of(id))
	return bonus


## Gold bonus from the current streak: +10 % per step, up to +50 %.
func streak_multiplier() -> float:
	return 1.0 + 0.1 * mini(streak, 5)


func add_streak(steps: int) -> void:
	streak += steps
	best_streak = maxi(best_streak, streak)
	save()


func reset_streak() -> void:
	streak = 0
	save()


func add_gold(amount: int) -> void:
	gold += amount
	save()


func powerup_rank(id: String) -> int:
	return int(powerups.get(id, 0))


func total_ranks() -> int:
	var n := 0
	for id: String in powerups:
		n += int(powerups[id])
	return n


## Price of the next rank: grows with the rank and with everything bought so
## far (like Vampire Survivors), so the order you buy in matters a little.
func powerup_cost(id: String) -> int:
	var base := float(GameData.powerups[id]["base_cost"])
	return roundi(base * (powerup_rank(id) + 1) * (1.0 + 0.1 * total_ranks()))


func buy_powerup(id: String) -> bool:
	var data: Dictionary = GameData.powerups[id]
	if powerup_rank(id) >= int(data["max_rank"]):
		return false
	var cost := powerup_cost(id)
	if gold < cost:
		return false
	gold -= cost
	spent += cost
	powerups[id] = powerup_rank(id) + 1
	save()
	return true


## Gives back everything spent on power-ups.
func refund_powerups() -> void:
	gold += spent
	spent = 0
	powerups = {}
	save()


## Sum of all bought power-ups per stat.
func powerup_bonus() -> Dictionary:
	var bonus := {}
	for id: String in powerups:
		var data: Dictionary = GameData.powerups.get(id, {})
		if data.is_empty():
			continue
		bonus[data["stat"]] = bonus.get(data["stat"], 0.0) + float(data["per_rank"]) * int(powerups[id])
	return bonus


func has_flag(flag: String) -> bool:
	return flag in flags


func set_flag(flag: String) -> void:
	if flag not in flags:
		flags.append(flag)
		save()


func save() -> void:
	# Automated test runs must never touch the real profile.
	if GameData.no_save():
		return
	var cfg := ConfigFile.new()
	cfg.set_value("cats", "unlocked", unlocked)
	cfg.set_value("cats", "selected", selected_cat)
	cfg.set_value("stages", "selected", selected_stage)
	cfg.set_value("stages", "cleared", cleared_stages)
	cfg.set_value("darkness", "selected", darkness)
	cfg.set_value("darkness", "best", darkness_best)
	cfg.set_value("story", "flags", flags)
	cfg.set_value("shop", "gold", gold)
	cfg.set_value("streak", "current", streak)
	cfg.set_value("charms", "owned", charms)
	cfg.set_value("charms", "quality", charm_quality)
	cfg.set_value("stats", "counters", stats)
	cfg.set_value("stats", "goals_done", goals_done)
	cfg.set_value("charms", "equipped", equipped_charms)
	cfg.set_value("streak", "best", best_streak)
	cfg.set_value("shop", "spent", spent)
	cfg.set_value("shop", "powerups", powerups)
	cfg.set_value("questbook", "steps", questbook)
	cfg.set_value("challenge", "active", _daily_backup if daily else (_report_backup if _report_on else challenges))
	cfg.set_value("reports", "list", reports)
	cfg.set_value("reports", "news", report_news)
	cfg.set_value("reports", "calm", siege_calm)
	cfg.set_value("nemesis", "bosses", nemesis)
	cfg.set_value("residents", "services", services)
	cfg.set_value("trip", "last", last_trip)
	cfg.set_value("territory", "conquered", territories)
	cfg.set_value("residents", "kidnapped", kidnapped)
	cfg.set_value("moon", "night", moon_night)
	cfg.set_value("weather", "today", weather_today)
	cfg.set_value("weather", "tomorrow", weather_tomorrow)
	cfg.set_value("moon", "traps", moon_traps)
	cfg.set_value("moon", "guards", moon_guards)
	cfg.set_value("artifacts", "owned", artifacts)
	cfg.set_value("chains", "steps", chains)
	cfg.set_value("achievements", "earned", achievements)
	cfg.set_value("artifacts", "equipped", equipped_artifacts)
	cfg.set_value("items", "owned", items)
	cfg.set_value("items", "equipped", equipped_items)
	cfg.set_value("items", "next_uid", next_item_uid)
	# Keep the last good save before writing the new one.
	if FileAccess.file_exists(PATH):
		var previous := ConfigFile.new()
		if previous.load(PATH) == OK:
			DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(BACKUP))
	cfg.save(PATH)
