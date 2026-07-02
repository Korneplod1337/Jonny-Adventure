extends BaseShot
class_name BaseGun

@onready var crit: AnimatedSprite2D = $Crit

func _ready() -> void:
	super()
	self_speed_multiplier *= 1.5
	extra_reload *= 0.5
	# Crit всегда сверху и смотрит вверх в мировых координатах
	crit.position = CRIT_WORLD_OFFSET.rotated(-rotation)
	crit.rotation = -rotation


func _get_crit_chance() -> float:
	var chance := 0.1
	var shooter := _get_player()
	if shooter:
		chance += StatManager.get_stat(shooter, "luck") / 2.0
		chance += shooter.crit_chance_bonus
	return chance
