extends Item

func apply_item_effect() -> void:
	player.heal(0,0,0,1 * int(effect_power))
