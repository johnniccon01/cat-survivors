class_name ChainStep
extends Quest
## One step of a quest chain (data/chains.json). Chains are long quests that
## go on over several nights: Profile.chains remembers how many steps are
## done, and the quest director hands out the next step on the right map.
## A step with "if": flag is skipped unless that flag is set (choices), and
## a step's own "reward" is paid when it is done.
## Texts: CHAIN_<ID>_NAME, CHAIN_<ID>_<n> (the objective), and optionally
## CHAIN_<ID>_<n>_START (said when the step begins) and CHAIN_<ID>_<n>_DONE.
## Subclasses implement one kind of step each (trail, chase, carry...).

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


## Makes the node for the next step of a chain.
static func create(id: String) -> ChainStep:
	var n := progress_of(id) + 1
	var data: Dictionary = steps(id)[n - 1]
	# Loaded here, not preloaded: the step scripts extend this class.
	var script: GDScript = load("res://scripts/quests/chain/%s_step.gd" % data["type"])
	var step: ChainStep = script.new()
	step.chain_id = id
	step.step_no = n
	step.data = data
	return step


## Text for a key that may not exist ("" then).
static func optional_text(key: String) -> String:
	var text := TranslationServer.translate(key)
	return "" if text == key else text


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
		line = ("%s\n" % line if line != "" else "") + tr("CHAIN_FINISHED") % [title(), QuestBook.reward_text(reward)]
	Profile.save()
	super.complete()
	if line != "":
		main.hud.show_banner(line, 6.0)


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
		"hint":
			for i in 3:
				draw_circle(at + Vector2(-8 + i * 8, 0), 2.5, Color(1, 1, 1, 0.5 * a))
		_:
			draw_circle(at, 8.0, Color(OUTLINE, a))
			draw_circle(at, 7.0, Color(0.95, 0.76, 0.3, a))


## A soft pulsing ring that says "come here".
func draw_beacon(at: Vector2, radius: float, color: Color) -> void:
	var k := 0.5 + 0.5 * sin(_age * 4.0)
	draw_arc(at, radius + k * 4.0, 0.0, TAU, 32, Color(color, 0.35 + 0.3 * k), 2.0)
