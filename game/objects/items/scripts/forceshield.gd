extends Item


func apply_item_effect() -> void:
	player.force_shield_max += 1
	player.force_shield_charges += 1
