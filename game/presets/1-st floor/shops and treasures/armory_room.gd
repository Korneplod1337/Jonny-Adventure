extends "res://game/presets/RoomScript.gd"


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var loyality = StatsManager.get_stat_display("armory_loyalty")["value"]

func _ready() -> void:
	print('armory loyality = ', loyality)
	tabels_spawn()
	call_deferred("init_room")
	animated_sprite_2d.animation_finished.connect(_on_sprite_animation_finished)

func tabels_spawn():
	var TableScene = preload("uid://pk82t1kne84x")
	
	var table1 = TableScene.instantiate()
	table1.position = self.position + Vector2(100, 0)
	table1.cost = 3
	table1.tier = [1] as Array
	table1.room = 'armory'
	table1.pool = 'armory'
	get_tree().current_scene.add_child(table1)
	
	if loyality > 10:
		var table2 = TableScene.instantiate()
		table2.position = self.position + Vector2(200, 0)
		table2.cost = 10
		table2.tier = [1] as Array
		table2.room = 'armory'
		table2.pool = 'armory'
		get_tree().current_scene.add_child(table2)
	
	if loyality > 20:
		var table3 = TableScene.instantiate()
		table3.position = self.position + Vector2(300, 0)
		table3.cost = 15
		table3.tier = [1] as Array
		table3.room = 'armory'
		table3.pool = 'armory'
		get_tree().current_scene.add_child(table3)
	
	if loyality > 40:
		var table4 = TableScene.instantiate()
		table4.position = self.position + Vector2(400, 0)
		table4.cost = 25
		table4.tier = [1] as Array
		table4.room = 'armory'
		table4.pool = 'armory'
		get_tree().current_scene.add_child(table4)
	
	if loyality > 80:
		var table5 = TableScene.instantiate()
		table5.position = self.position + Vector2(500, 0)
		table5.cost = 5
		table5.tier = [1] as Array
		table5.room = 'armory'
		table5.pool = 'armory'
		get_tree().current_scene.add_child(table5)

var enteredFlag = true
func bounds_body_entered(body: Node2D) -> void:
	if enteredFlag and body.is_in_group('player'):
		print(body, 'entered in armory= ', enteredFlag)
		animated_sprite_2d.animation = 'default'
		animated_sprite_2d.play()
		StatsManager.add_statistic_progress('visited_shops', 1)
		enteredFlag = false
		for child in get_parent().get_children():
			_connect_item_signals(child)

func _connect_item_signals(node):
	if node.has_signal("equip_taken"):
		node.equip_taken.connect(_equip_taken_anim)

func _equip_taken_anim():
	animated_sprite_2d.play('buy')

func _on_sprite_animation_finished()-> void:
	animated_sprite_2d.play('default')
