## Miromir's Blessing — лечит 1 красное сердце. CD: 5 зачищенных комнат (старт 2/5).
class_name MiromirBlessingAbility
extends BaseAbility


func _init() -> void:
	ability_id = "MiromirBlessing"
	cooldown_type = CooldownType.ROOMS
	cooldown_rooms = 5
	start_rooms_progress = 2


func activate() -> bool:
	player.heal(1, 0, 0, 0)
	return true
