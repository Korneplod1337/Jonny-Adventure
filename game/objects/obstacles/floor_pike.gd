extends Area2D

enum State { INACTIVE, OPENING, ACTIVE, CLOSING }

@export var initial_delay: float = 1.0
@export var active_duration: float = 2.0
@export var player_phy_damage: int = 1
@export var enemy_damage: float = 20.0

var _state: State = State.INACTIVE
var _damaged_bodies: Dictionary = {}

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	monitoring = false
	_sprite.speed_scale = GameState.animated_world_speed
	_sprite.frame_changed.connect(_on_frame_changed)
	_set_closed_visual()
	_start_cycle()


func _start_cycle() -> void:
	_state = State.INACTIVE
	_damaged_bodies.clear()
	monitoring = false
	await get_tree().create_timer(initial_delay).timeout
	if not is_inside_tree():
		return
	_begin_opening()


func _begin_opening() -> void:
	_state = State.OPENING
	_sprite.play("Open")


func _begin_active() -> void:
	if _state == State.ACTIVE:
		return
	_state = State.ACTIVE
	monitoring = true
	_check_overlapping_bodies()
	await get_tree().create_timer(active_duration).timeout
	if not is_inside_tree() or _state != State.ACTIVE:
		return
	_begin_closing()


func _begin_closing() -> void:
	_state = State.CLOSING
	monitoring = false
	_damaged_bodies.clear()
	_sprite.play("Close")


func _set_closed_visual() -> void:
	_sprite.animation = &"Close"
	_sprite.frame = _sprite.sprite_frames.get_frame_count(&"Close") - 1


func _on_body_entered(body: Node2D) -> void:
	if _state != State.ACTIVE:
		return
	_try_damage(body)


func _check_overlapping_bodies() -> void:
	for body in get_overlapping_bodies():
		_try_damage(body)


func _try_damage(body: Node) -> void:
	var id := body.get_instance_id()
	if _damaged_bodies.has(id):
		return

	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(player_phy_damage)
			_damaged_bodies[id] = true
	elif body.is_in_group("Enemy"):
		if body.has_method("hit") and not body.get("is_dead"):
			body.hit(enemy_damage)
			_damaged_bodies[id] = true


func _on_frame_changed() -> void:
	if _state != State.OPENING or _sprite.animation != &"Open":
		return
	var open_frames := _sprite.sprite_frames.get_frame_count(&"Open")
	if _sprite.frame == open_frames - 1:
		_begin_active()


func _on_animation_finished() -> void:
	if _state == State.CLOSING:
		_set_closed_visual()
		_start_cycle()
