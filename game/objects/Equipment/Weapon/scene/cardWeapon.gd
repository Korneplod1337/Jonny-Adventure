class_name CardShot
extends BaseShot

@export var spin_speed: float = 10.0

@onready var _anim_sprite: AnimatedSprite2D = $shot_Animated

var _spin_angle := 0.0


func _ready() -> void:
	penetration = 1
	extra_reload = 1.2
	self_damage_multiplier = 0.75
	self_range_multiplier = 0.75
	animaited_speed = GameState.animated_world_speed
	rotation = direction.angle()
	super()


func _physics_process(delta: float) -> void:
	if not exploded:
		_spin_angle += spin_speed * delta
		_anim_sprite.rotation = _spin_angle
	super._physics_process(delta)


func _on_body_entered(body: Node) -> void:
	if exploded:
		return
	if body.is_in_group("player"):
		return

	if body.has_method("hit"):
		_handle_enemy_contact(body)
	else:
		_break_shot()


func _handle_enemy_contact(enemy: Node) -> void:
	if _register_pierce_hit(enemy, _get_final_damage()):
		_break_shot()


func _break_shot() -> void:
	if exploded:
		return
	exploded = true
	explosion(0)
