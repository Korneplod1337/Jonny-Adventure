extends BaseEnemy
class_name EnemyRanger

@export var projectile_scene: PackedScene
@export var hard_projectile_damage: int = 1

var projectile_speed: float
var projectile_range: float
var projectile_damage: int = 1


func _ready() -> void:
	super._ready()


func get_projectile_damage() -> Vector3i:
	return _build_damage_vector(projectile_damage)


func shoot_projectile(direction: Vector2) -> void:
	if not projectile_scene or direction == Vector2.ZERO:
		return

	var shot: Node2D = projectile_scene.instantiate()
	var dir := direction.normalized()
	shot.global_position = global_position + dir * 12.0

	shot.owner_enemy = self
	shot.setup(dir, get_projectile_damage(), projectile_speed, projectile_range)
	get_tree().current_scene.add_child(shot)
	sprite.flip_h = dir.x < 0
