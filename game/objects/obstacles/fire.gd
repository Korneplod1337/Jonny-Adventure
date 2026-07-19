extends Area2D

@export var burn_out_time: float = 10.0
@export var player_phy_damage: int = 1
@export var damage_interval: float = 1.0
@export var projectiles_to_extinguish: int = 2

var _player_in_view: bool = false
var _player_in_fire: Node2D = null
var _burn_elapsed: float = 0.0
var _damage_cd: float = 0.0
var _projectile_hits: int = 0
var _extinguished: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _field_view: Area2D = $FieldViewArea


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 3 # игрок (1) + снаряды (2)
	_sprite.speed_scale = GameState.animated_world_speed
	_sprite.play("default")

	_field_view.monitoring = true
	_field_view.monitorable = false
	_field_view.collision_layer = 0
	_field_view.collision_mask = 1 # только игрок


func _physics_process(delta: float) -> void:
	if _extinguished:
		return

	if _player_in_view:
		_burn_elapsed += delta
		if _burn_elapsed >= burn_out_time:
			_extinguish()
			return

	if _player_in_fire == null:
		return
	if not is_instance_valid(_player_in_fire):
		_player_in_fire = null
		return

	_damage_cd -= delta
	if _damage_cd <= 0.0:
		_deal_player_damage()


func _deal_player_damage() -> void:
	if _player_in_fire == null or not _player_in_fire.has_method("take_damage"):
		return
	_player_in_fire.take_damage(player_phy_damage)
	_damage_cd = damage_interval


func _on_body_entered(body: Node2D) -> void:
	if _extinguished or not body.is_in_group("player"):
		return
	_player_in_fire = body
	if _damage_cd <= 0.0:
		_deal_player_damage()


func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_fire:
		_player_in_fire = null


func _on_area_entered(area: Area2D) -> void:
	if _extinguished or not area is BaseShot:
		return
	var shot := area as BaseShot
	if shot.exploded:
		return
	_projectile_hits += 1
	if _projectile_hits >= projectiles_to_extinguish:
		_extinguish()


func _on_field_view_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_view = true


func _on_field_view_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_view = false


func _extinguish() -> void:
	if _extinguished:
		return
	_extinguished = true
	set_deferred("monitoring", false)
	_field_view.set_deferred("monitoring", false)
	queue_free()
