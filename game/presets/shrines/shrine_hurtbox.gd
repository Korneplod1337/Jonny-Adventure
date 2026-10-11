extends StaticBody2D

## Пробрасывает попадания оружия в родительский шрайн.
func hit(amount: float, clear := false) -> void:
	var shrine := get_parent()
	if shrine != null and shrine.has_method("hit"):
		shrine.hit(amount, clear)
