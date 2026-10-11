extends StaticBody2D
## Дверь в банковский vault. Пока закрыта — можно стрелять (hit).
## После 70 HP: играет AnimatedSprite2D "open" → active → телепорт.

const HOLD_TIME := 0.1
const CLOSED_ALPHA := 0.22

@export var max_hp: float = 70.0
@export var dir: Vector2 = Vector2(-1, 0)
@export var target_room_pos: Vector2 = Vector2(50, 50)
@export var entrance_offset: Vector2 = Vector2(64, 0)
@export var open_animation: StringName = &"open"
@export var idle_animation: StringName = &"idle"

var active := false
var _hp: float = 70.0
var _opening := false
var _player_inside: Node2D = null
var _hold_timer := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var teleport_area: Area2D = $TeleportArea
@onready var block_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_hp = max_hp
	## 4 = shot/enemy layer, 16 = wall layer (blocks player)
	collision_layer = 4 | 16
	collision_mask = 0
	## Not in "Door" group — bank RoomScript.shuffle_doors must not move this door.
	modulate.a = CLOSED_ALPHA
	active = false
	if teleport_area:
		teleport_area.monitoring = false
		teleport_area.monitorable = false
	if anim:
		anim.modulate.a = 1.0
		if anim.sprite_frames and anim.sprite_frames.has_animation(idle_animation):
			anim.play(idle_animation)
			anim.pause()
			anim.frame = 0


func configure(direction: Vector2, target_pos: Vector2, _target_room_type: int, offset: Vector2) -> void:
	dir = direction
	target_room_pos = target_pos
	entrance_offset = offset


func disable_as_unused() -> void:
	## Вызывается для банков, которые не являются первым на этаже.
	visible = false
	active = false
	collision_layer = 0
	if block_shape:
		block_shape.set_deferred("disabled", true)
	if teleport_area:
		teleport_area.monitoring = false
		teleport_area.monitorable = false
	set_physics_process(false)


func hit(amount: float, _clear := false) -> void:
	if active or _opening:
		return
	_hp -= amount
	_flash()
	if _hp <= 0.0:
		_open()


func _flash() -> void:
	if not is_instance_valid(anim):
		return
	anim.modulate = Color(1.4, 1.4, 1.4, 1.0)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(anim) and not active:
		anim.modulate = Color.WHITE


func _open() -> void:
	if _opening or active:
		return
	_opening = true
	collision_layer = 0
	if block_shape:
		block_shape.set_deferred("disabled", true)

	modulate.a = 1.0
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation(open_animation):
		anim.play(open_animation)
		await anim.animation_finished
	else:
		await get_tree().create_timer(0.2).timeout

	active = true
	_opening = false
	if teleport_area:
		teleport_area.monitoring = true
		teleport_area.monitorable = true


func _physics_process(delta: float) -> void:
	if not active or _player_inside == null:
		_hold_timer = 0.0
		return
	if not _is_pressing_door_direction():
		_hold_timer = 0.0
		return
	_hold_timer += delta
	if _hold_timer < HOLD_TIME:
		return
	_hold_timer = 0.0
	var body := _player_inside
	_player_inside = null
	var dungeon := get_tree().current_scene
	if dungeon and dungeon.has_method("teleport_player"):
		dungeon.teleport_player(self, body)


func _is_pressing_door_direction() -> bool:
	var facing := dir
	if facing == Vector2.ZERO:
		facing = Vector2.LEFT
	if absf(facing.y) >= absf(facing.x):
		return Input.is_action_pressed("move_up" if facing.y < 0 else "move_down")
	return Input.is_action_pressed("move_left" if facing.x < 0 else "move_right")


func _on_teleport_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = body


func _on_teleport_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _player_inside == body:
		_player_inside = null
		_hold_timer = 0.0


func reactivate_after_room_clear() -> void:
	if active:
		_hold_timer = 0.0
