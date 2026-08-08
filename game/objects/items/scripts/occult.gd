extends Item

func apply_item_effect() -> void:
	GameState.enemy_hp_multiplier *= effect_power #0.9
	player.hp_bonus += 3
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player._emit_stats_changed()
