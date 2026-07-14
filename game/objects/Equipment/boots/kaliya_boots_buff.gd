extends Node

const STACK_SCRIPT := preload("res://game/objects/Equipment/boots/kaliya_boots_stack.gd")


func add_stack() -> void:
	add_child(STACK_SCRIPT.new())


func _exit_tree() -> void:
	for child in get_children():
		if child.has_method("expire_now"):
			child.expire_now()
