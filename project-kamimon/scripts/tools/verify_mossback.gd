extends SceneTree
## Round-trip check: loads mossback.tres fresh (this is a brand-new headless
## process, so there's no stale in-memory object -- a real test that the
## file on disk matches PlaceholderBattleData's in-code Mossback exactly,
## same discipline as the Emberkit example.
##
## Run headless:
##   Godot_v4.7.1-stable_linux.x86_64 --headless --path project-kamimon \
##     --script res://scripts/tools/verify_mossback.gd

var _fail_count := 0

func _initialize() -> void:
	var mon: MonsterData = load("res://resources/monsters/mossback.tres")

	_check("display_name", mon.display_name == "Mossback")
	_check("max_hp", mon.max_hp == 120)
	_check("attack", mon.attack == 10)
	_check("defense", mon.defense == 14)
	_check("speed", mon.speed == 8)
	_check("domains", mon.domains == ["Verdant", "", "", ""])
	_check("assigned_moves count", mon.assigned_moves.size() == 3)

	var guard_bash: MoveData = mon.assigned_moves[0]
	_check("move 0 name", guard_bash.display_name == "Guard Bash")
	_check("move 0 power", guard_bash.power == 8)
	_check("move 0 accuracy", guard_bash.accuracy == 1.0)
	_check("move 0 domains", guard_bash.domains == [])

	var tackle: MoveData = mon.assigned_moves[1]
	_check("move 1 name", tackle.display_name == "Tackle")
	_check("move 1 power", tackle.power == 12)
	_check("move 1 accuracy", is_equal_approx(tackle.accuracy, 0.95))
	_check("move 1 resource_path is the shared file (ext_resource, not embedded)", tackle.resource_path == "res://resources/moves/tackle.tres")

	var root_bind: MoveData = mon.assigned_moves[2]
	_check("move 2 name", root_bind.display_name == "Root Bind")
	_check("move 2 power", root_bind.power == 10)
	_check("move 2 accuracy", is_equal_approx(root_bind.accuracy, 0.9))
	_check("move 2 domains", root_bind.domains == ["Verdant"])

	print("\n%s" % ("ALL CHECKS PASSED" if _fail_count == 0 else "%d CHECK(S) FAILED" % _fail_count))
	quit(0 if _fail_count == 0 else 1)

func _check(label: String, condition: bool) -> void:
	if condition:
		print("[PASS] %s" % label)
	else:
		_fail_count += 1
		print("[FAIL] %s" % label)
