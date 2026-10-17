class_name MapFeature
extends Node2D
## Something a finished story leaves on a map for good (a chain's reward
## "feature": {stage, kind}). Kinds: "heal_spot" (the warm boiler: stand
## next to it to heal).

const OUTLINE := Color("2b1d14")
const HEAL_RADIUS := 70.0
const HEAL_PER_SECOND := 4.0

var kind := ""
var main: Node
var _t := 0.0


## Places every feature that finished stories left on this map.
static func place_all(p_main: Node, stage_id: String, origin: Vector2) -> void:
	var i := 0
	for id: String in GameData.chains:
		var feature: Dictionary = GameData.chains[id].get("reward", {}).get("feature", {})
		if feature.is_empty() or feature.get("stage", "") != stage_id or not ChainStep.is_done(id):
			continue
		var node := MapFeature.new()
		node.kind = feature["kind"]
		node.main = p_main
		node.position = origin + Vector2.from_angle(-0.6 + i * 1.3) * 240.0
		node.z_index = -4
		p_main.add_child(node)
		i += 1


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _physics_process(delta: float) -> void:
	_t += delta
	var cat: Player = main.player
	if kind == "heal_spot" and not cat.is_dead and cat.position.distance_to(position) < HEAL_RADIUS:
		cat.heal(HEAL_PER_SECOND * delta)
	queue_redraw()


func _draw() -> void:
	match kind:
		"heal_spot":
			draw_circle(Vector2.ZERO, HEAL_RADIUS, Color(1.0, 0.6, 0.3, 0.08 + 0.04 * sin(_t * 2.0)))
			draw_rect(Rect2(-16, -22, 32, 40), OUTLINE)
			draw_rect(Rect2(-15, -21, 30, 38), Color("8a6a4a"))
			draw_rect(Rect2(-9, 0, 18, 10), Color("2a1a14"))
			draw_rect(Rect2(-7, 2, 14, 6), Color(1.0, 0.5 + 0.2 * sin(_t * 6.0), 0.2))
			draw_line(Vector2(6, -21), Vector2(6, -34), Color("6a6e72"), 4.0)
