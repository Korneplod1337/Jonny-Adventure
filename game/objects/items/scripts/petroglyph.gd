extends Item


func apply_item_effect() -> void:
	var dungeon = player.get_tree().current_scene
	if dungeon == null:
		return
	dungeon.current_floor = maxi(0, dungeon.current_floor - 1)
