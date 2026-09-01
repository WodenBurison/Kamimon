extends SceneTree
func _initialize() -> void:
	var mon: MonsterData = load("res://resources/monsters/emberkit.tres")
	print("assigned_moves.size(): ", mon.assigned_moves.size(), " -> ", mon.assigned_moves.size() == 3)
	print("move_pool.size(): ", mon.move_pool.size(), " -> ", mon.move_pool.size() == 0)
	var ember: MoveData = mon.assigned_moves[2]
	print("3rd move name: ", ember.display_name, " -> ", ember.display_name == "Ember Burst")
	print("effects.size(): ", ember.effects.size(), " -> ", ember.effects.size() == 1)
	var effect: StatModifierEffect = ember.effects[0]
	print("effect stat/stages/chance/duration/target: ", effect.stat, " ", effect.stages, " ", effect.chance, " ", effect.duration, " ", effect.target)
	quit()
