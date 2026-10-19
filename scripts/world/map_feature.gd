class_name MapFeature
extends Node2D
## Something a finished story leaves on a map for good (a chain's reward
## "feature": {stage, kind}). Kinds: "heal_spot" (the warm boiler: stand
## next to it to heal), "scarecrow" (hits birds that come close), "turret"
## (the charged antenna zaps the nearest enemy), "lighthouse" (its beam
## burns jellyfish), "ally" (a cat joins every
## night; stage "any" works on every map).

const OUTLINE := Color("2b1d14")
const HEAL_RADIUS := 70.0
const HEAL_PER_SECOND := 4.0
const SCARE_RADIUS := 260.0
const SCARE_EVERY := 1.5
const SCARE_DAMAGE := 60.0
const BIRDS := ["CROW", "PIGEON", "GULL", "DIVE_GULL"]
const ZAP_RANGE := 320.0
const ZAP_EVERY := 1.0
const ZAP_DAMAGE := 40.0

var kind := ""
var main: Node
var _t := 0.0
var _scare_t := 0.0
var _zap_t := 0.0
var _zap_at := Vector2.INF
var _zap_show := 0.0
## 1 → 0 after being built: an expanding ring shows where it now protects.
var _burst := 0.0


## Places every feature that finished stories left on this map.
static func place_all(p_main: Node, stage_id: String, origin: Vector2) -> void:
	var i := 0
	for id: String in GameData.chains:
		var feature: Dictionary = GameData.chains[id].get("reward", {}).get("feature", {})
		if feature.is_empty() or not ChainStep.is_done(id):
			continue
		if feature.get("stage", "") != stage_id and feature.get("stage", "") != "any":
			continue
		if feature["kind"] == "ally":
			if p_main.player.cat_id != feature["cat"]:
				p_main.cat_joined.call_deferred(feature["cat"])
			continue
		place_one(p_main, feature["kind"], origin + Vector2.from_angle(-0.6 + i * 1.3) * 240.0)
		i += 1


## Puts one feature on the map; `fresh` shows a burst (just built in a quest).
static func place_one(p_main: Node, p_kind: String, at: Vector2, fresh: bool = false) -> MapFeature:
	var node := MapFeature.new()
	node.kind = p_kind
	node.main = p_main
	node.position = at
	node.z_index = -4
	node._burst = 1.0 if fresh else 0.0
	p_main.add_child(node)
	return node


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _physics_process(delta: float) -> void:
	_t += delta
	_burst = maxf(_burst - delta / 1.2, 0.0)
	var cat: Player = main.player
	if kind == "heal_spot" and not cat.is_dead and cat.position.distance_to(position) < HEAL_RADIUS:
		cat.heal(HEAL_PER_SECOND * delta)
	_zap_show -= delta
	if kind == "turret":
		_zap_t -= delta
		if _zap_t <= 0.0:
			_zap_t = ZAP_EVERY
			var target: Enemy = main.enemies.nearest(position, ZAP_RANGE)
			if target != null:
				target.hit(ZAP_DAMAGE * main.spawner.hp_multiplier(), target.position - position, 0.5, false)
				_zap_at = target.position - position
				_zap_show = 0.15
	if kind == "scarecrow" or kind == "lighthouse":
		_scare_t -= delta
		if _scare_t <= 0.0:
			_scare_t = SCARE_EVERY
			var targets: Array = BIRDS if kind == "scarecrow" else ["JELLYFISH"]
			for e: Enemy in main.enemies.query_radius(position, SCARE_RADIUS * (1.5 if kind == "lighthouse" else 1.0)):
				if e.id in targets:
					e.hit(SCARE_DAMAGE * main.spawner.hp_multiplier(), e.position - position, 1.5, false)
	queue_redraw()


## Radius the feature works in (shown faintly so you know where it helps).
func reach() -> float:
	match kind:
		"heal_spot":
			return HEAL_RADIUS
		"scarecrow":
			return SCARE_RADIUS
		"lighthouse":
			return SCARE_RADIUS * 1.5
		"turret":
			return ZAP_RANGE
	return 0.0


func _draw() -> void:
	if _burst > 0.0:
		var r := reach() * (1.0 - _burst * _burst)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 0.85, 0.35, 0.9 * _burst), 6.0)
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.85, 0.35, 0.12 * _burst))
	if kind != "heal_spot" and reach() > 0.0:
		draw_arc(Vector2.ZERO, reach(), 0.0, TAU, 48, Color(1.0, 0.95, 0.7, 0.07), 2.0)
	match kind:
		"heal_spot":
			draw_circle(Vector2.ZERO, HEAL_RADIUS, Color(1.0, 0.6, 0.3, 0.08 + 0.04 * sin(_t * 2.0)))
			draw_rect(Rect2(-16, -22, 32, 40), OUTLINE)
			draw_rect(Rect2(-15, -21, 30, 38), Color("8a6a4a"))
			draw_rect(Rect2(-9, 0, 18, 10), Color("2a1a14"))
			draw_rect(Rect2(-7, 2, 14, 6), Color(1.0, 0.5 + 0.2 * sin(_t * 6.0), 0.2))
			draw_line(Vector2(6, -21), Vector2(6, -34), Color("6a6e72"), 4.0)
		"turret":
			draw_line(Vector2(0, 16), Vector2(0, -30), OUTLINE, 3.0)
			draw_line(Vector2(0, 16), Vector2(0, -30), Color("9aa0a6"), 1.0)
			for k in 3:
				draw_line(Vector2(-14 + k * 3, -22 + k * 9), Vector2(14 - k * 3, -22 + k * 9), Color("9aa0a6"), 1.0)
			draw_circle(Vector2(0, -30), 3.0 + sin(_t * 8.0), Color("9ae0ff"))
			if _zap_show > 0.0 and _zap_at != Vector2.INF:
				var pts := PackedVector2Array([Vector2(0, -30)])
				for i in 5:
					pts.append(Vector2(0, -30).lerp(_zap_at, (i + 1) / 6.0) + Vector2(randf_range(-6, 6), randf_range(-6, 6)))
				pts.append(_zap_at)
				draw_polyline(pts, Color("9ae0ff"), 2.0)
		"lighthouse":
			var beam := _t * 0.8
			draw_colored_polygon(PackedVector2Array([Vector2(0, -30), Vector2(0, -30) + Vector2.from_angle(beam - 0.15) * 380.0, Vector2(0, -30) + Vector2.from_angle(beam + 0.15) * 380.0]), Color(1.0, 0.95, 0.6, 0.12))
			draw_colored_polygon(PackedVector2Array([Vector2(-12, 20), Vector2(12, 20), Vector2(7, -24), Vector2(-7, -24)]), Color("f4f1ea"))
			for y in [8.0, -8.0]:
				draw_rect(Rect2(-10, y, 20, 5), Color("d9534f"))
			draw_rect(Rect2(-8, -32, 16, 8), Color("f2d14e"))
		"scarecrow":
			var sway := sin(_t * 1.5) * 2.0
			draw_line(Vector2(0, 20), Vector2(0, -20), Color("6b4630"), 3.0)
			draw_line(Vector2(-16, -8 + sway), Vector2(16, -8 - sway), Color("6b4630"), 3.0)
			draw_rect(Rect2(-7, -10, 14, 18), Color("c9a24a"))
			draw_line(Vector2(-8, -9), Vector2(8, -9), Color("d9534f"), 3.0)
			draw_circle(Vector2(0, -20), 7.0, Color("e8902a"))
			draw_rect(Rect2(-9, -30, 18, 3), Color("5a4234"))
			draw_rect(Rect2(-5, -36, 10, 6), Color("5a4234"))
