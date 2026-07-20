extends Item

func apply_item_effect() -> void:
	player.hp_bonus += 1
	player.speed_bonus += 1
	player.luck_bonus += 1
	player.magic_bonus += 1
	player.damage_bonus += 1
	player.accuracy_bonus += 1
	player.range_bonus += 1
	player.fire_rate_bonus += 1
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player.luck = StatManager.get_stat(player, "luck")
	player.magic = StatManager.get_stat(player, "magic")
	player.damage = StatManager.get_stat(player, "damage")
	player.spread = StatManager.get_stat(player, "spread")
	player.atk_range = StatManager.get_stat(player, "range")
	player.fire_rate = StatManager.get_stat(player, "fire_rate")
	player._emit_stats_changed()
