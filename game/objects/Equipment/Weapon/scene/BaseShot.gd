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
	var player := get_tree().get_first_node_in_group("player")

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
	if enchantment:
		enchantment.apply_on_hit(body, (body.global_position - global_position).normalized())
	if body.has_method("hit"):
		body.hit(damage * self_damage_multiplier)
	exploded = true
	explosion(0)



func explosion(animation_index):
	print('animation_index ', animation_index)
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
