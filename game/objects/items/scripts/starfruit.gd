extends Item

func apply_item_effect() -> void:
	# Каждый стак: любой выстрел → 5 лучей, урон × effect_power (0.5)
	player.star_fruit_stacks += 1
