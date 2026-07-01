extends Item

func apply_item_effect() -> void:
	GameState.enemy_hp_multiplier *= effect_power #0.97
	player.luck_bonus += 1
	player.luck = StatManager.get_stat(player, "luck")
	player._emit_stats_changed()
