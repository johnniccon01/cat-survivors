class_name ChainStep
extends Quest
## One step of a quest chain (data/chains.json). Chains are long quests that
## go on over several nights: Profile.chains remembers how many steps are
## done, and the quest director hands out the next step on the right map.
## A step with "if": flag is skipped unless that flag is set (choices), and
## a step's own "reward" is paid when it is done, "dark" turns the lights
## off while the step runs, and "after_minute" keeps it for later in the
## night.
## Texts: CHAIN_<ID>_NAME, CHAIN_<ID>_<n> (the objective), and optionally
## CHAIN_<ID>_<n>_START (said when the step begins) and CHAIN_<ID>_<n>_DONE.
## Subclasses implement one kind of step each (trail, chase, carry...).

## Step scripts by type, loaded once (see warm).
static var _scripts: Dictionary = {}

var chain_id := ""
## 1-based number of this step in its chain.
var step_no := 1


static func chain(id: String) -> Dictionary:
	return GameData.chains[id]


static func steps(id: String) -> Array:
	return chain(id)["steps"]


static func progress_of(id: String) -> int:
	return int(Profile.chains.get(id, 0))


static func is_done(id: String) -> bool:
	return progress_of(id) >= steps(id).size()


## The map step `n` (1-based) is played on: the step's own "stage", else the
## chain's ("any" = every map).
static func stage_of(id: String, n: int) -> String:
	var list := steps(id)
	var step: Dictionary = list[clampi(n - 1, 0, list.size() - 1)]
	return step.get("stage", chain(id).get("stage", "any"))


## Loads every step script up front (at the start of a night): loading one
## the moment its step begins made the game stutter for a frame or two.
static func warm() -> void:
	for id: String in GameData.chains:
		for step: Dictionary in steps(id):
			_script(step["type"])


static func _script(type: String) -> GDScript:
	if not _scripts.has(type):
		_scripts[type] = load("res://scripts/quests/chain/%s_step.gd" % type)
	return _scripts[type]


## Makes the node for the next step of a chain.
static func create(id: String, at_step: int = 0) -> ChainStep:
	var n := at_step if at_step > 0 else progress_of(id) + 1
	var data: Dictionary = steps(id)[n - 1]
	# Loaded at run time, not preloaded: the step scripts extend this class.
	var script := _script(data["type"])
	var step: ChainStep = script.new()
	step.chain_id = id
	step.step_no = n
	step.data = data
	return step


## Text for a key that may not exist ("" then).
static func optional_text(key: String) -> String:
	var text := TranslationServer.translate(key)
	return "" if text == key else text


func _enter_tree() -> void:
	if data.get("dark", false) and get_node_or_null("Darkness") == null:
		var dark := Darkness.new()
		dark.name = "Darkness"
		dark.night = main.night
		add_child(dark)


func title() -> String:
	return tr("CHAIN_%s_NAME" % chain_id)


func step_text() -> String:
	return tr("CHAIN_%s_%d" % [chain_id, step_no])


func start_line() -> String:
	return optional_text("CHAIN_%s_%d_START" % [chain_id, step_no])


func complete() -> void:
	if _done:
		return
	# Skip the steps of the branch not taken.
	var next := step_no
	while next < steps(chain_id).size() and not Profile.has_flag(steps(chain_id)[next].get("if", "")) and steps(chain_id)[next].has("if"):
		next += 1
	Profile.chains[chain_id] = next
	var line := optional_text("CHAIN_%s_%d_DONE" % [chain_id, step_no])
	var step_reward: Dictionary = data.get("reward", {})
	if not step_reward.is_empty():
		QuestBook._pay(step_reward)
		line = ("%s\n" % line if line != "" else "") + QuestBook.reward_text(step_reward)
	if next >= steps(chain_id).size():
		Profile.set_flag("chain:" + chain_id)
		var reward: Dictionary = chain(chain_id).get("reward", {})
		QuestBook._pay(reward)
		if reward.has("flag"):
			Profile.set_flag(reward["flag"])
		# What the story leaves on the map starts working tonight already
		# (a "build" step places it itself, where it was built).
		var feature: Dictionary = reward.get("feature", {})
		# An ally only offers to join the cat that finished his story.
		if feature.get("kind", "") == "ally":
			Profile.set_flag("ally:%s:%s" % [feature["cat"], main.player.cat_id])
		if not feature.is_empty() and feature["kind"] != "ally" and not data.has("build") \
				and feature.get("stage", "") == main.spawner.stage_id:
			MapFeature.place_one(main, feature["kind"], position, true)
		line = ("%s\n" % line if line != "" else "") + tr("CHAIN_FINISHED") % [title(), QuestBook.reward_text(reward)]
	Profile.save()
	super.complete()
	if line != "":
		main.hud.show_banner(line, 6.0)


## Finishes every "final" step waiting for this map's final boss.
static func final_defeated(p_main: Node, stage_id: String) -> void:
	for id: String in GameData.chains:
		if is_done(id):
			continue
		var n := progress_of(id) + 1
		if steps(id)[n - 1]["type"] != "final" or stage_of(id, n) != stage_id:
			continue
		var step := create(id)
		step.main = p_main
		step.complete()


func timer_text(seconds: float) -> String:
	return tr("CHAIN_TIME") % ceili(maxf(seconds, 0.0))


func random_point(from: Vector2, dist: Array) -> Vector2:
	return from + Vector2.from_angle(randf() * TAU) * randf_range(float(dist[0]), float(dist[1]))


## Draws one of the quest things (`look`) centred on `at` (local position).
func draw_look(at: Vector2, look: String, alpha: float = 1.0) -> void:
	var a := alpha
	match look:
		"crumbs":
			for p: Vector2 in [Vector2(-5, 1), Vector2(-1, -3), Vector2(3, 2), Vector2(6, -2), Vector2(0, 4)]:
				draw_circle(at + p, 2.0, Color(0.55, 0.36, 0.2, a))
		"key":
			draw_circle(at + Vector2(-4, 0), 4.0, Color(OUTLINE, a))
			draw_circle(at + Vector2(-4, 0), 3.0, Color(0.95, 0.76, 0.3, a))
			draw_line(at + Vector2(-1, 0), at + Vector2(8, 0), Color(0.95, 0.76, 0.3, a), 2.0)
			draw_line(at + Vector2(6, 0), at + Vector2(6, 3), Color(0.95, 0.76, 0.3, a), 2.0)
		"sock":
			var sock := PackedVector2Array([at + Vector2(-3, -8), at + Vector2(3, -8), at + Vector2(3, 2), at + Vector2(8, 4), at + Vector2(8, 8), at + Vector2(-3, 8)])
			draw_colored_polygon(sock, Color(0.95, 0.92, 0.85, a))
			draw_polyline(sock + PackedVector2Array([sock[0]]), Color(OUTLINE, a), 1.0)
			draw_line(at + Vector2(-3, -5), at + Vector2(3, -5), Color(0.48, 0.36, 0.77, a), 2.0)
		"pantry":
			draw_rect(Rect2(at + Vector2(-26, -22), Vector2(52, 40)), Color(OUTLINE, a))
			draw_rect(Rect2(at + Vector2(-25, -21), Vector2(50, 38)), Color(0.55, 0.36, 0.23, a))
			for y in [-12.0, 0.0]:
				draw_rect(Rect2(at + Vector2(-22, y), Vector2(44, 3)), Color(0.42, 0.27, 0.19, a))
			for i in 4:
				draw_rect(Rect2(at + Vector2(-20 + i * 11, -20), Vector2(7, 7)), Color(0.85, 0.75, 0.45, a))
				draw_rect(Rect2(at + Vector2(-20 + i * 11, -8), Vector2(7, 7)), Color(0.75, 0.35, 0.3, a))
		"basket":
			draw_colored_polygon(Shapes.ellipse(at + Vector2(0, 4), 24, 15), Color(OUTLINE, a))
			draw_colored_polygon(Shapes.ellipse(at + Vector2(0, 4), 23, 14), Color(0.79, 0.64, 0.42, a))
			draw_colored_polygon(Shapes.ellipse(at + Vector2(0, 2), 17, 9), Color(0.55, 0.42, 0.28, a))
		"moon":
			var skew := Vector2(10, 0)
			for ix in 2:
				for iy in 2:
					var p := at + Vector2(-22 + ix * 23, -18 + iy * 19)
					draw_colored_polygon(PackedVector2Array([p + skew * iy * 0.5, p + Vector2(20, 0) + skew * iy * 0.5,
						p + Vector2(20, 17) + skew * (iy + 1) * 0.5, p + Vector2(0, 17) + skew * (iy + 1) * 0.5]), Color(0.75, 0.85, 1.0, 0.35 * a))
		"hole":
			draw_colored_polygon(Shapes.ellipse(at, 16, 10), Color(0.1, 0.07, 0.06, a))
			draw_arc(at, 15.0, PI, TAU, 12, Color(0.45, 0.35, 0.25, a), 2.0)
		"pawprints":
			for p: Vector2 in [Vector2(-6, 3), Vector2(4, -3)]:
				draw_circle(at + p, 2.5, Color(0.25, 0.2, 0.18, 0.7 * a))
				for k in 3:
					draw_circle(at + p + Vector2(-2 + k * 2, -3.5), 1.0, Color(0.25, 0.2, 0.18, 0.7 * a))
		"cocoon":
			draw_colored_polygon(Shapes.ellipse(at, 6, 10), Color(0.93, 0.93, 0.9, a))
			for k in 4:
				draw_line(at + Vector2(-6, -6 + k * 4), at + Vector2(6, -4 + k * 4), Color(0.7, 0.7, 0.68, a), 1.0)
			draw_line(at + Vector2(0, -10), at + Vector2(0, -20), Color(1, 1, 1, 0.5 * a), 1.0)
		"web":
			for k in 8:
				draw_line(at, at + Vector2.from_angle(TAU * k / 8.0) * 30.0, Color(1, 1, 1, 0.45 * a), 1.0)
			for r: float in [10.0, 18.0, 26.0]:
				draw_arc(at, r, 0.0, TAU, 8, Color(1, 1, 1, 0.35 * a), 1.0)
		"gear":
			for k in 8:
				var d := Vector2.from_angle(TAU * k / 8.0)
				draw_line(at + d * 4.0, at + d * 8.0, Color(0.6, 0.62, 0.65, a), 3.0)
			draw_circle(at, 5.0, Color(0.6, 0.62, 0.65, a))
			draw_circle(at, 2.0, Color(OUTLINE, a))
		"boiler":
			draw_rect(Rect2(at + Vector2(-16, -22), Vector2(32, 40)), Color(OUTLINE, a))
			draw_rect(Rect2(at + Vector2(-15, -21), Vector2(30, 38)), Color(0.54, 0.42, 0.29, a))
			draw_rect(Rect2(at + Vector2(-9, 0), Vector2(18, 10)), Color(0.16, 0.1, 0.08, a))
			draw_line(at + Vector2(6, -21), at + Vector2(6, -34), Color(0.42, 0.43, 0.45, a), 4.0)
		"veggies":
			for k in 3:
				var p := at + Vector2(-16 + k * 16, 0)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -2), p + Vector2(4, -2), p + Vector2(0, 10)]), Color(0.93, 0.55, 0.2, a))
				draw_line(p + Vector2(0, -2), p + Vector2(-3, -9), Color(0.37, 0.62, 0.29, a), 2.0)
				draw_line(p + Vector2(0, -2), p + Vector2(3, -9), Color(0.37, 0.62, 0.29, a), 2.0)
		"molehill":
			draw_colored_polygon(Shapes.ellipse(at, 12, 7), Color(0.36, 0.25, 0.17, a))
			draw_colored_polygon(Shapes.ellipse(at + Vector2(0, -2), 6, 3), Color(0.2, 0.14, 0.1, a))
		"flower":
			for k in 5:
				draw_circle(at + Vector2.from_angle(TAU * k / 5.0) * 4.0, 3.0, Color(0.88, 0.48, 0.63, a))
			draw_circle(at, 2.5, Color(0.95, 0.82, 0.3, a))
		"beehive":
			for k in 4:
				draw_colored_polygon(Shapes.ellipse(at + Vector2(0, -14 + k * 8), 14 - absf(k - 1.5) * 2.0, 5), Color(0.85, 0.65, 0.3, a).darkened(k * 0.05))
			draw_colored_polygon(Shapes.ellipse(at + Vector2(0, 6), 3, 3), Color(OUTLINE, a))
		"hat":
			draw_rect(Rect2(at + Vector2(-9, 0), Vector2(18, 3)), Color(0.35, 0.25, 0.18, a))
			draw_rect(Rect2(at + Vector2(-5, -8), Vector2(10, 8)), Color(0.42, 0.3, 0.2, a))
		"scarf":
			draw_line(at + Vector2(-8, -2), at + Vector2(8, -2), Color(0.85, 0.3, 0.3, a), 4.0)
			draw_line(at + Vector2(5, -2), at + Vector2(7, 8), Color(0.85, 0.3, 0.3, a), 4.0)
		"pumpkin":
			draw_colored_polygon(Shapes.ellipse(at, 9, 7), Color(0.93, 0.55, 0.2, a))
			draw_line(at + Vector2(0, -7), at + Vector2(1, -11), Color(0.37, 0.62, 0.29, a), 2.0)
		"pole":
			draw_line(at + Vector2(0, 14), at + Vector2(0, -18), Color(0.42, 0.3, 0.2, a), 3.0)
			draw_line(at + Vector2(-12, -8), at + Vector2(12, -8), Color(0.42, 0.3, 0.2, a), 3.0)
		"scarecrow":
			var sway := sin(_age * 1.5) * 2.0
			draw_line(at + Vector2(0, 20), at + Vector2(0, -20), Color(0.42, 0.28, 0.19, a), 3.0)
			draw_line(at + Vector2(-16, -8 + sway), at + Vector2(16, -8 - sway), Color(0.42, 0.28, 0.19, a), 3.0)
			draw_rect(Rect2(at + Vector2(-7, -10), Vector2(14, 18)), Color(0.79, 0.64, 0.29, a))
			draw_line(at + Vector2(-8, -9), at + Vector2(8, -9), Color(0.85, 0.33, 0.31, a), 3.0)
			draw_circle(at + Vector2(0, -20), 7.0, Color(0.91, 0.56, 0.16, a))
			draw_rect(Rect2(at + Vector2(-9, -30), Vector2(18, 3)), Color(0.35, 0.26, 0.2, a))
			draw_rect(Rect2(at + Vector2(-5, -36), Vector2(10, 6)), Color(0.35, 0.26, 0.2, a))
		"straw":
			for k in 4:
				draw_line(at + Vector2(-6 + k * 3, 6), at + Vector2(-4 + k * 2, -7), Color(0.85, 0.7, 0.32, a), 2.0)
			draw_line(at + Vector2(-7, 0), at + Vector2(7, 0), Color(0.6, 0.4, 0.2, a), 2.0)
		"button":
			draw_circle(at, 6.0, Color(OUTLINE, a))
			draw_circle(at, 5.0, Color(0.3, 0.3, 0.35, a))
			for p: Vector2 in [Vector2(-2, -2), Vector2(2, -2), Vector2(-2, 2), Vector2(2, 2)]:
				draw_circle(at + p, 1.0, Color(0.85, 0.85, 0.85, a))
		"chimney":
			draw_rect(Rect2(at + Vector2(-12, -12), Vector2(24, 24)), Color(OUTLINE, a))
			draw_rect(Rect2(at + Vector2(-11, -11), Vector2(22, 22)), Color(0.66, 0.31, 0.23, a))
			draw_rect(Rect2(at + Vector2(-7, -7), Vector2(14, 14)), Color(0.15, 0.1, 0.1, a))
		"antenna":
			draw_line(at + Vector2(0, 14), at + Vector2(0, -24), Color(OUTLINE, a), 3.0)
			draw_line(at + Vector2(0, 14), at + Vector2(0, -24), Color(0.6, 0.63, 0.65, a), 1.0)
			for k in 3:
				draw_line(at + Vector2(-12 + k * 2, -18 + k * 8), at + Vector2(12 - k * 2, -18 + k * 8), Color(0.6, 0.63, 0.65, a), 1.0)
		"bin":
			draw_rect(Rect2(at + Vector2(-16, -12), Vector2(32, 26)), Color(OUTLINE, a))
			draw_rect(Rect2(at + Vector2(-15, -11), Vector2(30, 24)), Color(0.29, 0.42, 0.33, a))
			draw_rect(Rect2(at + Vector2(-17, -15), Vector2(34, 5)), Color(0.23, 0.34, 0.27, a))
		"fish":
			draw_colored_polygon(Shapes.ellipse(at, 7, 3.5, 10), Color(0.67, 0.71, 0.75, a))
			draw_colored_polygon(PackedVector2Array([at + Vector2(6, 0), at + Vector2(11, -4), at + Vector2(11, 4)]), Color(0.55, 0.59, 0.64, a))
		"milk":
			draw_rect(Rect2(at + Vector2(-5, -8), Vector2(10, 15)), Color(0.96, 0.96, 0.94, a))
			draw_rect(Rect2(at + Vector2(-5, -2), Vector2(10, 4)), Color(0.35, 0.6, 0.9, a))
		"ham":
			draw_colored_polygon(Shapes.ellipse(at, 8, 6), Color(0.88, 0.5, 0.55, a))
			draw_circle(at + Vector2(5, 3), 2.5, Color(0.96, 0.94, 0.9, a))
		"cheese":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 5), at + Vector2(8, 5), at + Vector2(8, -2), at + Vector2(-8, -6)]), Color(0.95, 0.8, 0.3, a))
			draw_circle(at + Vector2(2, 1), 1.5, Color(0.8, 0.62, 0.2, a))
		"sardines":
			draw_rect(Rect2(at + Vector2(-8, -5), Vector2(16, 10)), Color(0.55, 0.66, 0.72, a))
			draw_rect(Rect2(at + Vector2(-6, -3), Vector2(12, 6)), Color(0.85, 0.3, 0.3, a))
		"register":
			draw_rect(Rect2(at + Vector2(-20, -8), Vector2(40, 22)), Color(OUTLINE, a))
			draw_rect(Rect2(at + Vector2(-19, -7), Vector2(38, 20)), Color(0.35, 0.42, 0.48, a))
			draw_rect(Rect2(at + Vector2(-10, -20), Vector2(20, 12)), Color(0.35, 0.82, 0.42, a))
		"fuse":
			draw_rect(Rect2(at + Vector2(-10, -12), Vector2(20, 24)), Color(OUTLINE, a))
			draw_rect(Rect2(at + Vector2(-9, -11), Vector2(18, 22)), Color(0.6, 0.63, 0.65, a))
			draw_rect(Rect2(at + Vector2(-3, -6), Vector2(6, 12)), Color(0.95, 0.82, 0.3, a))
		"bone":
			draw_line(at + Vector2(-7, 0), at + Vector2(7, 0), Color(0.96, 0.94, 0.88, a), 4.0)
			for p: Vector2 in [Vector2(-8, -2), Vector2(-8, 2), Vector2(8, -2), Vector2(8, 2)]:
				draw_circle(at + p, 2.5, Color(0.96, 0.94, 0.88, a))
		"doghouse":
			draw_rect(Rect2(at + Vector2(-22, -10), Vector2(44, 28)), Color(OUTLINE, a))
			draw_rect(Rect2(at + Vector2(-21, -9), Vector2(42, 26)), Color(0.75, 0.35, 0.3, a))
			draw_colored_polygon(PackedVector2Array([at + Vector2(-26, -8), at + Vector2(0, -26), at + Vector2(26, -8)]), Color(0.42, 0.3, 0.25, a))
			draw_colored_polygon(Shapes.ellipse(at + Vector2(0, 8), 8, 9), Color(0.12, 0.08, 0.07, a))
		"sail":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-6, 8), at + Vector2(6, 8), at + Vector2(0, -10)]), Color(0.96, 0.94, 0.88, a))
		"wheel":
			draw_arc(at, 7.0, 0.0, TAU, 16, Color(0.55, 0.36, 0.23, a), 2.5)
			for k in 4:
				var d := Vector2.from_angle(TAU * k / 8.0)
				draw_line(at - d * 10.0, at + d * 10.0, Color(0.55, 0.36, 0.23, a), 2.0)
		"rope":
			for r: float in [7.0, 4.5, 2.0]:
				draw_arc(at, r, 0.0, TAU, 14, Color(0.79, 0.64, 0.42, a), 2.0)
		"boat":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-34, -6), at + Vector2(34, -6), at + Vector2(24, 12), at + Vector2(-24, 12)]), Color(0.55, 0.36, 0.23, a))
			draw_line(at + Vector2(0, -6), at + Vector2(0, -40), Color(0.42, 0.3, 0.2, a), 3.0)
		"barrel":
			draw_circle(at, 9.0, Color(OUTLINE, a))
			draw_circle(at, 8.0, Color(0.54, 0.35, 0.23, a))
			draw_arc(at, 5.5, 0.0, TAU, 14, Color(0.29, 0.23, 0.16, a), 1.0)
		"lighthouse":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-12, 20), at + Vector2(12, 20), at + Vector2(7, -24), at + Vector2(-7, -24)]), Color(0.96, 0.94, 0.9, a))
			for y in [8.0, -8.0]:
				draw_rect(Rect2(at + Vector2(-10, y), Vector2(20, 5)), Color(0.85, 0.3, 0.3, a))
			draw_rect(Rect2(at + Vector2(-8, -32), Vector2(16, 8)), Color(0.95, 0.82, 0.3, a))
		"map_piece":
			draw_rect(Rect2(at + Vector2(-7, -6), Vector2(14, 12)), Color(0.94, 0.89, 0.75, a))
			draw_line(at + Vector2(-4, 2), at + Vector2(3, -3), Color(0.85, 0.3, 0.3, a), 1.0)
		"x":
			draw_line(at + Vector2(-10, -10), at + Vector2(10, 10), Color(0.85, 0.3, 0.3, a), 4.0)
			draw_line(at + Vector2(10, -10), at + Vector2(-10, 10), Color(0.85, 0.3, 0.3, a), 4.0)
		"photo":
			draw_rect(Rect2(at + Vector2(-7, -6), Vector2(14, 12)), Color(0.96, 0.94, 0.88, a))
			draw_rect(Rect2(at + Vector2(-5, -4), Vector2(10, 7)), Color(0.55, 0.65, 0.75, a))
			draw_circle(at + Vector2(-1, -1), 2.0, Color(0.85, 0.55, 0.35, a))
		"letter":
			draw_rect(Rect2(at + Vector2(-8, -5), Vector2(16, 10)), Color(0.96, 0.94, 0.88, a))
			draw_polyline(PackedVector2Array([at + Vector2(-8, -5), at + Vector2(0, 1), at + Vector2(8, -5)]), Color(0.6, 0.5, 0.4, a), 1.0)
		"ribbon":
			draw_line(at + Vector2(-6, -2), at + Vector2(6, 2), Color(0.85, 0.35, 0.55, a), 3.0)
			draw_circle(at, 2.5, Color(0.85, 0.35, 0.55, a))
		"bowl":
			draw_colored_polygon(Shapes.ellipse(at, 16, 9), Color(OUTLINE, a))
			draw_colored_polygon(Shapes.ellipse(at, 15, 8), Color(0.3, 0.55, 0.85, a))
			draw_colored_polygon(Shapes.ellipse(at + Vector2(0, -1), 10, 5), Color(0.6, 0.42, 0.25, a))
		"fire":
			for k in 3:
				var h := 10.0 + 4.0 * sin(_age * 9.0 + k * 2.0)
				draw_colored_polygon(PackedVector2Array([at + Vector2(-9 + k * 9 - 5, 6), at + Vector2(-9 + k * 9 + 5, 6), at + Vector2(-9 + k * 9, 6 - h)]), Color(1.0, 0.5 + k * 0.15, 0.15, 0.9 * a))
		"lantern":
			draw_rect(Rect2(at + Vector2(-5, -7), Vector2(10, 12)), Color(OUTLINE, a))
			draw_rect(Rect2(at + Vector2(-4, -6), Vector2(8, 10)), Color(1.0, 0.85, 0.4, a))
			draw_arc(at + Vector2(0, -8), 4.0, PI, TAU, 8, Color(OUTLINE, a), 1.5)
		"hint":
			for i in 3:
				draw_circle(at + Vector2(-8 + i * 8, 0), 2.5, Color(1, 1, 1, 0.5 * a))
		_:
			draw_circle(at, 8.0, Color(OUTLINE, a))
			draw_circle(at, 7.0, Color(0.95, 0.76, 0.3, a))


## The broken version of a quest thing that has to be built again.
func draw_broken(at: Vector2, look: String, alpha: float = 1.0) -> void:
	if alpha <= 0.0:
		return
	var a := alpha
	if look == "scarecrow":
		# A snapped, leaning pole with straw scattered around it.
		draw_line(at + Vector2(0, 20), at + Vector2(4, 4), Color(0.42, 0.28, 0.19, a), 3.0)
		draw_line(at + Vector2(6, 2), at + Vector2(20, -6), Color(0.42, 0.28, 0.19, a), 3.0)
		draw_line(at + Vector2(-18, 14), at + Vector2(-4, 18), Color(0.42, 0.28, 0.19, a), 3.0)
		for p: Vector2 in [Vector2(-12, 20), Vector2(10, 22), Vector2(-4, 24), Vector2(16, 16), Vector2(-20, 18)]:
			draw_line(at + p, at + p + Vector2(5, -2), Color(0.79, 0.64, 0.29, a), 2.0)
		return
	# Anything else: dark, tipped over and cracked.
	draw_set_transform(at + Vector2(0, 6), 0.35, Vector2.ONE)
	draw_look(Vector2.ZERO, look, 0.55 * a)
	draw_set_transform(Vector2.ZERO)
	var crack := Color(0.1, 0.07, 0.06, 0.8 * a)
	draw_polyline(PackedVector2Array([at + Vector2(-8, -14), at + Vector2(-2, -4), at + Vector2(-6, 4), at + Vector2(2, 14)]), crack, 2.0)
	draw_polyline(PackedVector2Array([at + Vector2(10, -10), at + Vector2(4, 0), at + Vector2(9, 8)]), crack, 2.0)
	# A wisp of smoke: it's not working.
	for k in 3:
		var s := fmod(_age * 0.6 + k / 3.0, 1.0)
		draw_circle(at + Vector2(6 + sin(_age * 2.0 + k) * 4.0, -20 - s * 24.0), 3.0 + s * 4.0, Color(0.45, 0.45, 0.45, (1.0 - s) * 0.35 * a))


## A soft pulsing ring that says "come here".
func draw_beacon(at: Vector2, radius: float, color: Color) -> void:
	var k := 0.5 + 0.5 * sin(_age * 4.0)
	draw_arc(at, radius + k * 4.0, 0.0, TAU, 32, Color(color, 0.35 + 0.3 * k), 2.0)
