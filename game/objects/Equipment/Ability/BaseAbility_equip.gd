class_name BaseAbility_equip
extends Area2D

var GS = GameState

@onready var interactable: Area2D = $Interactable

@export var ability_script: Script
@export var equip_icon: Texture2D: set = _set_equip_icon
@export var equip_id: String = "ability"
@export var equip_tooltip: String = "ability"
@export var interact_name: String = "ability"

signal equip_taken

var cost: int = 0
var type: String = "ability"

## CD state carried while this pickup lies on the ground.
var _saved_cd: Dictionary = {}


func _ready() -> void:
	interactable.interact = _on_interact
	if cost < 1:
		interactable.interact_name = "Take " + interact_name
	else:
		interactable.interact_name = "Take " + interact_name \
			+ " by %s coins" % ((cost + GS.cost_plus) * GS.cost_multiplier)
	if _has_active_saved_cd():
		_ensure_kill_cd_listener()


func _exit_tree() -> void:
	_disconnect_kill_cd_listener()


func set_saved_cooldown(state: Dictionary) -> void:
	_saved_cd = state.duplicate(true)
	if _has_active_saved_cd():
		_ensure_kill_cd_listener()
	else:
		_disconnect_kill_cd_listener()
		_saved_cd.clear()


func apply_equip(player: Node) -> void:
	if player.current_ability:
		var old_ability: BaseAbility = player.current_ability
		player.current_ability = null
		old_ability.set_process(false)
		old_ability.queue_free()

	var ability: BaseAbility = ability_script.new() as BaseAbility
	ability.name = "CurrentAbility"
	player.add_child(ability)
	player.current_ability = ability
	player.ability_id = equip_id
	ability.setup(player)
	if not _saved_cd.is_empty():
		ability.apply_cooldown_state(_saved_cd)
		_saved_cd.clear()
		_disconnect_kill_cd_listener()

	var hud = player.get_tree().get_first_node_in_group("HUD")
	if hud == null:
		return
	hud.AbilitySlot.set_icon(equip_icon)
	hud.AbilitySlot.set_tooltip(equip_tooltip)
	hud.AbilitySlot.set_cooldown_progress(ability.get_cooldown_ratio())


func _on_interact() -> void:
	var player = get_player()
	if not player:
		print("ability equip не видит игрока")
		return
	if GS.coins < (cost + GS.cost_plus) * GS.cost_multiplier:
		return
	GS.add_coins((-cost - GS.cost_plus) * GS.cost_multiplier)

	var drop_cd := {}
	if player.current_ability:
		drop_cd = player.current_ability.get_cooldown_state()
	if player.ability_id:
		EquipManager.certain_spawn(player.ability_id, global_position, null, drop_cd)

	apply_equip(player)
	equip_taken.emit()
	queue_free()


func effect_off() -> void:
	var player = get_player()
	if player == null:
		return
	if player.current_ability:
		var old_ability: BaseAbility = player.current_ability
		player.current_ability = null
		old_ability.set_process(false)
		old_ability.queue_free()
	player.ability_id = ""
	var hud = null
	if player.is_inside_tree():
		hud = player.get_tree().get_first_node_in_group("HUD")
	if hud and hud.AbilitySlot:
		hud.AbilitySlot.set_icon(null)
		hud.AbilitySlot.set_tooltip("")
		hud.AbilitySlot.set_cooldown_progress(0.0)


func effect_on() -> void:
	pass


func _process(delta: float) -> void:
	if not _has_active_saved_cd():
		return
	if int(_saved_cd.get("cooldown_type", 0)) != BaseAbility.CooldownType.TIME:
		return
	var time_left := float(_saved_cd.get("time_left", 0.0)) - delta
	if time_left <= 0.0:
		_saved_cd.clear()
		_disconnect_kill_cd_listener()
	else:
		_saved_cd["time_left"] = time_left


func _on_stat_changed(stat_name: String, _new_value: float) -> void:
	if stat_name != "kills":
		return
	if not _has_active_saved_cd():
		return
	if int(_saved_cd.get("cooldown_type", 0)) != BaseAbility.CooldownType.KILLS:
		return
	var kills_left := int(_saved_cd.get("kills_left", 0)) - 1
	if kills_left <= 0:
		_saved_cd.clear()
		_disconnect_kill_cd_listener()
	else:
		_saved_cd["kills_left"] = kills_left


func _has_active_saved_cd() -> bool:
	return bool(_saved_cd.get("on_cooldown", false))


func _ensure_kill_cd_listener() -> void:
	if int(_saved_cd.get("cooldown_type", 0)) != BaseAbility.CooldownType.KILLS:
		return
	if not StatsManager.stat_changed.is_connected(_on_stat_changed):
		StatsManager.stat_changed.connect(_on_stat_changed)


func _disconnect_kill_cd_listener() -> void:
	if StatsManager.stat_changed.is_connected(_on_stat_changed):
		StatsManager.stat_changed.disconnect(_on_stat_changed)


func _set_equip_icon(new_icon: Texture2D) -> void:
	equip_icon = new_icon


func get_player() -> Node:
	var tree: SceneTree
	if is_inside_tree():
		tree = get_tree()
	else:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player")
