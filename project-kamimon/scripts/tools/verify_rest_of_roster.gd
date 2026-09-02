extends SceneTree
## Round-trip check for the last 5 monsters, run in a brand-new headless
## process (no stale in-memory objects) against
## PlaceholderBattleData.get_player_party()/get_enemy_party()'s exact
## values. Also checks that every shared move (Tackle, Guard Bash, Bite,
## Snarl, Claw Rake) links via ext_resource -- resource_path pointing at
## the real shared file -- rather than an embedded per-monster copy, and
## that Grimhowl Alpha's move order (bite, claw_rake, snarl) really is
## different from the other two Grimhowls (bite, snarl, claw_rake).
##
## Run headless:
##   Godot_v4.7.1-stable_linux.x86_64 --headless --path project-kamimon \
##     --script res://scripts/tools/verify_rest_of_roster.gd

var _fail_count := 0

func _initialize() -> void:
	_check_monster(
		"res://resources/monsters/zephyrun.tres", "Zephyrun", 75, 12, 6, 20, ["Gale", "", "", ""],
		[
			["Quick Snap", 6, 1.0, [], ""],
			["Tackle", 12, 0.95, [], "res://resources/moves/tackle.tres"],
			["Gale Slice", 14, 0.9, ["Gale"], ""],
		]
	)
	_check_monster(
		"res://resources/monsters/graniteye.tres", "Graniteye", 105, 13, 16, 6, ["Stone", "", "", ""],
		[
			["Stone Fist", 18, 0.8, ["Stone"], ""],
			["Guard Bash", 8, 1.0, [], "res://resources/moves/guard_bash.tres"],
			["Tackle", 12, 0.95, [], "res://resources/moves/tackle.tres"],
		]
	)
	_check_monster(
		"res://resources/monsters/grimhowl.tres", "Grimhowl", 100, 13, 9, 12, ["Frost", "", "", ""],
		[
			["Bite", 14, 0.9, ["Frost"], "res://resources/moves/bite.tres"],
			["Snarl", 9, 1.0, [], "res://resources/moves/snarl.tres"],
			["Claw Rake", 17, 0.8, [], "res://resources/moves/claw_rake.tres"],
		]
	)
	_check_monster(
		"res://resources/monsters/grimhowl_pup.tres", "Grimhowl Pup", 60, 9, 6, 18, ["Frost", "", "", ""],
		[
			["Bite", 14, 0.9, ["Frost"], "res://resources/moves/bite.tres"],
			["Snarl", 9, 1.0, [], "res://resources/moves/snarl.tres"],
			["Claw Rake", 17, 0.8, [], "res://resources/moves/claw_rake.tres"],
		]
	)
	# Deliberately different move order from the other two Grimhowls above.
	_check_monster(
		"res://resources/monsters/grimhowl_alpha.tres", "Grimhowl Alpha", 130, 16, 12, 10, ["Frost", "", "", ""],
		[
			["Bite", 14, 0.9, ["Frost"], "res://resources/moves/bite.tres"],
			["Claw Rake", 17, 0.8, [], "res://resources/moves/claw_rake.tres"],
			["Snarl", 9, 1.0, [], "res://resources/moves/snarl.tres"],
		]
	)

	print("\n%s" % ("ALL CHECKS PASSED" if _fail_count == 0 else "%d CHECK(S) FAILED" % _fail_count))
	quit(0 if _fail_count == 0 else 1)

## expected_moves: array of [name, power, accuracy, domains, expected_shared_path_or_""]
func _check_monster(
	path: String,
	expected_name: String,
	expected_hp: int,
	expected_atk: int,
	expected_def: int,
	expected_spd: int,
	expected_domains: Array,
	expected_moves: Array
) -> void:
	var mon: MonsterData = load(path)
	print("--- %s ---" % path)
	_check("%s display_name" % expected_name, mon.display_name == expected_name)
	_check("%s max_hp" % expected_name, mon.max_hp == expected_hp)
	_check("%s attack" % expected_name, mon.attack == expected_atk)
	_check("%s defense" % expected_name, mon.defense == expected_def)
	_check("%s speed" % expected_name, mon.speed == expected_spd)
	_check("%s domains" % expected_name, mon.domains == expected_domains)
	_check("%s assigned_moves count" % expected_name, mon.assigned_moves.size() == expected_moves.size())

	for i in expected_moves.size():
		var move: MoveData = mon.assigned_moves[i]
		var exp: Array = expected_moves[i]
		var exp_name: String = exp[0]
		var exp_power: int = exp[1]
		var exp_accuracy: float = exp[2]
		var exp_domains: Array = exp[3]
		var exp_shared_path: String = exp[4]

		_check("%s move %d name (%s)" % [expected_name, i, exp_name], move.display_name == exp_name)
		_check("%s move %d power" % [expected_name, i], move.power == exp_power)
		_check("%s move %d accuracy" % [expected_name, i], is_equal_approx(move.accuracy, exp_accuracy))
		_check("%s move %d domains" % [expected_name, i], move.domains == exp_domains)
		if exp_shared_path != "":
			_check(
				"%s move %d (%s) links to shared file, not embedded" % [expected_name, i, exp_name],
				move.resource_path == exp_shared_path
			)

func _check(label: String, condition: bool) -> void:
	if condition:
		print("[PASS] %s" % label)
	else:
		_fail_count += 1
		print("[FAIL] %s" % label)
