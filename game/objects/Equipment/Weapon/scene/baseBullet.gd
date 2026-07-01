extends BaseShot
class_name BaseGun

var luck :float = 0.0
var spread: float
var base_crit_bonus: float = 60

@onready var crit: AnimatedSprite2D = $Crit
const CRIT_WORLD_OFFSET := Vector2(0, -60)
var crit_sprite = -1

func _ready() -> void:
	super()
	self_speed_multiplier *= 1.5
	extra_reload *= 0.5
	# Crit всегда сверху и смотрит вверх в мировых координатах
	crit.position = CRIT_WORLD_OFFSET.rotated(-rotation)
	crit.rotation = -rotation

func _on_body_entered(body):
	if exploded:
		return
	if body.name == "Player":
		return

	var player := get_tree().get_first_node_in_group("player")
	luck = StatManager.get_stat(player, 'luck')
	spread = StatManager.get_stat(player, 'spread')

	if body.has_method("hit"):
		if _register_pierce_hit(body, _get_damage_with_crits()):
			if crit_sprite >= 0:
				crit.frame = crit_sprite
				crit.show()
			exploded = true
			explosion(0)
		return

	if crit_sprite >= 0:
		crit.frame = crit_sprite
		crit.show()

	exploded = true
	explosion(0)


func _get_damage_with_crits() -> int:
	var chance := 0.1 + luck / 2
	var shooter := get_tree().get_first_node_in_group("player")
	if shooter:
		chance += shooter.crit_chance_bonus
	var crit_bonus := base_crit_bonus / (spread + 20)
	var total_crit := 1.0
	while true:
		if randf() < chance:
			crit_sprite += 1
			total_crit += crit_bonus
			chance -= 0.2
			print('crit! ', crit_sprite)
			if crit_sprite == 4:
				StatsManager.add_statistic_progress("Mega_crit", 1)
				break
		else:
			break
	return int(round(damage * self_damage_multiplier * total_crit))
