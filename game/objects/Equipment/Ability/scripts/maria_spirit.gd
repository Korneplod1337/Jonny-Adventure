extends Node2D

const SHOT_SCENE := preload("res://game/objects/Equipment/Ability/effects/MariaShot.tscn")

var damage: float = 100.0
var fire_interval: float = 0.5
var rot_speed_rad: float = TAU / 4.0  # 360 deg / 4s
var lifetime: float = 4.0

var _aim_angle: float = -PI / 2.0  # up
var _fire_cd: float = 0.0
var _alive: float = 0.0

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _marker: Marker2D = $ShotMarker


func setup(magic: float) -> void:
	var t := clampf(magic / 4.0, 0.0, 1.0)
	damage = lerpf(100.0, 75.0, t)
	fire_interval = lerpf(0.5, 0.1, t)
	var rot_period := lerpf(4.0, 2.0, t)
	rot_speed_rad = TAU / maxf(rot_period, 0.01)
	lifetime = lerpf(4.0, 8.0, t)


func _ready() -> void:
	_anim.play("idle")
	_fire_cd = 0.0
	_alive = 0.0
	_aim_angle = -PI / 2.0


func _physics_process(delta: float) -> void:
	_alive += delta
	if _alive >= lifetime:
		queue_free()
		return

	# Clockwise from up (Godot 2D: positive angle = clockwise).
	_aim_angle += rot_speed_rad * delta
	_fire_cd -= delta
	if _fire_cd <= 0.0:
		_fire_cd = fire_interval
		_shoot()


func _shoot() -> void:
	var dir := Vector2.RIGHT.rotated(_aim_angle)
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	var shot := SHOT_SCENE.instantiate()
	shot.setup(dir, damage)
	parent.add_child(shot)
	shot.global_position = _marker.global_position
