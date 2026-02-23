extends CharacterBody2D
var ST = StatManager

@onready var hp_list := {
	"red": max(0, StatManager.get_stat(self, 'hp')),
	"green": 0,
	"blue": 0,   # щит/овер, НЕ ограничен max_hp
	"black": 2,
	}

const base_max_hp: 				int = 3    #6
const base_move_speed:			float = 300.0
const base_luck: 				float = 0.2
const base_magic: 				float = 0.0
const base_damage: 				float = 25.0
const base_spread: 				float = 14.0
const base_range: 				float = 200.0
const base_fire_rate: 			float = 0.2

var hp_bonus: 		int = 0
var speed_bonus: 	int = 0
var luck_bonus: 		int = 0
var magic_bonus: 	int = 0
var damage_bonus: 	int = 0
var accuracy_bonus: 	int = 0
var range_bonus: 	int = 0
var fire_rate_bonus:	int = 0

@export var hit_points_level: 	float = 1.0
@export var move_speed_level: 	float = 2.0   # 1–10, 9 лвл прокачки
@export var luck_level: 			float = 1.0
@export var magic_level: 		float = 1.0
@export var damage_level: 		float = 1.0
@export var spread_level: 		float = 1.0
@export var range_level: 		float = 1.0
@export var fire_rate_level: 	float = 1.0

@onready var max_hp: 		= int(ST.get_stat(self, "hp"))
@onready var move_speed: float	= ST.get_stat(self, "move_speed")
@onready var luck: float			= ST.get_stat(self, "luck")
@onready var magic: float		= ST.get_stat(self, "magic")
@onready var damage: float		= ST.get_stat(self, "damage")
@onready var spread: float		= ST.get_stat(self, "spread")
@onready var atk_range: float	= ST.get_stat(self, "range")
@onready var fire_rate:float		= ST.get_stat(self, "fire_rate")

var extra_fire_rate:float = 0

signal stats_changed(move_speed_level, luck_level, damage_level, spread_level,\
 range_level, hit_points_level, fire_rate_level, magic_level)
signal hp_visual_changed(hp_array: Array)

var input_vector = Vector2(0, 0)
var now_move_direction := Vector2.ZERO
var last_move_dir := 1


func _ready() -> void:
	$AnimatedSprite2D.play()
	_emit_stats_changed()
	 # Вызвать это когда меняем стат

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("button_K"):
		take_damage(1)
	if Input.is_action_just_pressed("button_L"):
		heal(1)
	#if Input.is_action_just_pressed("o"):
	#	ST.upgrade_stat(self, 'hp', 1)
	if Input.is_action_just_pressed("i"):
		ItemManager.spawn("treasure", [1], self.global_position)


func _process(delta: float) -> void: 
	total_time_alive += delta
	total_distance_travelled += now_move_direction.length() * delta
	
	#ходьба
	velocity = Vector2(Input.get_axis('move_left', 'move_right'),
		Input.get_axis('move_up', 'move_down')).normalized() * move_speed
	move_and_slide()
	now_move_direction = get_real_velocity()
	
	if (now_move_direction.x < 1 and now_move_direction.x > -1) \
	and (now_move_direction.y < 1 and now_move_direction.y > -1):
		$AnimatedSprite2D.animation = "afk_default"
		if last_move_dir > 0:
			$AnimatedShot.animation = "down"
		else:
			$AnimatedShot.animation = "up"
	elif velocity.x != 0:
		$AnimatedSprite2D.animation = "walk_h"
		$AnimatedShot.animation = "right"
		$AnimatedSprite2D.flip_h = velocity.x < 0
		if velocity.x < 0:
			$AnimatedShot.animation = "left"
	elif velocity.y != 0:
		if velocity.y < 0:
			$AnimatedSprite2D.animation = "walk_up"
			$AnimatedShot.animation = "up"
		else:
			$AnimatedSprite2D.animation = "walk_down"
			$AnimatedShot.animation = "down"
		last_move_dir = now_move_direction.y
	
	# Анимации стрельбы
	shot_direction = Input.get_vector("fire_left", "fire_right", "fire_up", "fire_down")
	shooting = shot_direction != Vector2.ZERO
	if shooting:
		var anim_dir = "left" if shot_direction.x < 0 else "right" if shot_direction.x > 0\
		 else "up" if shot_direction.y < 0 else "down"
		$AnimatedShot.play(anim_dir)
	
	# Уход на перезарядку
	if can_shoot and shooting:
		fire(shot_direction)
		start_reload()


# ЗДОРОВЬЕ
func take_damage(phy_damage: int = 0,
				mag_damage: int = 0, clr_damage: int = 0) -> void:
	if invulnerable:
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
			_die()
	
	if mag_damage:
		pass
	if clr_damage:
		pass
	
	invulnerable = true
	imuneTimer.start()
	$AnimatedSprite2D.modulate.a = 0.4
	_emit_hp_visual_changed()

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

func _die() -> void:
	var hud := get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.show_death_menu(total_time_alive, total_distance_travelled)
	get_tree().paused = true

func _on_immune_timer_timeout() -> void:
	invulnerable = false
	$AnimatedSprite2D.modulate.a = 1
	pass


func _emit_hp_visual_changed() -> void:
	hp_visual_changed.emit(build_hp_array()) #для худа

func build_hp_array() -> Array:
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


func fire (shot_dir: Vector2) -> void:
	if not shot_scene:
		return
		
	var shot = shot_scene.instantiate()
	shot.position = global_position + Vector2(0, -25)
	
	var angle := shot_dir.angle()
	angle += deg_to_rad(randf_range(-spread/2, spread/2))
	var final_dir := Vector2.RIGHT.rotated(angle)
	
	shot.direction = final_dir + now_move_direction.normalized()/3 
	#+ shot_dir.normalized()/3
	
	shot.damage = damage
	shot.atk_range = atk_range
	shot.speed = 300 * (1 + (move_speed_level + fire_rate_level - 8)* 0.05)
	
	extra_fire_rate = shot.extra_reload
	get_tree().current_scene.add_child(shot)

# таймер (лоховской)
func _on_shot_timer_timeout() -> void:
	can_shoot = true
	shooting = false

# Скорострельность
func start_reload():
		can_shoot = false
		print($shot_Timer.wait_time, ' ', fire_rate, ' ', extra_fire_rate)
		$shot_Timer.wait_time = fire_rate + extra_fire_rate
		$shot_Timer.start()

# Сигнал изменения статов
func _emit_stats_changed() -> void: 
	_emit_hp_visual_changed()
	emit_signal("stats_changed", move_speed_level, luck_level, damage_level,\
	 spread_level, range_level, hit_points_level, fire_rate_level, magic_level)


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
