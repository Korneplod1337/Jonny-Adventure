extends Item

func apply_item_effect() -> void:
	if player.is_class("Joab"):
		player.heal(1)
	else:
		player.take_damage(0, 1, 0)
