extends EnemySpider
class_name EnemySpiderEggSmall

const WAVE2_ENEMY_SCENE := preload("res://game/enemy/1-st floor basement/Spider_small.tscn")

var _releasing_wave2 := false
var _spawn_pos := Vector2.ZERO
var _spawn_scale := Vector2.ONE


func _ready() -> void:
	add_to_group("EnemyWave2Spawn")
	deals_melee_damage = false
	super._ready()
	active = false
	$FieldViewArea.set_deferred("monitoring", false)
	$FieldViewArea.set_deferred("monitorable", false)
	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _apply_level_buffs() -> void:
	base_hp = _scale_hp(hard_base_hp, 0, 0)
	_apply_spider_angle_deviation()


func _custom_physics(_delta: float) -> void:
	velocity = Vector2.ZERO


func _on_field_view_area_body_entered(_body: Node2D) -> void:
	pass

func _on_field_view_area_body_exited(_body: Node2D) -> void:
	pass

func _on_blind_timer_timeout() -> void:
	pass

func die() -> void:
	if is_dead or _releasing_wave2:
		return
	is_dead = true
	_spawn_pos = global_position
	_spawn_scale = scale
	_disable_collisions()

	var room := _get_room()
	if room:
		if room.has_method("mark_wave2_spawn_death"):
			room.mark_wave2_spawn_death()
		if room.has_method("reserve_enemy_slot"):
			room.reserve_enemy_slot()

	_enemy_die.emit(1)
	_start_wave2_release()


func _disable_collisions() -> void:
	velocity = Vector2.ZERO
	$CollisionShape2D.call_deferred("set_disabled", true)
	$FieldViewArea.hide()
	cooldown_timer.stop()
	blind_timer.stop()
	poison_timer.stop()


func _get_room() -> Node:
	var node: Node = self
	while node:
		if node.has_method("spawn_wave2_enemy"):
			return node
		node = node.get_parent()
	return null


func _start_wave2_release() -> void:
	_releasing_wave2 = true
	sprite.play("default")


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "default" and _releasing_wave2:
		_finish_wave2_release()
		return
	super._on_sprite_animation_finished()


func _finish_wave2_release() -> void:
	if not _releasing_wave2:
		return
	_releasing_wave2 = false

	var room := _get_room()
	if room:
		room.spawn_wave2_enemy(WAVE2_ENEMY_SCENE, _spawn_pos, _spawn_scale)
	else:
		var parent := get_parent()
		if parent:
			var enemy := WAVE2_ENEMY_SCENE.instantiate()
			parent.add_child(enemy)
			enemy.global_position = _spawn_pos
			enemy.scale = _spawn_scale

	StatsManager.add_statistic_progress("kills", 1)
	queue_free()
