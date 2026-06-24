extends Item

func apply_item_effect() -> void:
	player.scale = player.scale * effect_power
	#player.hp_bonus += 5
	#player.max_hp = int(StatManager.get_stat(player, "hp"))
	#player._emit_stats_changed()
