extends Item

func apply_item_effect() -> void:
	player.luck_bonus += 3
	GameState.extra_chest_loot_chance += 0.10
	player.luck = StatManager.get_stat(player, "luck")
	player._emit_stats_changed()
