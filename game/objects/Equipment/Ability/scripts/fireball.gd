extends Area2D

const BASE_DAMAGE := 40.0
const MAGIC_DAMAGE_STEP := 0.2
const BONUS_PER_STEP := 2.0
const BASE_RANGE := 200.0
const MAGIC_RANGE_STEP := 0.1
const RANGE_PER_STEP := 12.0

var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
var atk_range: float = 150.0
var damage: float = BASE_DAMAGE

var distance_travelled: float = 0.0
var exploded: bool = false

@onready var _anim: AnimatedSprite2D = $shot_Animated
@onready var _col: CollisionShape2D = $CollisionShape2D


func setup(dir: Vector2, spd: float, magic: float) -> void:
	direction = dir.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	speed = spd
	atk_range = BASE_RANGE + floor(magic / MAGIC_RANGE_STEP) * RANGE_PER_STEP
	damage = BASE_DAMAGE + floor(magic / MAGIC_DAMAGE_STEP) * BONUS_PER_STEP


func _ready() -> void:
	rotation = direction.angle()
	_anim.play("fly")


func _physics_process(delta: float) -> void:
	if exploded:
		return
	var movement := direction * speed * delta
	position += movement
	distance_travelled += movement.length()
	if distance_travelled >= atk_range:
		_explode_miss()


func _on_body_entered(body: Node) -> void:
	if exploded:
		return
	if body.is_in_group("player") or body.name == "Player":
		return
	exploded = true
	_disable_hitboxes()
	speed = 0.0
	if body.has_method("hit"):
		body.hit(damage)
	_play_and_free(&"hit")


func _explode_miss() -> void:
	exploded = true
	_disable_hitboxes()
	speed = 0.0
	_play_and_free(&"miss")


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
