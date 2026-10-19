extends Node2D

const SHOT_SCENE := preload("res://game/objects/Equipment/Ability/effects/KeresShot.tscn")
const WAVE_INTERVAL := 1.0
const ANGLE_STEP_DEG := 15.0

var remaining_damage: float = 25.0
var max_wave_damage: float = 25.0
var _wave_cd: float = 0.0

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _marker: Marker2D = $ShotMarker


func setup(magic: float) -> void:
	var t := clampf(magic / 4.0, 0.0, 1.0)
	remaining_damage = lerpf(50.0, 240.0, t)
	max_wave_damage = lerpf(25.0, 40.0, t)


func _ready() -> void:
	_anim.play("idle")
	# First wave immediately on spawn.
	_wave_cd = 0.0


func _physics_process(delta: float) -> void:
	_wave_cd -= delta
	if _wave_cd > 0.0:
		return
	_wave_cd = WAVE_INTERVAL
	if remaining_damage <= 0.0:
		queue_free()
		return
	_fire_wave()


func _fire_wave() -> void:
	var wave_dmg := minf(max_wave_damage, remaining_damage)
	remaining_damage -= wave_dmg

	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()

	var spawn_pos := _marker.global_position
	var angle := 0.0
	while angle < 360.0 - 0.01:
		var dir := Vector2.RIGHT.rotated(deg_to_rad(angle))
		var shot := SHOT_SCENE.instantiate()
		shot.setup(dir, wave_dmg)
		if parent is Node2D:
			shot.position = (parent as Node2D).to_local(spawn_pos)
		else:
			shot.position = spawn_pos
		parent.add_child(shot)
		angle += ANGLE_STEP_DEG
