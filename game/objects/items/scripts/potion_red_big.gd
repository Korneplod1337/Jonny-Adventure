extends Item

func apply_item_effect() -> void:
	if str(player.player_name) == "Joab":
		if player.has_method("apply_red_potion"):
			player.apply_red_potion(int(effect_power))
		else:
			player.take_damage(int(effect_power), 0, 0)
	else:
		player.heal(1 * int(effect_power))

func _ready() -> void:
	cost += 1
	super()
