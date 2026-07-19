extends Area2D

const ANIM_PREPARING := &"preparing"
const ANIM_SHOT := &"shot"
const FIRE_SCENE := preload("res://game/objects/obstacles/fire.tscn")

@export var mag_damage: int = 1
## Масштаб всей сцены молнии (спрайт + хитбокс).
@export var size_scale: float = 2.0
## Секунды подготовки. FPS preparing = число_кадров / prepare_time.
@export var prepare_time: float = 6.0
## Сколько секунд играет shot, затем молния исчезает.
@export var active_duration: float = 1.0
## Если true — в конце удара спавнится огонь на месте молнии.
@export var spawn_fire: bool = false

var _active: bool = false
var _damaged_player: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = false
	monitorable = false
	scale = Vector2(size_scale, size_scale)
	_sprite.sprite_frames = _sprite.sprite_frames.duplicate()
	_sprite.speed_scale = GameState.animated_world_speed
	_start_preparing()


func _start_preparing() -> void:
	_active = false
	monitoring = false
	var frames := _sprite.sprite_frames.get_frame_count(ANIM_PREPARING)
	var fps := float(frames) / maxf(prepare_time, 0.001)
	_sprite.sprite_frames.set_animation_speed(ANIM_PREPARING, fps)
	_sprite.play(ANIM_PREPARING)


func _start_shot() -> void:
	_active = true
	_damaged_player = false
	monitoring = true
	_sprite.play(ANIM_SHOT)
	_check_overlapping_bodies()
	await get_tree().create_timer(active_duration).timeout
	if not is_inside_tree():
		return
	_finish()


func _finish() -> void:
	if spawn_fire:
		var fire := FIRE_SCENE.instantiate()
		fire.global_position = global_position + Vector2(0, -10)
		get_tree().current_scene.call_deferred("add_child", fire)
	queue_free()


func _on_animation_finished() -> void:
	if _sprite.animation == ANIM_PREPARING:
		_start_shot()


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	_try_damage(body)


func _check_overlapping_bodies() -> void:
	for body in get_overlapping_bodies():
		_try_damage(body)


func _try_damage(body: Node) -> void:
	if _damaged_player:
		return
	if not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(0, mag_damage)
		_damaged_player = true
