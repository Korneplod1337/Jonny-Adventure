extends Item

func apply_item_effect() -> void:
	player.speed_bonus += 1
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player._emit_stats_changed()
