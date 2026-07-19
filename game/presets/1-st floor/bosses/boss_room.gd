extends "res://game/presets/RoomScript_enemy.gd"

const ChestScene := preload("uid://tsiccout8ibv")
const CoinBagScene := preload("res://game/objects/coins/CoinBag.tscn")
const LightningScene := preload("res://game/objects/obstacles/lightning.tscn")
const TIERS_EQUIP := [[0, 1], [0, 1, 2], [0, 1, 2], [0, 1, 2, 3], [0, 2, 3], [2, 3], [2, 3]]
const TIERS_ITEM := [[0, 1], [0, 1, 2, 4], [0, 1, 2, 4], [0, 1, 2, 3, 4], [0, 2, 3, 4], [2, 3], [2, 3]]

const INTRO_ZOOM_IN := 2.0
const INTRO_HOLD := 2.0
const INTRO_ZOOM_OUT := 1.0
const INTRO_ZOOM_MULT := 1.2
const HAZARD_SPAWN_MARGIN := 80.0

var _reward_spawned := false
var _intro_played := false
var _intro_running := false
var _hazard_timer: Timer = null
var _hazard_kind: String = ""
@onready var _hatch: Node2D = $Hatch


func init_room() -> void:
	super()
	spawn_clear_reward = false
	if _hatch and _hatch.has_method("hide_hatch"):
		_hatch.hide_hatch()
	_apply_boss_complication()
	_set_boss_combat_enabled(false)


func show_doors() -> void:
	_stop_boss_hazards()
	super()
	_show_hatch_and_reward()


func _show_hatch_and_reward() -> void:
	if _hatch and _hatch.has_method("show_hatch"):
		_hatch.show_hatch()
	if _reward_spawned:
		return
	_reward_spawned = true
	spawn_reward_chest()


func spawn_reward_chest() -> void:
	if GameState.has_level_buf("Barren"):
		return

	var positions: Array[Vector2] = _get_chest_spawn_positions()
	if GameState.has_level_buf("Midas"):
		for pos in positions:
			var bag = CoinBagScene.instantiate()
			bag.position = pos
			call_deferred("add_child", bag)
		return

	var dungeon = get_tree().current_scene
	var floor_index := clampi(int(dungeon.current_floor) / 2, 0, TIERS_ITEM.size() - 1)
	for pos in positions:
		var chest = ChestScene.instantiate()
		chest.position = pos
		chest.item_tier = TIERS_ITEM[floor_index]
		chest.equip_tier = TIERS_EQUIP[floor_index]
		call_deferred("add_child", chest)


func _get_chest_spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var point1 := get_node_or_null("ChestSpawnPoint") as Node2D
	var point2 := get_node_or_null("ChestSpawnPoint2") as Node2D

	if GameState.is_red_boss_buf():
		if point1:
			positions.append(point1.position)
		if point2:
			positions.append(point2.position)
	elif point1:
		positions.append(point1.position)

	if positions.is_empty():
		if _hatch:
			positions.append(_hatch.position + Vector2(-140, 0))
		else:
			positions.append(Vector2.ZERO)
	return positions


func _find_boss() -> Boss:
	for child in get_children():
		if child is Boss:
			return child
	return null


func _find_bosses() -> Array[Boss]:
	var bosses: Array[Boss] = []
	for child in get_children():
		if child is Boss:
			bosses.append(child)
	return bosses


func _apply_boss_complication() -> void:
	var boss := _find_boss()
	if boss == null:
		return

	var buf_name: String = GameState.get_boss_bufs()[0]
	match buf_name:
		"Dreadnought":
			boss.Boss_HP_buff *= 2.0
		"Twins":
			pass
		"Reaper":
			boss.Boss_damage_buff *= 2.0
		"Vengeful":
			pass
		"Tempest":
			pass
		"Turtleshell":
			boss.Boss_HP_buff *= 1.5
			boss.Boss_move_speed_buff *= 0.8
		"Dwarf":
			boss.Boss_model_size_buff *= 0.75
			boss.Boss_move_speed_buff *= 1.25
		"Siamese":
			boss.Boss_HP_buff *= 0.5
		"Frenetic":
			boss.Boss_damage_buff *= 0.5
			boss.Boss_move_speed_buff *= 1.2
			boss.Boss_phase_switch_buff -= 0.4
		"Thunderer":
			pass
		"Emaciated":
			boss.Boss_HP_buff *= 0.8
		"Inhibited":
			boss.Boss_phase_switch_buff += 0.25
		"Slothful":
			boss.Boss_move_speed_buff *= 0.85

	_refresh_boss_stats(boss)

	if buf_name == "Twins" or buf_name == "Siamese":
		var clone := _spawn_boss_pair(boss, buf_name == "Siamese")
		if clone and buf_name == "Siamese":
			clone.setup_as_siamese_follower(boss)

	if buf_name == "Vengeful":
		for b in _find_bosses():
			b.vengeful_enabled = true

	if buf_name == "Tempest" or buf_name == "Thunderer":
		_hazard_kind = buf_name


func _refresh_boss_stats(boss: Boss) -> void:
	boss._apply_level_buffs()
	boss.base_move_speed = boss.move_speed
	boss.current_hp = boss.base_hp
	boss.cooldown_timer.wait_time = boss.cooldown_time


func _spawn_boss_pair(original: Boss, _siamese: bool) -> Boss:
	const PAIR_OFFSET := 50.0
	var scene_path := original.scene_file_path
	if scene_path.is_empty():
		push_warning("BossRoom: cannot clone boss without scene_file_path")
		return null

	var origin_pos := original.position
	original.position = origin_pos + Vector2(-PAIR_OFFSET, 0)

	var clone: Boss = load(scene_path).instantiate()
	clone.Boss_HP_buff = original.Boss_HP_buff
	clone.Boss_damage_buff = original.Boss_damage_buff
	clone.Boss_move_speed_buff = original.Boss_move_speed_buff
	clone.Boss_model_size_buff = original.Boss_model_size_buff
	clone.Boss_phase_switch_buff = original.Boss_phase_switch_buff
	add_child(clone)
	clone.position = origin_pos + Vector2(PAIR_OFFSET, 0)

	original.add_collision_exception_with(clone)
	clone.add_collision_exception_with(original)
	connect_single_enemy(clone, true)
	return clone


func _set_boss_combat_enabled(enabled: bool) -> void:
	for boss in _find_bosses():
		var field := boss.get_node_or_null("FieldViewArea") as Area2D
		if field:
			field.monitoring = enabled

		if not enabled:
			boss.active = false
			boss.player_in_vision = false
			boss.blind_timer.stop()
			boss.cooldown_timer.stop()
			boss.velocity = Vector2.ZERO
			continue

		if field == null:
			continue
		for body in field.get_overlapping_bodies():
			if body.is_in_group("player"):
				boss._on_field_view_area_body_entered(body)
				break

	if enabled:
		_start_boss_hazards()
	else:
		_stop_boss_hazards()


func _has_living_boss() -> bool:
	for boss in _find_bosses():
		if is_instance_valid(boss) and not boss.is_dead:
			return true
	return false


func _start_boss_hazards() -> void:
	if _hazard_kind.is_empty() or _hazard_timer != null:
		return

	var interval := 1.0
	match _hazard_kind:
		"Tempest":
			interval = 2.0
		"Thunderer":
			interval = 6.0
		_:
			return

	_hazard_timer = Timer.new()
	_hazard_timer.wait_time = interval
	_hazard_timer.one_shot = false
	_hazard_timer.timeout.connect(_on_hazard_timer_timeout)
	add_child(_hazard_timer)
	_hazard_timer.start()
	_on_hazard_timer_timeout()


func _stop_boss_hazards() -> void:
	if _hazard_timer != null:
		_hazard_timer.stop()
		_hazard_timer.queue_free()
		_hazard_timer = null


func _on_hazard_timer_timeout() -> void:
	if not _has_living_boss():
		_stop_boss_hazards()
		return
	_spawn_hazard_lightning()


func _spawn_hazard_lightning() -> void:
	var bolt := LightningScene.instantiate()
	match _hazard_kind:
		"Tempest":
			bolt.spawn_fire = true
			bolt.prepare_time = 2.0
			bolt.active_duration = 0.5
		"Thunderer":
			bolt.spawn_fire = false
			bolt.mag_damage = 2
			bolt.prepare_time = 6.0
			bolt.active_duration = 1.5
			bolt.size_scale = 8.0
		_:
			bolt.queue_free()
			return

	bolt.position = to_local(_random_hazard_global_position())
	add_child(bolt)


func _random_hazard_global_position() -> Vector2:
	var bounds := get_node_or_null("CameraBounds") as Area2D
	if bounds == null:
		return global_position

	var shape_node := bounds.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var rect := shape_node.shape as RectangleShape2D if shape_node else null
	if rect == null:
		return bounds.global_position

	var half := rect.size * 0.5
	var margin := HAZARD_SPAWN_MARGIN
	var local := Vector2(
		randf_range(-half.x + margin, half.x - margin),
		randf_range(-half.y + margin, half.y - margin)
	)
	return bounds.to_global(local)


func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _intro_played or _intro_running:
		return
	_play_boss_intro(body)


func _on_player_detection_area_body_exited(_body: Node2D) -> void:
	pass


func _get_boss_focus_point(boss: Node2D) -> Vector2:
	var bosses := _find_bosses()
	if bosses.size() > 1:
		var sum := Vector2.ZERO
		for b in bosses:
			var sprite := b.get_node_or_null("AnimatedSprite2D") as Node2D
			sum += sprite.global_position if sprite else b.global_position
		return sum / float(bosses.size())

	var sprite := boss.get_node_or_null("AnimatedSprite2D") as Node2D
	if sprite:
		return sprite.global_position
	return boss.global_position


func _clamp_camera_center(cam: Camera2D, desired: Vector2, zoom: Vector2) -> Vector2:
	var screen := cam.get_viewport_rect().size
	var half := Vector2(screen.x / zoom.x, screen.y / zoom.y) * 0.5
	var min_x := float(cam.limit_left) + half.x
	var max_x := float(cam.limit_right) - half.x
	var min_y := float(cam.limit_top) + half.y
	var max_y := float(cam.limit_bottom) - half.y
	if min_x > max_x:
		desired.x = (min_x + max_x) * 0.5
	else:
		desired.x = clampf(desired.x, min_x, max_x)
	if min_y > max_y:
		desired.y = (min_y + max_y) * 0.5
	else:
		desired.y = clampf(desired.y, min_y, max_y)
	return desired


func _tween_camera_look(cam: Camera2D, from_center: Vector2, to_center: Vector2, from_zoom: Vector2, to_zoom: Vector2, duration: float) -> void:
	var tween := create_tween()
	var step := func(t: float) -> void:
		var z: Vector2 = from_zoom.lerp(to_zoom, t)
		var desired: Vector2 = from_center.lerp(to_center, t)
		cam.zoom = z
		cam.global_position = _clamp_camera_center(cam, desired, z)
	tween.tween_method(step, 0.0, 1.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _play_boss_intro(player: Node2D) -> void:
	_intro_running = true
	_intro_played = true

	var boss := _find_boss()
	if boss == null:
		_intro_running = false
		return

	var cam: Camera2D = player.get_node_or_null("Camera2D")
	var dungeon = get_tree().current_scene
	var hud = dungeon.hud_instance if dungeon else null

	if player.has_method("set_movement_locked"):
		player.set_movement_locked(true)
	if hud and hud.has_method("set_ui_locked"):
		hud.set_ui_locked(true)

	_set_boss_combat_enabled(false)

	var buf := GameState.get_boss_bufs()
	var intro_text := boss.BossName
	var intro_color := Color.WHITE
	if buf[0] != "Nothing":
		intro_text = "%s %s" % [buf[0], boss.BossName]
		intro_color = buf[1]
	if hud and hud.has_method("show_boss_effect"):
		hud.show_boss_effect(intro_text, intro_color)

	if cam == null:
		await get_tree().create_timer(INTRO_ZOOM_IN + INTRO_HOLD).timeout
		if hud and hud.has_method("hide_boss_effect"):
			hud.hide_boss_effect()
		await get_tree().create_timer(INTRO_ZOOM_OUT).timeout
		_finish_boss_intro(player, hud)
		return

	var orig_zoom := cam.zoom
	var orig_offset := cam.offset
	var orig_position := cam.position
	var orig_limit_smoothed := cam.limit_smoothed
	var target_zoom := orig_zoom * INTRO_ZOOM_MULT
	var start_center := cam.get_screen_center_position()
	var boss_center := _clamp_camera_center(cam, _get_boss_focus_point(boss), target_zoom)

	cam.limit_smoothed = false
	cam.top_level = true
	cam.global_position = start_center
	cam.offset = Vector2.ZERO

	await _tween_camera_look(cam, start_center, boss_center, orig_zoom, target_zoom, INTRO_ZOOM_IN)
	await get_tree().create_timer(INTRO_HOLD).timeout

	if hud and hud.has_method("hide_boss_effect"):
		hud.hide_boss_effect()

	var return_center := _clamp_camera_center(cam, player.global_position + orig_offset, orig_zoom)
	await _tween_camera_look(cam, cam.global_position, return_center, cam.zoom, orig_zoom, INTRO_ZOOM_OUT)

	cam.top_level = false
	cam.position = orig_position
	cam.offset = orig_offset
	cam.zoom = orig_zoom
	cam.limit_smoothed = orig_limit_smoothed
	_finish_boss_intro(player, hud)


func _finish_boss_intro(player: Node2D, hud: Node) -> void:
	_set_boss_combat_enabled(true)
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)
	if hud and hud.has_method("set_ui_locked"):
		hud.set_ui_locked(false)
	_intro_running = false
