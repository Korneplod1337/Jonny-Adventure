extends RigidBody2D

## Пробрасывает попадания оружия в родительский shootable_wall.
func hit(amount: float, clear := false) -> void:
	var wall := get_parent()
	if wall != null and wall.has_method("hit"):
		wall.hit(amount, clear)
