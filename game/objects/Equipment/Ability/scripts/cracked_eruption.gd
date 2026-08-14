extends Area2D

const VARIATIONS: Array[StringName] = [&"variation 1", &"variation 2", &"variation 3"]
const DAMAGE := 15.0

var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
var atk_range: float = 50.0

var distance_travelled: float = 0.0
var exploded: bool = false
var _hit_anim: StringName = &"variation 1"

@onready var _anim: AnimatedSprite2D = $shot_Animated
@onready var _col: CollisionShape2D = $CollisionShape2D


func setup(dir: Vector2, spd: float, rng: float) -> void:
	direction = dir.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	speed = spd
	atk_range = rng


func _ready() -> void:
	_hit_anim = VARIATIONS[randi() % VARIATIONS.size()]
	rotation = direction.angle()
	_anim.animation = _hit_anim
	_anim.frame = 0
	_anim.pause()


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
		body.hit(DAMAGE)
	_play_and_free(_hit_anim)


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
