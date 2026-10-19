extends Area2D

const DEFAULT_SPEED := 400.0
const FAILSAFE_RANGE := 2500.0

var speed: float = DEFAULT_SPEED
var direction: Vector2 = Vector2.UP
var damage: float = 0.0
var distance_travelled: float = 0.0
var exploded: bool = false

@onready var _anim: AnimatedSprite2D = $shot_Animated
@onready var _col: CollisionShape2D = $CollisionShape2D


func setup(dir: Vector2, dmg: float, spd: float = DEFAULT_SPEED) -> void:
	direction = dir.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	damage = dmg
	speed = spd
	rotation = direction.angle()


func _ready() -> void:
	rotation = direction.angle()
	if _anim:
		_anim.play("fly")


func _physics_process(delta: float) -> void:
	if exploded:
		return
	var movement := direction * speed * delta
	position += movement
	distance_travelled += movement.length()
	if distance_travelled >= FAILSAFE_RANGE:
		_impact(null)


func _on_body_entered(body: Node) -> void:
	if exploded:
		return
	if body.is_in_group("player") or body.name == "Player":
		return
	_impact(body)


func _impact(body: Node) -> void:
	exploded = true
	_disable_hitboxes()
	speed = 0.0
	if body != null and body.has_method("hit") and damage > 0.0:
		body.hit(damage)
	_play_and_free(&"hit")


func _disable_hitboxes() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if _col:
		_col.set_deferred("disabled", true)


func _play_and_free(anim_name: StringName) -> void:
	_anim.play(anim_name)
	if not _anim.animation_finished.is_connected(_on_animation_finished):
		_anim.animation_finished.connect(_on_animation_finished)


func _on_animation_finished() -> void:
	queue_free()
