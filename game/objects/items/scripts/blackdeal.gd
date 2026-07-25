extends Item

func apply_item_effect() -> void:
	if player.player_name == "Joab":
		player.hp_bonus += 5
		player.heal(0, 0, 4, 0)
		player.take_damage(2)
	else:
		player.hp_bonus -= 5
		player.take_damage(0,2)
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player._emit_stats_changed()
