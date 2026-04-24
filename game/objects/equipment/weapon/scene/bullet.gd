extends BaseShot
class_name BaseGun

var luck :float = 0.0
var spread: float = 0.0
var base_crit_bonus: float = 50
@onready var crit: AnimatedSprite2D = $Crit
var crit_sprite = -1

func _ready() -> void:
	extra_reload= 0.5


func _on_body_entered(body):
	if exploded:
		return
	if body.name == "Player":
		return
	var player := get_tree().get_first_node_in_group("player")
	luck 	= StatManager.get_stat(player, 'luck')
	spread 	= StatManager.get_stat(player, 'spread')
	if enchantment:
		enchantment.apply_on_hit(body, (body.global_position - global_position).normalized())

	if body.has_method("hit"):
		body.hit(_get_damage_with_crits())
	
	if crit_sprite >= 0:
		crit.frame = crit_sprite
		crit.show()
	
	exploded = true
	explosion(0)


func _get_damage_with_crits() -> int:
	var chance := 0.1 + luck/2
	var crit_bonus := base_crit_bonus / (spread+10)

	var total_crit := 1.0

	while true:
		if randf() < chance:
			crit_sprite += 1
			total_crit 	+= crit_bonus
			chance -= 0.2
			print('crit! ', crit_sprite)
		else:
			break

	return int(round(damage * self_damage_multiplier * total_crit))
	
