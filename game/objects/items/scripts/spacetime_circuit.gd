extends Item

func apply_item_effect() -> void:
	# effect_power = 1.28 → +28% хода времени (скорость, анимации, скорострельность, фазы)
	GameState.time_flow_mult *= effect_power
	GameState.animated_world_speed *= effect_power
	GameState.extra_enemy_coin_chance += 0.20
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player.fire_rate = StatManager.get_stat(player, "fire_rate")
	player._emit_stats_changed()
