extends Area2D
class_name BaseShot

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

var distance_travelled := 0.0
var exploded := false

var enchantment: EnchantmentResource

var penetration: int = 0 ## Число врагов, сквозь которых снаряд проходит, не исчезая (0 — остановка на первом).
var _enemy_hit_count: int = 0

var spread_angle: float
var spawned_spread := false

func _ready() -> void:
	collision_mask |= 32 # layer 6 — Препятствия
	animaited_speed = GameState.animated_world_speed
	player = get_tree().get_first_node_in_group("player")
	rotation = direction.angle()
	spread_angle = StatManager.get_stat(player, "spread")
	if pellet_count > 1 and not spawned_spread:
		spawned_spread = true
		_spawn_spread()

func _physics_process(delta):
	var movement = direction.normalized() * speed * delta * self_speed_multiplier
	position += movement
	distance_travelled += movement.length()
	
	if distance_travelled >= atk_range * self_range_multiplier and not exploded:
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


func _get_final_damage() -> float:
	var final_damage := float(damage * self_damage_multiplier)
	if enchantment and enchantment.has_method("get_damage_low"):
		final_damage *= enchantment.get_damage_low() #для яда
	return final_damage


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
		bullet.enchantment = enchantment
		bullet.penetration = penetration
		bullet.use_spread = use_spread
		bullet.pellet_count = pellet_count
		bullet.spread_angle = spread_angle

		if self is BaseGun and bullet is BaseGun:
			bullet.base_crit_bonus = self.base_crit_bonus

		get_parent().add_child.call_deferred(bullet)
		bullet.global_position = global_position
