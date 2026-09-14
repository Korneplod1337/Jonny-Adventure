extends Jonny
class_name JonnyAlt

const START_TEST_SHOT_EQUIP := preload("res://game/objects/Equipment/Weapon/equip/TestShot_equip.tscn")
const EXTRA_SHOT_DELAY := 0.2


func _init() -> void:
	player_name = "JonnyAlt"
	base_max_hp = 2
	base_move_speed = 250.0
	base_luck = 0.2
	base_magic = 0.0
	base_damage = 25.0
	base_spread = 14.0
	base_range = 150.0
	base_fire_rate = 0.8
	hit_points_level = 1.0
	move_speed_level = 1.0
	luck_level = 1.0
	magic_level = 1.0
	damage_level = 3.0
	spread_level = 1.0
	range_level = 3.0
	fire_rate_level = 1.0


func _ready() -> void:
	hp_list = {
		"red": 2,
		"green": 0,
		"blue": 0,
		"black": 4,
	}
	super()


func _equip_start_weapon() -> void:
	var equip: BaseShot_equip = START_TEST_SHOT_EQUIP.instantiate()
	equip.apply_equip(self)


func fire(shot_dir: Vector2) -> void:
	super.fire(shot_dir)
	var dir := shot_dir
	get_tree().create_timer(EXTRA_SHOT_DELAY).timeout.connect(
		func() -> void:
			if is_instance_valid(self):
				_spawn_extra_shot(dir)
	)


func _spawn_extra_shot(shot_dir: Vector2) -> void:
	if not shot_scene or attack_locked or movement_locked:
		return
	var shot = shot_scene.instantiate()
	shot.position = global_position + Vector2(0, -15)
	var angle := shot_dir.angle()
	var effective_spread := spread
	if not shot.use_spread:
		effective_spread = maxf(0.0, spread - 56.0)
	if effective_spread > 0.0 and not GameState.Surestrike:
		angle += deg_to_rad(randf_range(-effective_spread / 2, effective_spread / 2))
	var final_dir := Vector2.RIGHT.rotated(angle)
	shot.direction = final_dir + now_move_direction.normalized() / 3
	shot.damage = StatManager.get_stat(self, "damage")
	shot.atk_range = atk_range
	shot.speed = 300 * (1 + (move_speed_level + fire_rate_level - 8) * 0.05)
	shot.boomerang_power += boomerang_bonus
	shot.penetration += penetration_bonus
	shot.hack += hack_bonus
	if shot_enchantment:
		shot.enchantment = shot_enchantment.duplicate(true)
	if GameState.WildBoots:
		var mag := StatManager.get_stat(self, "magic")
		var chance := lerpf(0.2, 0.4, clampf(mag / 4.0, 0.0, 1.0))
		if randf() < chance:
			shot.extra_enchantment = EquipManager.roll_guaranteed_enchantment()
	get_tree().current_scene.add_child(shot)
