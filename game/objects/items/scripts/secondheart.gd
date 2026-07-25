extends Item

func apply_item_effect() -> void:
	player.revival_count += 1
	player.hp_bonus += 2
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player._emit_stats_changed()
