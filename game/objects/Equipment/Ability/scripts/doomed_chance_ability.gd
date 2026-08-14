## Doomed Chance — жертвует 1 HP магическим уроном, даёт +1 уровень luck. CD: 1 с.
class_name DoomedChanceAbility
extends BaseAbility


func _init() -> void:
	ability_id = "DoomedChance"
	cooldown_type = CooldownType.TIME
	cooldown_time = 1.0


func activate() -> bool:
	player.take_damage(0, 1)
	StatManager.upgrade_stat(player, "luck", 1)
	player._emit_stats_changed()
	return true
