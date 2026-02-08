extends CanvasLayer

const font: FontFile = preload("uid://cv3kwiaeereef")
var ui_open := false

func _ready() -> void:
	death_menu.visible = false
	pause_menu.visible = false
		#Деньги
	GameState.coins_changed.connect(_on_coins_changed) 
	_on_coins_changed(GameState.coins) 
	
		#Интвентарь
	stats_panel.visible = false
	inventory_panel.visible = false
	
		# подключения к игроку
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.hp_visual_changed.connect(_on_hp_visual_changed)
		_on_hp_visual_changed(player.build_hp_array())
		
		player.stats_changed.connect(_on_player_stats_changed)
		_on_player_stats_changed(player.move_speed_level,\
			player.luck_level, player.damage_level,\
			player.spread_level, player.range_level, player.hit_points_level,\
			player.fire_rate_level, player.magic_level)
	
	else: print('Худ не нашёл Игрока')
	AchievementManager.achievement_unlocked.connect(_show_new_achievement)


func _process(_delta) -> void:
	if Input.is_action_just_pressed("tab_button"):
		_toggle_full_ui()
	if Input.is_action_just_pressed("Escape"):
		_toggle_pause()
	if Input.is_action_just_pressed("button_L"):
		if pause_menu.visible or death_menu.visible:
			_on_button_main_pressed()


# Здоровье
func _on_hp_visual_changed(hp_array: Array) -> void:
	for child in hearts_row.get_children():
		child.queue_free()
	
	for slot in hp_array:
		var icon := HeartIconScene.instantiate()
		hearts_row.add_child(icon)
		var type := int(slot["type"])
		var side := int(slot["side"])
		_render_heart_icon(icon, type, side)

func _render_heart_icon(icon: Node, type: int, side: int) -> void:
	var sprite: AnimatedSprite2D = icon.get_node("AnimatedSprite2D")
	
	match type:
		1: sprite.animation = "red"
		2: sprite.animation = "green"
		3: sprite.animation = "blue"
		4: sprite.animation = "black"
		0: sprite.animation = "empty"
		_: sprite.animation = "empty"
	
	# side: 0 = левый кадр, 1 = правый
	match side:
		0: sprite.frame = 0
		1: sprite.frame = 1
		#_: sprite.frame = 0


# Применить статы
func _on_player_stats_changed(move_speed_level: float,\
 luck_level: float, damage_level: float, spread_level: float,\
 range_level: float, hit_points_level: float, fire_rate_level: float,\
 magic_level: float) -> void:
	# уровни 1–10 → кадры 0–9
	move_speed_stat.frame	= int(move_speed_level)		- 1
	luck_stat.frame			= int(luck_level)			- 1
	damage_stat.frame		= int(damage_level)			- 1
	spread_stat.frame		= int(spread_level)			- 1
	range_stat.frame		= int(range_level)			- 1
	hit_points_stat.frame	= int(hit_points_level)		- 1
	fire_rate_stat.frame	= int(fire_rate_level)		- 1
	magic_stat.frame		= int(magic_level)			- 1


# Смерть и пауза
func show_death_menu(total_time_alive: float, distance_travelled: float) -> void:
	death_menu.visible = true
	distance_travelled = snappedf(distance_travelled / 100, 0.1)
	total_time_alive = snappedf(total_time_alive, 0.1)
	distance_label.text = "Distance: %.1f m" % distance_travelled

	
	StatsManager.add_statistic_progress("lifetime", total_time_alive)
	StatsManager.add_statistic_progress("distance_traveled", distance_travelled)

func _toggle_pause() -> void:
	var tree := get_tree()
	tree.paused = not tree.paused
	pause_menu.visible = tree.paused


# Предметы инвентарь
const SlotScene: PackedScene = preload("uid://bmr2p245fgr3l")
@onready var items: Array[Dictionary] = []

func add_item(icon: Texture2D, tooltip: String):
	items.insert(0, {"icon": icon, "tooltip": tooltip})
	_render_inventory()

func _render_inventory():
	for child in items_container.get_children():
		child.queue_free()
	for item_data in items:
		var slot = SlotScene.instantiate() as InventorySlot
		slot.set_icon(item_data.icon)
		slot.set_tooltip(item_data.tooltip)
		items_container.add_child(slot)
	



# Отображение подбора монетки
func _on_coins_changed(new_value: int) -> void:
	coins_label.text = str(new_value)
	coins_timer.start()
	coins_icon_active.visible = true
	coins_icon_passive.visible = false
	
func _on_timer_Money_timeout() -> void:
	coins_icon_active.visible = false
	coins_icon_passive.visible = true
	
func _toggle_full_ui() -> void:
	ui_open = not ui_open
	stats_panel.visible = ui_open
	inventory_panel.visible = ui_open
	equip_panel.visible = ui_open
	_on_coins_changed(GameState.coins)
	if ui_open:
		_render_inventory()

# Ачивки
func _show_new_achievement(data: String):
	$HUD/Achivements.show()
	$HUD/Achivements/Sprite2D.texture = load(data)
	$HUD/Achivements/achiv_timer.start()

func _on_achiv_timer_timeout() -> void:
	$HUD/Achivements.hide()


const HeartIconScene: PackedScene = preload("res://game/HUD/HeartIcon.tscn")
@onready var hearts_row: HBoxContainer = $HUD/LeftUpVBoxContainer/HpContainersRow

@onready var inventory_panel: Control = $HUD/InventoryList
@onready var items_container: GridContainer = $HUD/InventoryList/ItemsScroll/ItemsGridContainer
@onready var items_scroll: ScrollContainer = $HUD/InventoryList/ItemsScroll

@onready var equip_panel: Panel = $HUD/EquipPanel


@onready var death_menu: Control = $HUD/DeathMenu
@onready var distance_label: Label = $HUD/DeathMenu/VBoxContainer/DistanceLabel
@onready var pause_menu: Control = $HUD/PauseMenu

@onready var coins_container: GridContainer = $HUD/LeftUpVBoxContainer/CoinsContainer
@onready var coins_label: Label = $HUD/LeftUpVBoxContainer/CoinsContainer/CoinsLabel
@onready var coins_timer = $HUD/LeftUpVBoxContainer/CoinsContainer/MoneyTimer
@onready var coins_icon_active = $HUD/LeftUpVBoxContainer/CoinsContainer/CoinsIcon
@onready var coins_icon_passive = $HUD/LeftUpVBoxContainer/CoinsContainer/CoinsIcon2
@onready var stats_panel: Control = $HUD/StatsPanel

@onready var hit_points_stat: AnimatedSprite2D = $HUD/StatsPanel/Brown_Stat
@onready var luck_stat: AnimatedSprite2D = $HUD/StatsPanel/Green_stat
@onready var range_stat: AnimatedSprite2D = $HUD/StatsPanel/Purple_Stat
@onready var damage_stat: AnimatedSprite2D = $HUD/StatsPanel/Red_Stat
@onready var fire_rate_stat: AnimatedSprite2D = $HUD/StatsPanel/Sea_Stat 
@onready var spread_stat: AnimatedSprite2D = $HUD/StatsPanel/Yellow_Stat
@onready var magic_stat: AnimatedSprite2D = $HUD/StatsPanel/Pink_Stat
@onready var move_speed_stat: AnimatedSprite2D = $HUD/StatsPanel/Blue_Stat

#Временные кнопки
func _on_button_play_pressed() -> void:
	_toggle_pause()

func _on_button_restart_pressed() -> void:
	var tree := get_tree()
	tree.paused = false
	var current_scene := tree.current_scene
	tree.reload_current_scene() 

func _on_button_main_pressed() -> void:
	var tree := get_tree()
	tree.paused = false
	tree.change_scene_to_file("uid://ckbshuddtl78y")
