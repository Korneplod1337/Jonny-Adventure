extends BaseShot
class_name BaseGun

var luck :float = 0.0
var spread: float = 0.0
var base_crit_bonus: float = 50

@onready var crit: AnimatedSprite2D = $Crit
var crit_sprite = -1

# ДРОБОВИК
@export var pellet_count := 1
@export var spread_angle := 30.0
@export var damage_mult : float = 1
@export var range_mult : float = 1
var spawned_spread := false


func _ready() -> void:
	self_speed_multiplier = 1.5
	self_damage_multiplier = damage_mult
	self_range_multiplier = range_mult 
	extra_reload = 0.5
	super()
	# Создание дополнительных дробинок
	if pellet_count > 1 and not spawned_spread:
		spawned_spread = true
		_spawn_spread()

func _spawn_spread():
	var center := int(pellet_count / 2)
	var step := deg_to_rad(spread_angle / float(pellet_count - 1))
	var start_angle := -deg_to_rad(spread_angle) / 2.0

	for i in range(pellet_count):
		# Центральная пуля уже существует
		if i == center:
			continue
		var bullet = duplicate()
		var angle = start_angle + step * i

		bullet.direction = direction.rotated(angle)
		# Чтобы дробинки не создавали новые дробинки
		bullet.spawned_spread = true

		# Копируем ВСЕ параметры
		bullet.damage = damage
		bullet.speed = speed
		bullet.atk_range = atk_range
		bullet.extra_reload = extra_reload
		bullet.self_damage_multiplier = self_damage_multiplier
		bullet.self_speed_multiplier = self_speed_multiplier
		bullet.self_range_multiplier = self_range_multiplier
		bullet.enchantment = enchantment
		bullet.use_spread = use_spread
		bullet.pellet_count = pellet_count
		bullet.spread_angle = spread_angle

		# КРИТЫ
		bullet.base_crit_bonus = base_crit_bonus
		get_parent().add_child.call_deferred(bullet)
		bullet.global_position = global_position



func _on_body_entered(body):
	if exploded:
		return
	if body.name == "Player":
		return

	var player := get_tree().get_first_node_in_group("player")
	luck = StatManager.get_stat(player, 'luck')
	spread = StatManager.get_stat(player, 'spread')

	if enchantment:
		enchantment.apply_on_hit(
			body,
			(body.global_position - global_position).normalized()
		)

	if body.has_method("hit"):
		body.hit(_get_damage_with_crits())

	if crit_sprite >= 0:
		crit.frame = crit_sprite
		crit.show()

	exploded = true
	explosion(0)


func _get_damage_with_crits() -> int:
	var chance := 0.1 + luck / 2
	var crit_bonus := base_crit_bonus / (spread + 10)
	var total_crit := 1.0
	while true:
		if randf() < chance:
			crit_sprite += 1
			total_crit += crit_bonus
			chance -= 0.2
			print('crit! ', crit_sprite)
			if crit_sprite == 4:
				StatsManager.add_statistic_progress("Mega_crit", 1)
		else:
			break


	return int( round(damage * self_damage_multiplier * total_crit))
