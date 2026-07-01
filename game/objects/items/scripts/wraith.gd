extends Item


func apply_item_effect() -> void:
	player.pass_through_enemies = true
	player.immune_time_bonus += 0.1
	player.speed_bonus += 1
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player._update_enemy_collision()
	player._emit_stats_changed()
