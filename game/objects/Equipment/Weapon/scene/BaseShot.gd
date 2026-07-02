extends Area2D
class_name BaseShot

const BOOMERANG_MIN_CURVE_T_RATE := 0.06
const BOOMERANG_SPEED_CURVE := preload("res://game/combat/boomerang_speed_curve.tres")

var player
var speed: float = 300.0
var animaited_speed = 1
var direction: Vector2 = Vector2.RIGHT
var atk_range: float
var damage: int
var extra_reload: float = 1.0 # только для слёз множитель больше 1 1,6 MAX
@export var use_spread: bool = true
@export var pellet_count := 1
@export var self_damage_multiplier: float = 1
@export var self_speed_multiplier: float = 1
@export var self_range_multiplier: float = 1
## 0 — прямой полёт; 1 — туда + обратно; 2+ — дополнительные отрезки пути.
@export var boomerang_power: int = 0

var distance_travelled := 0.0
var exploded := false

var _max_boomerang_range := 0.0
var _boomerang_segment := 0
var _boomerang_segment_count := 0
var _segment_curve_t := 0.0
var _segment_trip_duration := 1.0
var _boomerang_active := false

var enchantment: EnchantmentResource

var penetration: int = 0 ## Число врагов, сквозь которых снаряд проходит, не исчезая (0 — остановка на первом).
var _enemy_hit_count: int = 0

var spread_angle: float
var spawned_spread := false

var base_crit_bonus: float = 60.0
var crit_sprite: int = -1

const CRIT_WORLD_OFFSET := Vector2(0, -60)

func _ready() -> void:
	collision_mask |= 32 # layer 6 — Препятствия
	animaited_speed = GameState.animated_world_speed
	player = get_tree().get_first_node_in_group("player")
	rotation = direction.angle()
	spread_angle = StatManager.get_stat(player, "spread")
	if GameState.Surestrike:
		spread_angle = 0.0
	if pellet_count > 1 and not spawned_spread:
		spawned_spread = true
		_spawn_spread()
	_init_boomerang()

func _physics_process(delta: float) -> void:
	if exploded:
		return
	if _boomerang_active:
		_physics_process_boomerang(delta)
	else:
		_physics_process_linear(delta)


func _physics_process_linear(delta: float) -> void:
	var movement := direction.normalized() * speed * delta * self_speed_multiplier
	position += movement
	distance_travelled += movement.length()

	if distance_travelled >= atk_range * self_range_multiplier:
		exploded = true
		explosion(1)


func _physics_process_boomerang(delta: float) -> void:
	if _boomerang_segment >= _boomerang_segment_count:
		_finish_boomerang_path()
		return

	if _segment_curve_t >= 1.0:
		_advance_boomerang_segment()
		return

	var outbound := _boomerang_segment % 2 == 0
	var sample_t := lerpf(0.0, 0.5, _segment_curve_t) if outbound else lerpf(0.5, 1.0, _segment_curve_t)
	var mult := BOOMERANG_SPEED_CURVE.sample(sample_t)
	var move_dir := direction.normalized()

	var step := move_dir * speed * absf(mult) * delta * self_speed_multiplier
	global_position += step
	rotation = move_dir.angle()
	distance_travelled += step.length()

	var t_rate := maxf(absf(mult), BOOMERANG_MIN_CURVE_T_RATE)
	_segment_curve_t += (t_rate * delta) / _segment_trip_duration
	_segment_curve_t = minf(_segment_curve_t, 1.0)


func _init_boomerang() -> void:
	if boomerang_power <= 0:
		_boomerang_active = false
		return

	_max_boomerang_range = atk_range * self_range_multiplier
	_boomerang_segment_count = boomerang_power + 1
	_boomerang_segment = 0
	_segment_curve_t = 0.0
	_segment_trip_duration = _max_boomerang_range / maxf(speed * self_speed_multiplier, 1.0)
	_boomerang_active = true


func _advance_boomerang_segment() -> void:
	direction = -direction
	_boomerang_segment += 1
	_segment_curve_t = 0.0
	if _boomerang_segment >= _boomerang_segment_count:
		_finish_boomerang_path()

func _finish_boomerang_path() -> void:
	if exploded:
		return
	exploded = true
	explosion(1)


func _on_body_entered(body):
	if exploded:
		return
	if body.name == "Player":
		return
	if body.has_method("hit"):
		if _register_pierce_hit(body, _get_final_damage()):
			exploded = true
			explosion(0)
		return
	exploded = true
	explosion(0)


func _get_player() -> Node:
	if player:
		return player
	return get_tree().get_first_node_in_group("player")


func _get_crit_chance() -> float:
	var shooter := _get_player()
	if shooter:
		return shooter.crit_chance_bonus
	return 0.0


func _get_final_damage() -> float:
	crit_sprite = -1
	var final_damage := float(damage * self_damage_multiplier)
	if enchantment and enchantment.has_method("get_damage_low"):
		final_damage *= enchantment.get_damage_low() #для яда

	var chance := _get_crit_chance()
	var spread_val := 20.0
	var shooter := _get_player()
	if shooter:
		spread_val = StatManager.get_stat(shooter, "spread")
	var crit_bonus := base_crit_bonus / (spread_val + 20)
	var total_crit := 1.0
	while true:
		if randf() < chance:
			crit_sprite += 1
			total_crit += crit_bonus
			chance -= 0.2
			if crit_sprite == 4:
				StatsManager.add_statistic_progress("Mega_crit", 1)
				break
		else:
			break
	return final_damage * total_crit


func _show_crit_effect() -> void:
	if crit_sprite < 0:
		return
	var crit_node := get_node_or_null("Crit")
	if crit_node is AnimatedSprite2D:
		crit_node.position = CRIT_WORLD_OFFSET.rotated(-rotation)
		crit_node.rotation = -rotation
		crit_node.frame = crit_sprite
		crit_node.show()


func _build_damage_info(target: Node, amount: float) -> DamageInfo:
	var info := DamageInfo.new()
	info.damage = amount
	info.source = self
	var weapon_point := _get_weapon_hit_point()
	info.hit_position = DamageDealer.get_hit_contact_point(self, target, weapon_point)
	info.enchantment = enchantment
	info.penetration = penetration
	if target is Node2D:
		info.direction = (target.global_position - weapon_point).normalized()
	return info


func _get_effective_penetration() -> int:
	var info := DamageInfo.new()
	info.penetration = penetration
	DamageDealer.apply_hit_modifiers(info)
	return info.penetration


func _register_pierce_hit(target: Node, amount: float) -> bool:
	_deal_hit(target, amount)
	_enemy_hit_count += 1
	return _enemy_hit_count > _get_effective_penetration()


func _deal_hit(target: Node, amount: float) -> void:
	DamageDealer.deal_damage(self, target, _build_damage_info(target, amount))
	_show_crit_effect()


func explosion(animation_index):
	speed = 0
	$shot_Animated.speed_scale = animaited_speed
	if animation_index == 0:
		$shot_Animated.play("default")
	elif animation_index == 1:
		$shot_Animated.play("miss")

	if not $shot_Animated.is_connected("animation_finished", Callable(self, "_on_explosion_finished")):
		$shot_Animated.connect("animation_finished", Callable(self, "_on_explosion_finished"))

func _on_explosion_finished():
	queue_free()


func _get_weapon_hit_point() -> Vector2:
	var col := get_node_or_null("CollisionShape2D")
	if col is CollisionShape2D:
		return col.global_position
	return global_position


func _spawn_spread() -> void:
	var base_dir := direction.normalized()
	var half_spread := deg_to_rad(spread_angle) / 2.0
	var is_even := pellet_count % 2 == 0

	var step: float
	var start_angle: float
	var center: int

	if is_even:
		# Чётное число — симметрично вокруг центра, без выстрела в центр
		step = deg_to_rad(spread_angle) / float(pellet_count)
		start_angle = -half_spread + step / 2.0
		center = -1
	else:
		# Нечётное число — одна дробинка в центре (текущий снаряд)
		center = pellet_count / 2
		step = deg_to_rad(spread_angle) / float(pellet_count - 1)
		start_angle = -half_spread

	for i in range(pellet_count):
		var angle := start_angle + step * i
		if not is_even and i == center:
			continue
		if is_even and i == 0:
			direction = base_dir.rotated(angle)
			rotation = direction.angle()
			if has_node("Crit"):
				var crit_node: AnimatedSprite2D = $Crit
				crit_node.position = Vector2(0, -60).rotated(-rotation)
				crit_node.rotation = -rotation
			continue

		var bullet: BaseShot = duplicate()
		bullet.direction = base_dir.rotated(angle)
		bullet.rotation = bullet.direction.angle()
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
		bullet.boomerang_power = boomerang_power
		bullet.enchantment = enchantment
		bullet.penetration = penetration
		bullet.use_spread = use_spread
		bullet.pellet_count = pellet_count
		bullet.spread_angle = spread_angle

		bullet.base_crit_bonus = self.base_crit_bonus

		get_parent().add_child.call_deferred(bullet)
		bullet.global_position = global_position
