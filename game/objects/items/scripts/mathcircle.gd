extends Item

func apply_item_effect() -> void:
	# amplitude стакается (рад); дальность дальнобойных ×2 за каждый экземпляр
	player.math_circle_amplitude += effect_power #0.5
	player.math_circle_range_mult *= 1.75
