extends Item

func apply_item_effect() -> void:
	player.minimap += 1
	player.range_bonus += 2
	player.atk_range = StatManager.get_stat(player, "range")
	player._emit_stats_changed()
	var dungeon := get_tree().current_scene
	if dungeon and dungeon.has_method("refresh_minimap"):
		dungeon.refresh_minimap()
