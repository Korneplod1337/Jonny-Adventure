extends StaticBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable: Area2D = $Interactable
var cost := 0
var item_tier :Array = [1] # add check floor
var item_pool := 'treasure'
var equip_tier :Array = [1] #add check floor
var equip_pool := 'armory'
const OPENED_BEFORE_FADE_DELAY := 2.0
const FADE_DURATION := 4.0
const COLLISION_DISABLE_LAST_SECONDS := 1.0
var _despawn_started := false


func _ready() -> void:
	interactable.interact = _on_interact

func _on_interact() -> void: 
	var player = get_tree().get_first_node_in_group('player')
	var luck = StatManager.get_stat(player, 'luck')
	if interactable.is_interactable:
		SoundManager.play_skrip()
		_spawn_loot(Vector2(0, -80))
		if GameState.extra_chest_loot_chance > 0.0 and randf() < GameState.extra_chest_loot_chance:
			_spawn_loot(Vector2(40, -80))
		animated_sprite_2d.frame = 1
		interactable.is_interactable = false
		_start_despawn_sequence()

func _spawn_loot(offset: Vector2) -> void:
	var random = randi_range(1, 100)
	if random >= 75:
		EquipManager.spawn(equip_pool, equip_tier, self.global_position + offset)
	else:
		ItemManager.spawn(item_pool, item_tier, self.global_position + offset, cost)

func _start_despawn_sequence() -> void:
	if _despawn_started:
		return
	_despawn_started = true

	await get_tree().create_timer(OPENED_BEFORE_FADE_DELAY).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property(animated_sprite_2d, "modulate:a", 0.0, FADE_DURATION)

	await get_tree().create_timer(max(FADE_DURATION - COLLISION_DISABLE_LAST_SECONDS, 0.0)).timeout
	_disable_collision()
	await get_tree().create_timer(min(COLLISION_DISABLE_LAST_SECONDS, FADE_DURATION)).timeout
	queue_free()

func _disable_collision() -> void:
	collision_layer = 0
	collision_mask = 0
	interactable.monitoring = false
	interactable.monitorable = false
