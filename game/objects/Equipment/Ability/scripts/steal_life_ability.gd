## Steal Life — следующий выстрел при попадании лечит 1 зелёное (или синее, если нет слотов). CD: этаж.
class_name StealLifeAbility
extends BaseAbility

var _next_shot_buffed: bool = false


func _init() -> void:
	ability_id = "StealLife"
	cooldown_type = CooldownType.FLOOR


func activate() -> bool:
	_next_shot_buffed = true
	return true


## Called from Jonny.fire — arms the next volley once.
func consume_for_next_shot() -> bool:
	if not _next_shot_buffed:
		return false
	_next_shot_buffed = false
	return true


func _exit_tree() -> void:
	_next_shot_buffed = false
	if player and is_instance_valid(player):
		player.steal_life_heal_ready = false
	super._exit_tree()
