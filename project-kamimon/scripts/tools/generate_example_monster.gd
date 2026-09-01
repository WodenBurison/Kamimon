extends SceneTree
## One-time resource-generation script: writes real MonsterData/MoveData
## .tres files so they show up in the editor Inspector, instead of being
## built in GDScript (see PlaceholderBattleData._make_monster/_make_move).
##
## Run headless:
##   Godot_v4.7.1-stable_linux.x86_64 --headless --path project-kamimon \
##     --script res://scripts/tools/generate_example_monster.gd
##
## This is the EXAMPLE pass — just Emberkit and its 3 moves, matching
## PlaceholderBattleData's current values exactly, to demonstrate the
## pattern before converting the rest of the roster. Not wired into
## PlaceholderBattleData yet, so nothing about the running battle changes
## until that gets rewired deliberately (a separate step, see
## project-context.md's Implementation principle section).
##
## Tackle is shared: PlaceholderBattleData also uses it for Mossback and
## Graniteye, so this is the one to look at for how a shared move resource
## behaves once other monsters get converted too (Heavy Slam and Ember
## Burst are Emberkit-only for now).

const MOVES_DIR := "res://resources/moves"
const MONSTERS_DIR := "res://resources/monsters"

func _initialize() -> void:
	var tackle := _save_move("Tackle", 12, 0.95, [], "%s/tackle.tres" % MOVES_DIR)
	var heavy_slam := _save_move("Heavy Slam", 20, 0.75, [], "%s/heavy_slam.tres" % MOVES_DIR)
	var ember_burst := _save_move("Ember Burst", 16, 0.85, ["Flame"], "%s/ember_burst.tres" % MOVES_DIR)

	var emberkit := MonsterData.new()
	emberkit.display_name = "Emberkit"
	emberkit.max_hp = 90
	emberkit.attack = 14
	emberkit.defense = 8
	emberkit.speed = 16
	emberkit.domains = ["Flame", "", "", ""]
	emberkit.battler_sprite = load("res://assets/placeholder_My_mon_back_sprite.png")
	emberkit.moves = [tackle, heavy_slam, ember_burst]
	# level, equipped_gear, accuracy, evasion, crit_stat all stay at
	# MonsterData's class defaults deliberately - same reasoning
	# PlaceholderBattleData already documents (keeps this example neutral,
	# doesn't touch current battle balance).

	var err := ResourceSaver.save(emberkit, "%s/emberkit.tres" % MONSTERS_DIR)
	print("Saved emberkit.tres, error code: ", err)

	quit()

func _save_move(move_name: String, power: int, accuracy: float, domains: Array[String], path: String) -> MoveData:
	var move := MoveData.new()
	move.display_name = move_name
	move.power = power
	move.accuracy = accuracy
	move.domains = domains
	var err := ResourceSaver.save(move, path)
	print("Saved %s, error code: %s" % [path, err])
	# Reload from disk rather than returning the in-memory object: saving a
	# resource does not reliably re-associate its own resource_path in the
	# same running process, so a monster referencing this in-memory `move`
	# gets it re-serialized as an embedded [sub_resource] copy instead of a
	# proper [ext_resource] link. Loading it back by path pulls it through
	# Godot's resource cache with resource_path genuinely set, so anything
	# that references *that* copy links out to this file instead of
	# duplicating it - this is what makes "edit Tackle once, every monster
	# using it updates" actually work.
	return load(path)
