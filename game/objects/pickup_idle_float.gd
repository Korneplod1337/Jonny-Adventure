class_name PickupIdleFloat
extends RefCounted

## Soft idle bob for world pickups: slow vertical sine motion with rare horizontal sway.

const AMPLITUDE_Y := 2.0
const AMPLITUDE_X := 2.0
## Seconds for one half of the bob (up or down).
const HALF_PERIOD := 2.75
## Chance to also drift sideways on the "out" half; return half always centers X.
const SWAY_CHANCE := 0.28

const _META_VISUAL := &"_pickup_idle_visual"
const _META_BASE := &"_pickup_idle_base"
const _META_TWEEN := &"_pickup_idle_tween"


static func begin(host: Node) -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	var visual := _find_visual(host)
	if visual == null:
		return

	host.set_meta(_META_VISUAL, visual)
	host.set_meta(_META_BASE, visual.position)

	# Desync pickups so they don't bob in lockstep.
	var delay := randf() * HALF_PERIOD
	var tree := host.get_tree()
	if tree == null:
		_cycle(host, -1.0)
		return
	# weakref: иначе после queue_free host → "Lambda capture ... was freed"
	var host_ref: WeakRef = weakref(host)
	tree.create_timer(delay, false, true).timeout.connect(
		func() -> void:
			var h := host_ref.get_ref() as Node
			if h != null:
				_cycle(h, -1.0),
		CONNECT_ONE_SHOT
	)


static func _find_visual(host: Node) -> Node2D:
	var sprite := host.get_node_or_null("Sprite2D")
	if sprite is Node2D:
		return sprite
	var anim := host.get_node_or_null("AnimatedSprite2D")
	if anim is Node2D:
		return anim
	return null


static func _cycle(host: Node, y_dir: float) -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	if not host.has_meta(_META_VISUAL) or not host.has_meta(_META_BASE):
		return

	var visual: Node2D = host.get_meta(_META_VISUAL)
	if not is_instance_valid(visual):
		return

	var base: Vector2 = host.get_meta(_META_BASE)
	var target := Vector2(base.x, base.y + AMPLITUDE_Y * y_dir)

	# Side sway only on the upward half; downward half returns to center X.
	if y_dir < 0.0 and randf() < SWAY_CHANCE:
		target.x = base.x + AMPLITUDE_X * (1.0 if randf() < 0.5 else -1.0)

	if host.has_meta(_META_TWEEN):
		var prev: Tween = host.get_meta(_META_TWEEN)
		if prev and prev.is_valid():
			prev.kill()

	var host_ref: WeakRef = weakref(host)
	var tween := host.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, "position", target, HALF_PERIOD)
	tween.tween_callback(
		func() -> void:
			var h := host_ref.get_ref() as Node
			if h != null:
				_cycle(h, -y_dir)
	)
	host.set_meta(_META_TWEEN, tween)
