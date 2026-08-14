## Boon of Keres — даёт 1 чёрный щит. CD: 4 зачищенных комнат (старт 0/4).
class_name BoonOfKeresAbility
extends BaseAbility


func _init() -> void:
	ability_id = "BoonOfKeres"
	cooldown_type = CooldownType.ROOMS
	cooldown_rooms = 4
	start_rooms_progress = 0


func activate() -> bool:
	player.heal(0, 0, 0, 1)
	return true
