extends SceneTree
## One-off: brings the existing example resources up to the current
## schemas after the assigned_moves/move_pool rename and the MoveEffect
## refactor.
##   - ember_burst.tres: loaded and re-saved with its flat effect_* fields
##     (gone from the script now) replaced by a StatModifierEffect in
##     `effects`, same values as before (10%% chance, -1 Defense, 3 turns).
##   - emberkit.tres: rebuilt from scratch rather than loaded-and-patched --
##     its serialized `moves = [...]` property no longer matches any field
##     MonsterData declares (renamed to `assigned_moves`), and referencing
##     a dropped field by name in code doesn't compile against the current
##     script, so this just reconstructs it with the same values as
##     generate_example_monster.gd used originally, referencing the
##     already-saved move .tres files rather than rebuilding those too.
## Run headless (after a rescan if the new effect classes were just added):
##   Godot_v4.7.1-stable_linux.x86_64 --headless --path project-kamimon \
##     --script res://scripts/tools/migrate_emberkit_examples.gd

func _initialize() -> void:
	var move_path := "res://resources/moves/ember_burst.tres"
	var move: MoveData = load(move_path)
	var effect := StatModifierEffect.new()
	effect.stat = "Defense"
	effect.stages = -1
	effect.chance = 0.1
	effect.duration = 3
	effect.target = "defender"
	move.effects = [effect]
	var move_err := ResourceSaver.save(move, move_path)
	print("Re-saved %s, error code: %s" % [move_path, move_err])

	var mon := MonsterData.new()
	mon.display_name = "Emberkit"
	mon.max_hp = 90
	mon.attack = 14
	mon.defense = 8
	mon.speed = 16
	mon.domains = ["Flame", "", "", ""]
	mon.battler_sprite = load("res://assets/placeholder_My_mon_back_sprite.png")
	mon.assigned_moves = [
		load("res://resources/moves/tackle.tres"),
		load("res://resources/moves/heavy_slam.tres"),
		load(move_path),
	]
	var mon_path := "res://resources/monsters/emberkit.tres"
	var mon_err := ResourceSaver.save(mon, mon_path)
	print("Re-saved %s, error code: %s" % [mon_path, mon_err])

	quit()
