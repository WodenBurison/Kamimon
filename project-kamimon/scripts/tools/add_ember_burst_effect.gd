extends SceneTree
## One-off: adds a demonstration secondary effect to the existing
## resources/moves/ember_burst.tres (10%% chance to lower the target's
## Defense by one stage for 3 turns) so Woden can see the new MoveData
## effect_* fields on a real, already-in-use resource. Loads the existing
## file rather than rebuilding it from scratch, so nothing else about it
## changes. Run headless:
##   Godot_v4.7.1-stable_linux.x86_64 --headless --path project-kamimon \
##     --script res://scripts/tools/add_ember_burst_effect.gd

func _initialize() -> void:
	var path := "res://resources/moves/ember_burst.tres"
	var move: MoveData = load(path)
	move.effect_stat = "Defense"
	move.effect_stages = -1
	move.effect_chance = 0.1
	move.effect_duration = 3
	move.effect_target = "defender"
	var err := ResourceSaver.save(move, path)
	print("Re-saved %s, error code: %s" % [path, err])
	quit()
