extends Item

const MODIFIER_ID := "guillotine"


func apply_item_effect() -> void:
	var modifier := FirstStrikeHitModifier.new()
	modifier.multiplier = 1.15
	DamageDealer.add_modifier(modifier, MODIFIER_ID)
	player.damage_bonus += 1
	player.damage = StatManager.get_stat(player, "damage")
	player._emit_stats_changed()
