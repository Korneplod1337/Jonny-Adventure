extends Item

func apply_item_effect() -> void:
	player.speed_bonus += 3
	player.damage_bonus += 1
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player.damage = StatManager.get_stat(player, "damage")
	player._emit_stats_changed()
