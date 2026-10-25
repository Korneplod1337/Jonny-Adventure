extends Item

func apply_item_effect() -> void:
	player.ricochet_bonus += int(effect_power) #1
