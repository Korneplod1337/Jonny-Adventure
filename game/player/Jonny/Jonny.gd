extends CharacterBody2D
class_name Jonny

var ST = StatManager
var player_name = 'Jonny'

@onready var interactcomp = $InteractingComponents/InteractRange/CollisionShape2D
@onready var head_sprite: AnimatedSprite2D = $Head
@onready var chest_sprite: AnimatedSprite2D = $Chest
@onready var boots_sprite: AnimatedSprite2D = $Boots
@onready var body_parts := [
	$AnimatedSprite2D,
	$Chest,
	$Boots ]
@onready var head_parts := [
	$AnimatedShot,
	$Head]

@onready var hp_list := {
	"red": max(0, StatManager.get_stat(self, 'hp')),
	"green": 0,
	"blue": 0,  # magic shield
	"black": 2, # shield
	}

const base_max_hp: 				int  = 3    #6
const base_move_speed:			float = 250.0
const base_luck: 				float = 0.2
const base_magic: 				float = 0.0
const base_damage: 				float = 25.0
const base_spread: 				float = 14.0
const base_range: 				float = 150.0
const base_fire_rate: 			float = 0.5

const ENEMY_COLLISION_BITS := 4 | 64
const BASE_IMMUNE_TIME := 0.3

var hp_bonus: 				int = 0
var speed_bonus: 			int = 0
var luck_bonus: 				int = 0
var magic_bonus: 			int = 0
var damage_bonus: 			int = 1
var accuracy_bonus: 			int = 0
var range_bonus: 			int = 0
var fire_rate_bonus:			int = 0

var crit_chance_bonus: 		float = 0.0
var immune_time_bonus: 		float = 0.0
var pass_through_enemies: 	bool = false
var _base_collision_mask: 	int = 0
var ez_retaliation_count: 	int = 0
var force_shield_max: 		int = 0
var force_shield_charges: 	int = 0

@export_range(1.0, 10.0, 1.0) var hit_points_level: 	float = 1.0
@export_range(1.0, 10.0, 1.0) var move_speed_level: 	float = 2.0
@export_range(1.0, 10.0, 1.0) var luck_level: 		float = 1.0
@export_range(1.0, 10.0, 1.0) var magic_level: 		float = 1.0
@export_range(1.0, 10.0, 1.0) var damage_level: 		float = 1.0
@export_range(1.0, 10.0, 1.0) var spread_level: 		float = 1.0
@export_range(1.0, 10.0, 1.0) var range_level: 		float = 1.0
@export_range(1.0, 10.0, 1.0) var fire_rate_level: 	float = 1.0

@onready var max_hp: 		= int(ST.get_stat(self, "hp"))
@onready var move_speed: float	= ST.get_stat(self, "move_speed")
@onready var luck: float			= ST.get_stat(self, "luck")
@onready var magic: float		= ST.get_stat(self, "magic")
@onready var damage: float		= ST.get_stat(self, "damage")
@onready var spread: float		= ST.get_stat(self, "spread")
@onready var atk_range: float	= ST.get_stat(self, "range")
@onready var fire_rate:float		= ST.get_stat(self, "fire_rate")

var extra_fire_rate:float = 0
var EquipFireRateBoost: float = 1.0
var EquipMoveSpeedFlat: float = 0.0
var boomerang_bonus: int = 0

var head_id: String
var chest_id: String
var boots_id: String
var ability_id: String = ""
var current_ability: BaseAbility = null
var is_dashing: bool = false
@export var start_weapon := true
@export var start_ability := true
const START_WEAPON_EQUIP := preload("uid://bwiytmmsxjtk5")
const START_ABILITY_EQUIP := preload("res://game/objects/Equipment/Ability/equip/Dash_equip.tscn")
const PROJECTILE_COLLISION_BIT := 2

signal stats_changed(move_speed_level, luck_level, damage_level, spread_level,\
 range_level, hit_points_level, fire_rate_level, magic_level)
signal bonuses_changed(hp_bonus, speed_bonus, luck_bonus, magic_bonus,\
 damage_bonus, accuracy_bonus, range_bonus, fire_rate_bonus)
signal hp_visual_changed(hp_array: Array)

var input_vector = Vector2(0, 0)
var now_move_direction := Vector2.ZERO
var last_move_dir := 1

var animated_speed := 1

func _ready() -> void:
	_base_collision_mask = collision_mask
	$AnimatedSprite2D.play()
	_emit_stats_changed()	 # Вызвать это когда меняем стат
	update_equipment_visuals()
	if start_weapon:
		call_deferred("_equip_start_weapon")
	if start_ability:
		call_deferred("_equip_start_ability")

func _equip_start_weapon() -> void:
	var equip: BaseShot_equip = START_WEAPON_EQUIP.instantiate()
	equip.apply_equip(self)

func _equip_start_ability() -> void:
	var equip: BaseAbility_equip = START_ABILITY_EQUIP.instantiate()
	equip.apply_equip(self)
	equip.queue_free()

func _try_use_ability() -> void:
	if current_ability == null:
		return
	current_ability.try_activate()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Ability"):
		_try_use_ability()
	if Input.is_action_just_pressed("button_K"):
		take_damage(1)
	if Input.is_action_just_pressed("button_L"):
		heal(1)
	if Input.is_action_just_pressed("o"):
		ItemManager.spawn("treasure", [0,1,4], self.global_position)
	if Input.is_action_just_pressed("i"):
		ItemManager.spawn("treasure", [4], self.global_position)


@export var on_ice: bool = true
var movement_locked: bool = false

func set_movement_locked(locked: bool) -> void:
	movement_locked = locked
	if locked:
		velocity = Vector2.ZERO

func _process(delta: float) -> void: 
	total_time_alive += delta
	total_distance_travelled += now_move_direction.length() * delta
	#ходьба
	'''
	velocity = Vector2(Input.get_axis('move_left', 'move_right'),
		Input.get_axis('move_up', 'move_down')).normalized() * move_speed
	'''
	
	var ability_moved := false
	if current_ability:
		ability_moved = current_ability.process_movement(delta)

	if not ability_moved:
		var dir := Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		).normalized()
		if movement_locked:
			dir = Vector2.ZERO

		var target := dir * move_speed
		
		if on_ice:
			velocity = velocity.move_toward(target, delta * move_speed)
			if dir == Vector2.ZERO:
				velocity = velocity.move_toward(Vector2.ZERO, delta * move_speed)
		else:
			velocity = dir * move_speed

	move_and_slide()
	now_move_direction = get_real_velocity()
	
# =========================
# BODY ANIMATION
	if velocity.length() < 1:
		if last_move_dir > 0:
			play_body("afk_default")
		else:
			play_body("afk_up")
	else:
		if abs(velocity.x) < abs(velocity.y):
			if velocity.y < 0:
				play_body("walk_up")
			else:
				play_body("walk_down")
			last_move_dir = velocity.y
		else:
			play_body("walk_h")
			flip_body(velocity.x < 0)
# =========================
# HEAD ANIMATION
	shot_direction = Input.get_vector(
		"fire_left",
		"fire_right",
		"fire_up",
		"fire_down"
	)
	shooting = shot_direction != Vector2.ZERO
	# Если стреляем — смотрим туда
	if shooting:
		if abs(shot_direction.x) > abs(shot_direction.y):
			if shot_direction.x < 0:
				play_head("left")
			else:
				play_head("right")
		else:
			if shot_direction.y < 0:
				play_head("up")
			else:
				play_head("down")
	# Если НЕ стреляем — смотрим по движению
	else:
		if velocity.length() < 1:
			if last_move_dir > 0:
				play_head("down")
			else:
				play_head("up")
		else:
			if abs(velocity.x) >= abs(velocity.y):
				if velocity.x < 0:
					play_head("left")
				else:
					play_head("right")
			else:
				if velocity.y < 0:
					play_head("up")
				else:
					play_head("down")
	
	#if (now_move_direction.x < 1 and now_move_direction.x > -1) \
	#and (now_move_direction.y < 1 and now_move_direction.y > -1):
		#$AnimatedSprite2D.animation = "afk_default"
		#if last_move_dir > 0:
			#$AnimatedShot.animation = "down"
		#else:
			#$AnimatedShot.animation = "up"
	#elif velocity.x != 0:
		#$AnimatedSprite2D.animation = "walk_h"
		#$AnimatedShot.animation = "right"
		#$AnimatedSprite2D.flip_h = velocity.x < 0
		#if velocity.x < 0:
			#$AnimatedShot.animation = "left"
	#elif velocity.y != 0:
		#if velocity.y < 0:
			#$AnimatedSprite2D.animation = "walk_up"
			#$AnimatedShot.animation = "up"
		#else:
			#$AnimatedSprite2D.animation = "walk_down"
			#$AnimatedShot.animation = "down"
		#last_move_dir = now_move_direction.y
	
	# Анимации стрельбы
	shot_direction = Input.get_vector("fire_left", "fire_right", "fire_up", "fire_down")
	shooting = shot_direction != Vector2.ZERO
	if shooting:
		var anim_dir = "left" if shot_direction.x < 0 else "right" if shot_direction.x > 0\
		 else "up" if shot_direction.y < 0 else "down"
		play_head(anim_dir)
	
	# Уход на перезарядку
	if can_shoot and shooting and not movement_locked:
		fire(shot_direction)
		start_reload()
		
		animated_speed = GameState.animated_world_speed
		$AnimatedSprite2D.speed_scale = animated_speed
		$Chest.speed_scale = animated_speed
		$Boots.speed_scale = animated_speed

func play_body(anim: String):
	for p in body_parts:
		p.play(anim)
func flip_body(state: bool):
	for p in body_parts:
		p.flip_h = state
func play_head(anim: String):
	for p in head_parts:
		p.play(anim)

func update_equipment_visuals():
	for p in body_parts:
		p.frame = 0
	# HEAD
	if head_id != "":
		head_sprite.sprite_frames = EquipManager.equip_visuals[head_id]
		head_sprite.visible = true
	else:
		head_sprite.visible = false
	# CHEST
	if chest_id != "":
		chest_sprite.sprite_frames = EquipManager.equip_visuals[chest_id]
		chest_sprite.visible = true
	else:
		chest_sprite.visible = false
	# BOOTS
	if boots_id != "":
		boots_sprite.sprite_frames = EquipManager.equip_visuals[boots_id]
		boots_sprite.visible = true
	else:
		boots_sprite.visible = false

# ЗДОРОВЬЕ
func take_damage(phy_damage: int = 0,
				mag_damage: int = 0, clr_damage: int = 0, attacker: Node = null) -> void:
	#return
	if invulnerable or is_dashing:
		return
	
	var incoming := phy_damage + mag_damage + clr_damage
	if incoming <= 0 and attacker == null:
		return
	
	if attacker:
		_retaliate_ez(attacker)
	
	if incoming <= 0:
		return
	
	if force_shield_charges > 0:
		force_shield_charges -= 1
		_start_invulnerability()
		return
	
	if phy_damage:
		var remaining := phy_damage
		for d in ["black", "blue"]:
			if remaining <= 0:
				break
			var used :int = min(remaining, hp_list[d])
			hp_list[d] -= used
			remaining -= used
		
		for t in ["green", "red"]:
			if remaining <= 0:
				break
			var used :int = min(remaining, hp_list[t])
			hp_list[t] -= used
			remaining -= used
		if hp_list["red"] + hp_list["green"] + hp_list["blue"] + hp_list["black"] <= 0: 
			print('die')
			die()
	if mag_damage:
		var remaining := mag_damage
		for t in ["green", "red"]:
			if remaining <= 0:
				break
			var used :int = min(remaining, hp_list[t])
			hp_list[t] -= used
			remaining -= used
		if hp_list["red"] + hp_list["green"] <= 0: 
			print('die')
			die()
	if clr_damage:
		var remaining := clr_damage
		for d in ["blue"]:
			if remaining <= 0:
				break
			var used: int = min(remaining, hp_list[d])
			hp_list[d] -= used
			remaining -= used
		for t in ["red"]:
			if remaining <= 0:
				break
			var used :int = min(remaining, hp_list[t])
			hp_list[t] -= used
			remaining -= used
		if hp_list["red"] <= 0: 
			print('die')
			die()
	

	_start_invulnerability()

func _start_invulnerability() -> void:
	invulnerable = true
	imuneTimer.wait_time = BASE_IMMUNE_TIME + immune_time_bonus
	imuneTimer.start()
	$AnimatedSprite2D.modulate.a = 0.4
	_emit_hp_visual_changed()

func _retaliate_ez(attacker: Node) -> void:
	if ez_retaliation_count <= 0:
		return
	var target: Node = attacker
	if not target.has_method("hit"):
		var owner = target.get("owner_enemy")
		if owner is Node:
			target = owner
	if not target.has_method("hit"):
		return
	for _i in ez_retaliation_count:
		var info := DamageInfo.new()
		info.damage = damage
		info.source = self
		info.hit_position = global_position
		if target is Node2D:
			info.direction = (target.global_position - global_position).normalized()
		DamageDealer.deal_damage(self, target, info)

func recharge_force_shield() -> void:
	for i in range(force_shield_max):
		if randi()%2 <1:
			force_shield_charges +=1


func heal(red: int = 0, green: int = 0, blue: int = 0, black: int = 0) -> void:
	hp_list["blue"] += blue
	hp_list["black"] += black
	
	if red != 0:
		_add_live_hp("red", red)
	if green != 0:
		_add_live_hp("green", green)
	
	_emit_hp_visual_changed()

func _add_live_hp(typ: String, amount: int) -> void:
	var live_total : int = hp_list["red"] + hp_list["green"]
	var free_slots : int = max_hp - live_total
	if free_slots <= 0:
		return
	var add :int = min(amount, free_slots)
	hp_list[typ] += add

func die() -> void:
	var hud := get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.show_death_menu(total_time_alive, total_distance_travelled)
	get_tree().paused = true
	AchievementManager.unlock_achievement('First time')

func _on_immune_timer_timeout() -> void:
	invulnerable = false
	$AnimatedSprite2D.modulate.a = 1
	pass


func _emit_hp_visual_changed() -> void:
	hp_visual_changed.emit(_build_hp_array()) #для худа

func _build_hp_array() -> Array:
	var hp_array: Array = []
	
	var live_types: Array[String] = ["green", "red"]

	for t in live_types:
		var halves_for_type: int = hp_list.get(t, 0)
		if halves_for_type <= 0:
			continue
		
		for i in range(halves_for_type):
			hp_array.append({"type": _heart_type_to_int(t),})
	
	while hp_array.size() < max_hp:
		hp_array.append({ "type": 0 })
	
	for t in ["blue", "black"]:
		for i in range(hp_list.get(t, 0)):
			hp_array.append({"type": _heart_type_to_int(t),})
	
	# 4) Сортировка по типам: 1, 2, 0, 3, 4
	var order := {1: 0, 2: 1, 0: 2, 3: 3, 4: 4}
	hp_array.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var at: int = order.get(a["type"], 999)
			var bt: int = order.get(b["type"], 999)
			return at < bt )
	
	# Теперь одним проходом назначаем side, чередуя 0/1 по всему итоговому массиву
	for i in range(hp_array.size()):
		var h: Dictionary = hp_array[i]
		h["side"] = i % 2 
		hp_array[i] = h
	
	return hp_array

func _heart_type_to_int(t: String) -> int:
	match t:
		"red":   return 1
		"green": return 2
		"blue":  return 3
		"black": return 4
		_:   return 0


# Стрельба
var shot_direction := Vector2(0,0)
var shot_angle: float
var can_shoot: bool = true
var shooting: bool = false
@export var shot_scene: PackedScene
var shot_id: String = ''

var shot_enchantment: EnchantmentResource

func fire (shot_dir: Vector2) -> void:
	if not shot_scene:
		return
		
	var shot = shot_scene.instantiate()
	shot.position = global_position + Vector2(0, -10)
	
	var angle := shot_dir.angle()
	var effective_spread := spread
	if not shot.use_spread:
		effective_spread = maxf(0.0, spread - 56.0)
	if effective_spread > 0.0 and not GameState.Surestrike:
		angle += deg_to_rad(randf_range(-effective_spread / 2, effective_spread / 2))
	var final_dir := Vector2.RIGHT.rotated(angle)
	
	shot.direction = final_dir + now_move_direction.normalized()/3 
	#+ shot_dir.normalized()/3
	
	shot.damage = damage
	
	shot.atk_range = atk_range
	shot.speed = 300 * (1 + (move_speed_level + fire_rate_level - 8)* 0.05)
	shot.atk_range = atk_range
	shot.speed = 300 * (1 + (move_speed_level + fire_rate_level - 8)* 0.05)
	shot.boomerang_power += boomerang_bonus
	
	if shot_enchantment:
		shot.enchantment = shot_enchantment.duplicate(true)
	get_tree().current_scene.add_child(shot)
	
	extra_fire_rate = shot.extra_reload
	var cloak_fx := get_node_or_null("Accelerator_Cloak")
	if cloak_fx and cloak_fx.has_method("update_boost"):
		cloak_fx.update_boost()
	fire_rate = ST.get_stat(self, "fire_rate")

# таймер (лоховской)
func _on_shot_timer_timeout() -> void:
	can_shoot = true
	shooting = false

# Скорострельность
func start_reload():
		can_shoot = false
		$shot_Timer.wait_time = fire_rate
		$shot_Timer.start()
		#print($shot_Timer.wait_time, ' ', fire_rate, ' ', extra_fire_rate)

# Сигнал изменения статов
func _emit_stats_changed() -> void: 
	_emit_hp_visual_changed()
	emit_signal("stats_changed", move_speed_level, luck_level, damage_level,\
	 spread_level, range_level, hit_points_level, fire_rate_level, magic_level)
	_emit_bonuses_changed()

func _emit_bonuses_changed() -> void:
	emit_signal("bonuses_changed", hp_bonus, speed_bonus, luck_bonus, magic_bonus,\
	 damage_bonus, accuracy_bonus, range_bonus, fire_rate_bonus)


func _update_enemy_collision() -> void:
	var mask := _base_collision_mask
	if pass_through_enemies or is_dashing:
		mask = mask & ~ENEMY_COLLISION_BITS
	if is_dashing:
		mask = mask & ~PROJECTILE_COLLISION_BIT
	collision_mask = mask



# камера
func set_room(room_root: Node2D) -> void:
	var bounds_node := room_root.get_node_or_null("CameraBounds")
	if bounds_node == null:
		return
	var rect := _rect_from_bounds(bounds_node)
	_apply_camera_limits(rect)

func _rect_from_bounds(bounds_area: Area2D) -> Rect2:
	var shape_node: CollisionShape2D = bounds_area.get_node("CollisionShape2D")
	var rect_shape := shape_node.shape as RectangleShape2D
	var center := bounds_area.global_position
	var size := rect_shape.size

	return Rect2(center - size * 0.5, size)

func _apply_camera_limits(rect: Rect2) -> void:
	var cam: Camera2D = $Camera2D
	cam.limit_left = 	int(rect.get_center().x - rect.size.x/2)
	cam.limit_top = 		int(rect.get_center().y - rect.size.y/2)
	cam.limit_right = 	int(rect.get_center().x + rect.size.x/2)
	cam.limit_bottom = 	int(rect.get_center().y + rect.size.y/2)
	cam.limit_smoothed = true



# cтаты и ачивки
var total_distance_travelled: float = 0.0
var total_time_alive: float = 0.0

@onready var imuneTimer = $immune_Timer
var invulnerable: bool = false


func update_level_buffs() -> void:
	on_ice = GameState.level_bufs[4][1]


# --- переход между этажами через люк ---
const HATCH_APPROACH_HEIGHT := 80.0
const HATCH_DESCEND_DEPTH := 25.0
const HATCH_APPROACH_TIME := 0.45
const HATCH_DESCEND_TIME := 1.25
const HATCH_ENTER_DROP := 100.0
const HATCH_ENTER_TIME := 1.5
const HATCH_SPIN_TURNS := 2.0

var _saved_collision_mask: int = 0
var _floor_transition_tween: Tween = null


func begin_floor_transition() -> void:
	set_movement_locked(true)
	_saved_collision_mask = collision_mask
	set_collision_mask(0)


func end_floor_transition() -> void:
	if _floor_transition_tween and _floor_transition_tween.is_valid():
		_floor_transition_tween.kill()
	rotation = 0.0
	set_collision_mask(_saved_collision_mask)
	_update_enemy_collision()
	set_movement_locked(false)


func play_hatch_exit(hatch_center: Vector2) -> void:
	begin_floor_transition()
	var above := hatch_center + Vector2(0, -HATCH_APPROACH_HEIGHT)
	var inside := hatch_center + Vector2(0, HATCH_DESCEND_DEPTH)

	if _floor_transition_tween and _floor_transition_tween.is_valid():
		_floor_transition_tween.kill()

	_floor_transition_tween = create_tween()
	_floor_transition_tween.tween_property(
		self, "global_position", above, HATCH_APPROACH_TIME
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _floor_transition_tween.finished

	var spin_from := rotation
	_floor_transition_tween = create_tween()
	_floor_transition_tween.set_parallel(true)
	_floor_transition_tween.tween_property(
		self, "global_position", inside, HATCH_DESCEND_TIME
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_floor_transition_tween.tween_property(
		self, "rotation", spin_from + TAU * HATCH_SPIN_TURNS, HATCH_DESCEND_TIME
	)
	await _floor_transition_tween.finished


func play_hatch_enter(land_pos: Vector2) -> void:
	global_position = land_pos + Vector2(0, -HATCH_ENTER_DROP)
	rotation = 0.0

	var spin_from := rotation
	if _floor_transition_tween and _floor_transition_tween.is_valid():
		_floor_transition_tween.kill()

	_floor_transition_tween = create_tween()
	_floor_transition_tween.set_parallel(true)
	_floor_transition_tween.tween_property(
		self, "global_position", land_pos, HATCH_ENTER_TIME
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_floor_transition_tween.tween_property(
		self, "rotation", spin_from + TAU * HATCH_SPIN_TURNS, HATCH_ENTER_TIME
	)
	await _floor_transition_tween.finished
	end_floor_transition()
