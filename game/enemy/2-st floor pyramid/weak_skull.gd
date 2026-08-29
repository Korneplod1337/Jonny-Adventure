extends EnemyShortVision
class_name EnemyWeakSkull

@export_group("Hard Stats")
@export var hard_base_hp: int = 40
@export var hard_damage: int = 1
@export var hard_move_speed: float = 65.0

const MOVE_SPEED_MED_OFFSET := -10.0
const MOVE_SPEED_EASY_OFFSET := -20.0
const HP_MED_OFFSET := -10
const HP_EASY_OFFSET := -20
const DAMAGE_MED_OFFSET := 0
const DAMAGE_EASY_OFFSET := 0


func _ready() -> void:
	use_base_move_towards_player = true
	super._ready()


func _apply_level_buffs() -> void:
	move_speed = _scale_move_speed(
		hard_move_speed, MOVE_SPEED_MED_OFFSET, MOVE_SPEED_EASY_OFFSET
	)
	base_hp = _scale_hp(hard_base_hp, HP_MED_OFFSET, HP_EASY_OFFSET)
	damage = _scale_damage(hard_damage, DAMAGE_MED_OFFSET, DAMAGE_EASY_OFFSET)
	super._apply_level_buffs()
