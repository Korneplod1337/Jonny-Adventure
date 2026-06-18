extends Item

func apply_item_effect() -> void:
	player.boomerang_bonus += int(effect_power)
