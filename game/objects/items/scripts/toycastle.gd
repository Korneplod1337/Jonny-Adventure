extends Item

func apply_item_effect() -> void:
	GameState.boss_hp_multiplier *= effect_power #0.85
	GameState.boss_size_multiplier *= 0.92
	player.range_bonus += 1
	player.atk_range = StatManager.get_stat(player, "range")
	player._emit_stats_changed()
