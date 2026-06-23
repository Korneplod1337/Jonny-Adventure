extends Node2D

enum State { READY, CAPTURED, COOLDOWN }

const COIN_SCENE := preload("res://game/objects/coins/Coin.tscn")

@export var base_hp: int = 50
@export var capture_duration: float = 2.0
@export var cooldown_duration: float = 2.0
@export var player_phy_damage: int = 1

var current_hp: int
var is_dead: bool = false
var _state: State = State.READY
var _cycle_token: int = 0
var _trapped_player: Node2D = null
var _damage_flash_token: int = 0

@onready var _trap_area: Area2D = $TrapArea
@onready var _hit_area: Area2D = $HitArea
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hit_shape: CollisionShape2D = $HitArea/CollisionShape2D


func _ready() -> void:
	current_hp = base_hp
	_set_trap_monitoring(true)
	_hit_area.monitoring = true
	_sprite.speed_scale = GameState.animated_world_speed
	_sprite.play("Open")


func _physics_process(_delta: float) -> void:
	if _state != State.CAPTURED or _trapped_player == null:
		return
	if not is_instance_valid(_trapped_player):
		_trapped_player = null
		return
	_trapped_player.global_position = global_position
	_trapped_player.velocity = Vector2.ZERO


func _on_trap_area_body_entered(body: Node2D) -> void:
	if _state != State.READY or is_dead:
		return
	if not body.is_in_group("player"):
		return
	_capture_player(body)


func _on_hit_area_area_entered(area: Area2D) -> void:
	if is_dead or not area is BaseShot:
		return
	var shot := area as BaseShot
	if shot.exploded:
		return
	if shot._register_pierce_hit(self, shot._get_final_damage()):
		shot.exploded = true
		shot.explosion(0)


func _capture_player(player: Node2D) -> void:
	_cycle_token += 1
	var my_token := _cycle_token

	_state = State.CAPTURED
	_trapped_player = player
	_set_trap_monitoring(false)

	player.global_position = global_position
	player.velocity = Vector2.ZERO
	player.set_movement_locked(true)

	_sprite.play("Close")
	player.take_damage(player_phy_damage)

	await get_tree().create_timer(capture_duration).timeout
	if my_token != _cycle_token or is_dead or not is_inside_tree():
		return

	_release_player()
	_begin_cooldown(my_token)


func _release_player() -> void:
	if _trapped_player != null and is_instance_valid(_trapped_player):
		_trapped_player.set_movement_locked(false)
	_trapped_player = null


func _begin_cooldown(token: int) -> void:
	_state = State.COOLDOWN
	_set_closed_visual()

	await get_tree().create_timer(cooldown_duration).timeout
	if token != _cycle_token or is_dead or not is_inside_tree():
		return

	_state = State.READY
	_set_trap_monitoring(true)
	_sprite.play("Open2")


func _set_trap_monitoring(enabled: bool) -> void:
	_trap_area.set_deferred("monitoring", enabled)


func _set_closed_visual() -> void:
	_sprite.animation = &"Close"
	_sprite.frame = _sprite.sprite_frames.get_frame_count(&"Close") - 1


func hit(amount: float, clear := false) -> void:
	if is_dead:
		return
	if not clear:
		_flash_damage()
	current_hp -= amount
	if current_hp <= 0:
		die()


func _flash_damage() -> void:
	_damage_flash_token += 1
	var my_token := _damage_flash_token
	_sprite.modulate.a = 0.4
	await get_tree().process_frame
	if my_token != _damage_flash_token or not is_instance_valid(self):
		return
	_sprite.modulate.a = 1.0


func die() -> void:
	if is_dead:
		return
	is_dead = true
	_cycle_token += 1
	_state = State.COOLDOWN
	_release_player()
	_set_trap_monitoring(false)
	_hit_area.set_deferred("monitoring", false)
	_hit_shape.set_deferred("disabled", true)
	_sprite.play("Break")


func _on_animation_finished() -> void:
	if _sprite.animation == &"Break":
		_try_spawn_coin()
		queue_free()


func _try_spawn_coin() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var luck := StatManager.get_stat(player, "luck")
	if randf() < luck * 0.5:
		var coin := COIN_SCENE.instantiate()
		coin.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", coin)
