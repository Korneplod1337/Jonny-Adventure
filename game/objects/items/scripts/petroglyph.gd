extends Item


func apply_item_effect() -> void:
	var dungeon = player.get_tree().current_scene
	if dungeon == null or not dungeon.has_method("regenerate_floor"):
		return
	var new_floor := maxi(-1, dungeon.current_floor - 1)
	if new_floor == dungeon.current_floor:
		return
	dungeon.call_deferred("regenerate_floor", new_floor)
