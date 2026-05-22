extends Item

func apply_item_effect() -> void:
	player.heal(1 * int(effect_power))
