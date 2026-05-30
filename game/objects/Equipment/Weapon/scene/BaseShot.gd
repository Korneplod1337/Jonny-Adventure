extends Area2D
class_name BaseShot

var speed: float = 300.0
var animaited_speed = 1
var direction: Vector2 = Vector2.RIGHT
var atk_range: float = 200.0
var damage: int
var extra_reload: float = 1.0 # только для слёз множитель больше 1 1,6 MAX
@export var use_spread: bool = true
var self_damage_multiplier: float = 1
var self_speed_multiplier: float = 1
var self_range_multiplier: float = 1

var distance_travelled := 0.0

var exploded := false

var enchantment: EnchantmentResource

func _ready() -> void:
	animaited_speed = GameState.animated_world_speed
	#var player := get_tree().get_first_node_in_group("player")
	rotation = direction.angle()

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
		_deal_hit(body, _get_final_damage())
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
	if target is Node2D:
		info.direction = (target.global_position - weapon_point).normalized()
	return info


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
