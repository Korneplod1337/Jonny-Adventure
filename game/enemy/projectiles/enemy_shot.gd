extends Area2D
class_name EnemyShot

var speed: float = 300.0
var animaited_speed = 1
var direction: Vector2 = Vector2.RIGHT
var atk_range: float = 200.0
@export var damage := [0, 0, 0]

var distance_travelled := 0.0
var exploded := false


func setup(dir: Vector2, damage_values: Vector3i, spd: float, atk_rng: float) -> void:
	direction = dir.normalized()
	damage = [damage_values.x, damage_values.y, damage_values.z]
	speed = spd
	atk_range = atk_rng
	rotation = direction.angle()


func _ready() -> void:
	rotation = direction.angle()

func _physics_process(delta):
	var movement = direction.normalized() * speed * delta
	position += movement
	distance_travelled += movement.length()
	
	if distance_travelled >= atk_range and not exploded:
		exploded = true
		explosion(1)

func _on_body_entered(body):
	if exploded:
		return
	if body.is_in_group("player"):
		body.take_damage(damage[0], damage[1], damage[2])
		exploded = true
		explosion(0)
		return
	exploded = true
	explosion(0)



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
