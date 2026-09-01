extends SceneTree
func _initialize() -> void:
	var move: MoveData = load("res://resources/moves/ember_burst.tres")
	print("effect_stat=", move.effect_stat, " effect_stages=", move.effect_stages, " effect_chance=", move.effect_chance, " effect_duration=", move.effect_duration, " effect_target=", move.effect_target)
	quit()
