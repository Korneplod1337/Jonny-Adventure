extends Item

func apply_item_effect() -> void:
	# +2 слота на орбите Satellite
	GameState.satellite_bonus_slots += int(effect_power)
