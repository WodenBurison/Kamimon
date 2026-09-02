extends SceneTree
## One-off: converts Mossback and its two new moves (Guard Bash, Root Bind)
## to .tres resources, matching PlaceholderBattleData.get_player_party()'s
## in-code Mossback exactly. Tackle is NOT recreated here -- it already
## exists at resources/moves/tackle.tres from the Emberkit pass and is
## loaded from disk directly, proving the "link to an existing shared move
## file" path (Emberkit's three moves were all new, so it never exercised
## this). Guard Bash and Root Bind are new: each gets saved once, then
## reloaded by path before being handed to Mossback, per the
## ResourceSaver.save() resource_path gotcha documented in
## project-context.md (saving and reusing the same in-memory object embeds
## a private copy instead of linking out via ext_resource).
##
## Run headless:
##   Godot_v4.7.1-stable_linux.x86_64 --headless --path project-kamimon \
##     --script res://scripts/tools/generate_mossback.gd

const MOVES_DIR := "res://resources/moves"
const MONSTERS_DIR := "res://resources/monsters"

func _initialize() -> void:
	var guard_bash := _save_move("Guard Bash", 8, 1.0, [], "%s/guard_bash.tres" % MOVES_DIR)
	var root_bind := _save_move("Root Bind", 10, 0.9, ["Verdant"], "%s/root_bind.tres" % MOVES_DIR)
	var tackle: MoveData = load("%s/tackle.tres" % MOVES_DIR)

	var mossback := MonsterData.new()
	mossback.display_name = "Mossback"
	mossback.max_hp = 120
	mossback.attack = 10
	mossback.defense = 14
	mossback.speed = 8
	mossback.domains = ["Verdant", "", "", ""]
	mossback.battler_sprite = load("res://assets/placeholder_My_mon_back_sprite.png")
	mossback.assigned_moves = [guard_bash, tackle, root_bind]

	var err := ResourceSaver.save(mossback, "%s/mossback.tres" % MONSTERS_DIR)
	print("Saved mossback.tres, error code: ", err)

	quit()

func _save_move(move_name: String, power: int, accuracy: float, domains: Array[String], path: String) -> MoveData:
	var move := MoveData.new()
	move.display_name = move_name
	move.power = power
	move.accuracy = accuracy
	move.domains = domains
	var err := ResourceSaver.save(move, path)
	print("Saved %s, error code: %s" % [path, err])
	return load(path)
