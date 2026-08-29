extends EnemyRandomMover
class_name EnemyKnot

const MOVE_SPEED_MED_OFFSET := -25.0
const MOVE_SPEED_EASY_OFFSET := -50.0
const HP_MED_OFFSET := -20
const HP_EASY_OFFSET := -50
const DAMAGE_MED_OFFSET := 0
const DAMAGE_EASY_OFFSET := 0


func _get_roll_speed_med_offset() -> float:
	return MOVE_SPEED_MED_OFFSET


func _get_roll_speed_easy_offset() -> float:
	return MOVE_SPEED_EASY_OFFSET


func _get_hp_med_offset() -> int:
	return HP_MED_OFFSET


func _get_hp_easy_offset() -> int:
	return HP_EASY_OFFSET


func _get_damage_med_offset() -> int:
	return DAMAGE_MED_OFFSET


func _get_damage_easy_offset() -> int:
	return DAMAGE_EASY_OFFSET
