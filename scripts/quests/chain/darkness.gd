class_name Darkness
extends Node
## Lights out while a quest step runs (a power cut): the world goes almost
## black and the cat's own light grows. Freed with the step.

var night: Node


func _enter_tree() -> void:
	if night != null:
		night.dark += 1


func _exit_tree() -> void:
	if is_instance_valid(night):
		night.dark -= 1
