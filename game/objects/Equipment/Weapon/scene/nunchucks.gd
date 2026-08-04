extends SwordShot
class_name NunchucksShot

@onready var _anim_sprite: AnimatedSprite2D = $shot_Animated
@onready var _lifetime_timer: Timer = $Timer


func _ready() -> void:
	speed = 0
	self_damage_multiplier = 1.2
	rotation = direction.angle()
	if not _melee_boomerang_copy:
		_play_attack_sfx()
		_fire_direction = direction.normalized()
		if boomerang_power > 0:
			_melee_boomerang_legs = BoomerangPath.build_legs(boomerang_power)

	_melee_size_scale = clampf(0.6 + atk_range / 600.0, 0.8, 2.0)
	scale = Vector2(_melee_size_scale, _melee_size_scale)
	if not _melee_boomerang_copy:
		_melee_spin_duration = _lifetime_timer.wait_time
	_lifetime_timer.wait_time = _melee_spin_duration

	_anim_sprite.speed_scale = GameState.animated_world_speed
	_anim_sprite.play("default")
	_lifetime_timer.start()
	if not body_exited.is_connected(_on_body_exited_ricochet):
		body_exited.connect(_on_body_exited_ricochet)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		return
	if _ricochet_overlap_id != 0 and body.get_instance_id() == _ricochet_overlap_id:
		return
	if body.has_method("hit"):
		if not _is_ricochet_ignored(body):
			_deal_hit(body, _get_final_damage())
		_try_ricochet(body)
	else:
		_try_ricochet(body)


func _on_timer_timeout() -> void:
	_try_spawn_melee_boomerang_copy()
	queue_free()
