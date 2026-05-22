extends Item

func apply_item_effect() -> void:
	player.scale = player.scale * effect_power
