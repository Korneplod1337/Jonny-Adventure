extends "res://game/presets/RoomScript.gd"
## Секретный банковский vault. Лут зависит от bank_loyalty.

const CHEST_SMALL := preload("res://game/objects/Chests/Chest_small.tscn")
const CHEST_BIG := preload("res://game/objects/Chests/Chest_big.tscn")
const COIN := preload("res://game/objects/Coins/Coin.tscn")
const SPIDER_SMALL := preload("res://game/enemy/1-st floor basement/Spider_small.tscn")
const SPIDER_BIG := preload("res://game/enemy/1-st floor basement/Spider_big.tscn")
const WEAK_SKULL := preload("res://game/enemy/2-st floor pyramid/weak_skull.tscn")

@onready var content_spawn: Marker2D = $ContentSpawn
@onready var coin_spawn_left: Marker2D = $CoinSpawnLeft
@onready var coin_spawn_right: Marker2D = $CoinSpawnRight


func init_room() -> void:
	super.init_room()
	_spawn_loyalty_content()


func shuffle_doors() -> void:
	## Vault doors are fixed (exit right only); never shuffle.
	pass



func _loyalty() -> float:
	var data: Dictionary = StatsManager.get_stat_display("bank_loyalty")
	return float(data.get("value", 0))


func _spawn_at(scene: PackedScene, pos: Vector2) -> Node:
	var inst = scene.instantiate()
	inst.position = pos
	add_child(inst)
	return inst


func _rand_spawn(scene: PackedScene, chance_max: int, base: Vector2, jitter: float = 40.0) -> void:
	## chance_max inclusive: 0..chance_max means 0 or 1 when chance_max=1
	if randi() % (chance_max + 1) == 0:
		return
	var offset := Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
	_spawn_at(scene, base + offset)


func _spawn_loyalty_content() -> void:
	var loy := _loyalty()
	var base := content_spawn.position if content_spawn else Vector2.ZERO

	if loy < 40.0:
		_rand_spawn(SPIDER_SMALL, 1, base + Vector2(-60, 0))
		_rand_spawn(WEAK_SKULL, 1, base + Vector2(60, 0))
		_rand_spawn(SPIDER_BIG, 1, base + Vector2(0, 50))
	elif loy < 80.0:
		_spawn_at(CHEST_SMALL, base)
		_rand_spawn(SPIDER_SMALL, 1, base + Vector2(-80, 40))
		_rand_spawn(WEAK_SKULL, 1, base + Vector2(80, 40))
	else:
		_spawn_at(CHEST_BIG, base)
		var left := coin_spawn_left.position if coin_spawn_left else base + Vector2(-70, 0)
		var right := coin_spawn_right.position if coin_spawn_right else base + Vector2(70, 0)
		_spawn_at(COIN, left)
		_spawn_at(COIN, right)
