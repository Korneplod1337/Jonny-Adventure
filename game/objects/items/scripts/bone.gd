extends Item

func apply_item_effect() -> void:
	player.heal(0, 0, 1)
	player.hp_bonus += 2
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player._emit_stats_changed()
