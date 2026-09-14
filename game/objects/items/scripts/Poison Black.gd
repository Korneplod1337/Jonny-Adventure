extends Item

func apply_item_effect() -> void:
	if str(player.player_name) == "Joab":
		if player.has_method("apply_black_potion"):
			player.apply_black_potion(1)
		else:
			player.heal(1)
	else:
		player.take_damage(0, 1, 0)
