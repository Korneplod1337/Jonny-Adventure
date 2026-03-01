extends Area2D

var speed: float = 300.0
@export var animaited_speed = 2
var direction: Vector2 = Vector2.RIGHT
var atk_range: float = 200.0
var damage: int = 25
var extra_reload: float = 1 # только для слёз 
const self_damage_multiplier: float = 1.5
const self_speed_multiplier: float = 1.5
const self_range_multiplier: float = 0.6


var distance_travelled := 0.0

var exploded := false

func _physics_process(delta):
	var movement = direction.normalized() * speed * delta * self_speed_multiplier
	position += movement
	distance_travelled += movement.length()
	
	if distance_travelled >= atk_range * self_range_multiplier and not exploded:
		exploded = true
		explosion()

func _on_body_entered(body):
	if exploded:
		return
	if body.name == "Player":
		return
	if body.has_method("hit"):
		body.hit(damage * self_damage_multiplier)
	exploded = true
	explosion()



func explosion():
	speed = 0
	$shot_Animated.speed_scale = animaited_speed
	$shot_Animated.play("default")
	if not $shot_Animated.is_connected("animation_finished", Callable(self, "_on_explosion_finished")):
		$shot_Animated.connect("animation_finished", Callable(self, "_on_explosion_finished"))


func _on_explosion_finished():
	queue_free()
