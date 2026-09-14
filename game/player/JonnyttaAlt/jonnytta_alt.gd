extends Jonny
class_name JonnyttaAlt

const START_SPEAR_EQUIP := preload("res://game/objects/Equipment/Weapon/equip/Spear_equip.tscn")
const TRIPLE_ANGLES_DEG: Array[float] = [-30.0, 0.0, 30.0]
const WEAPON_SCALE_MULT := 0.75


func _init() -> void:
	player_name = "JonnyttaAlt"
	base_max_hp = 5
	base_move_speed = 250.0
	base_luck = 0.2
	base_magic = 0.0
	base_damage = 32.0
	base_spread = 30.0
	base_range = 160.0
	base_fire_rate = 0.5
	hit_points_level = 2.0
	move_speed_level = 1.0
	luck_level = 1.0
	magic_level = 1.0
	damage_level = 1.0
	spread_level = 4.0
	range_level = 3.0
	fire_rate_level = 1.0


func _ready() -> void:
	hp_list = {
		"red": max(0, StatManager.get_stat(self, "hp")),
		"green": 0,
		"blue": 0,
		"black": 0,
	}
	super()


func _equip_start_weapon() -> void:
	var equip: BaseShot_equip = START_SPEAR_EQUIP.instantiate()
	equip.apply_equip(self)


func fire(shot_dir: Vector2) -> void:
	if not shot_scene:
		return
	var apply_ability := true
	for offset_deg in TRIPLE_ANGLES_DEG:
		_spawn_scaled_shot(shot_dir, offset_deg, apply_ability)
		apply_ability = false
	extra_fire_rate = 0.0
	var cloak_fx := get_node_or_null("Accelerator_Cloak")
	if cloak_fx and cloak_fx.has_method("update_boost"):
		cloak_fx.update_boost()
	fire_rate = ST.get_stat(self, "fire_rate")


func _spawn_scaled_shot(shot_dir: Vector2, angle_offset_deg: float, apply_ability: bool) -> void:
	var shot = shot_scene.instantiate()
	shot.position = global_position + Vector2(0, -15)
	var angle := shot_dir.angle() + deg_to_rad(angle_offset_deg)
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
	if apply_ability:
		steal_life_heal_ready = false
		if current_ability and current_ability.has_method("consume_for_next_shot"):
			if current_ability.consume_for_next_shot():
				shot.steal_life = true
				steal_life_heal_ready = true
	if shot_enchantment:
		shot.enchantment = shot_enchantment.duplicate(true)
	if GameState.WildBoots:
		var mag := StatManager.get_stat(self, "magic")
		var chance := lerpf(0.2, 0.4, clampf(mag / 4.0, 0.0, 1.0))
		if randf() < chance:
			shot.extra_enchantment = EquipManager.roll_guaranteed_enchantment()
	get_tree().current_scene.add_child(shot)
	# После _ready ближнего оружия (оно само выставляет scale).
	shot.scale *= WEAPON_SCALE_MULT
	extra_fire_rate = shot.extra_reload
