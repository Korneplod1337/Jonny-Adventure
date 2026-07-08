extends BaseEnemy
class_name EnemySpider

@export_group("Hard Stats")
@export var hard_base_hp: int = 65
@export var hard_damage: int = 1
## Разброс направления движения от базового, в градусах.
@export var hard_angle_deviation: float = 60.0

const ANGLE_DEVIATION_MED_OFFSET := 0.0
const ANGLE_DEVIATION_EASY_OFFSET := -10.0

var angle_deviation: float


func _apply_spider_angle_deviation() -> void:
	angle_deviation = _apply_difficulty_offset(
		hard_angle_deviation, ANGLE_DEVIATION_MED_OFFSET, ANGLE_DEVIATION_EASY_OFFSET
	)
