extends SceneTree
## One-off: converts the last 5 placeholder monsters (Zephyrun, Graniteye,
## Grimhowl, Grimhowl Pup, Grimhowl Alpha) and their remaining new moves to
## .tres resources, matching PlaceholderBattleData.get_player_party()/
## get_enemy_party() exactly. Reuses already-saved shared moves (Tackle,
## Guard Bash) by loading them from disk rather than recreating them --
## same reload-after-save discipline as generate_mossback.gd for the moves
## that ARE new here (Quick Snap, Gale Slice, Stone Fist, Bite, Snarl,
## Claw Rake), several of which are themselves shared across the three
## Grimhowls.
##
## Grimhowl Alpha's move order is deliberately different from the other two
## Grimhowls in PlaceholderBattleData (bite, claw_rake, snarl instead of
## bite, snarl, claw_rake) -- preserved here exactly, not normalized.
##
## Run headless:
##   Godot_v4.7.1-stable_linux.x86_64 --headless --path project-kamimon \
##     --script res://scripts/tools/generate_rest_of_roster.gd

const MOVES_DIR := "res://resources/moves"
const MONSTERS_DIR := "res://resources/monsters"
const PLAYER_SPRITE := "res://assets/placeholder_My_mon_back_sprite.png"
const ENEMY_SPRITE := "res://assets/placeholder_enemy_mon.png"

func _initialize() -> void:
	# New moves for the player-party monsters.
	var quick_snap := _save_move("Quick Snap", 6, 1.0, [], "%s/quick_snap.tres" % MOVES_DIR)
	var gale_slice := _save_move("Gale Slice", 14, 0.9, ["Gale"], "%s/gale_slice.tres" % MOVES_DIR)
	var stone_fist := _save_move("Stone Fist", 18, 0.8, ["Stone"], "%s/stone_fist.tres" % MOVES_DIR)

	# New moves for the enemy Grimhowl pack.
	var bite := _save_move("Bite", 14, 0.9, ["Frost"], "%s/bite.tres" % MOVES_DIR)
	var snarl := _save_move("Snarl", 9, 1.0, [], "%s/snarl.tres" % MOVES_DIR)
	var claw_rake := _save_move("Claw Rake", 17, 0.8, [], "%s/claw_rake.tres" % MOVES_DIR)

	# Already-saved shared moves, loaded from disk (not recreated).
	var tackle: MoveData = load("%s/tackle.tres" % MOVES_DIR)
	var guard_bash: MoveData = load("%s/guard_bash.tres" % MOVES_DIR)

	var zephyrun := _save_monster(
		"Zephyrun", 75, 12, 6, 20, "Gale", PLAYER_SPRITE,
		[quick_snap, tackle, gale_slice],
		"%s/zephyrun.tres" % MONSTERS_DIR
	)
	var graniteye := _save_monster(
		"Graniteye", 105, 13, 16, 6, "Stone", PLAYER_SPRITE,
		[stone_fist, guard_bash, tackle],
		"%s/graniteye.tres" % MONSTERS_DIR
	)
	var grimhowl := _save_monster(
		"Grimhowl", 100, 13, 9, 12, "Frost", ENEMY_SPRITE,
		[bite, snarl, claw_rake],
		"%s/grimhowl.tres" % MONSTERS_DIR
	)
	var grimhowl_pup := _save_monster(
		"Grimhowl Pup", 60, 9, 6, 18, "Frost", ENEMY_SPRITE,
		[bite, snarl, claw_rake],
		"%s/grimhowl_pup.tres" % MONSTERS_DIR
	)
	# NOTE: order is bite, claw_rake, snarl here -- matches
	# PlaceholderBattleData's Grimhowl Alpha exactly, NOT the same order as
	# the other two Grimhowls above.
	var grimhowl_alpha := _save_monster(
		"Grimhowl Alpha", 130, 16, 12, 10, "Frost", ENEMY_SPRITE,
		[bite, claw_rake, snarl],
		"%s/grimhowl_alpha.tres" % MONSTERS_DIR
	)

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

func _save_monster(
	monster_name: String,
	hp: int,
	atk: int,
	def: int,
	spd: int,
	primary_domain: String,
	sprite_path: String,
	moves: Array[MoveData],
	path: String
) -> MonsterData:
	var monster := MonsterData.new()
	monster.display_name = monster_name
	monster.max_hp = hp
	monster.attack = atk
	monster.defense = def
	monster.speed = spd
	monster.domains = [primary_domain, "", "", ""]
	monster.battler_sprite = load(sprite_path)
	monster.assigned_moves = moves
	var err := ResourceSaver.save(monster, path)
	print("Saved %s, error code: %s" % [path, err])
	return load(path)
