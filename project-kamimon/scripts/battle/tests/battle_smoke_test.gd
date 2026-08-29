extends SceneTree
## Headless smoke test for the battle prototype. Run with:
##   Godot_v4.7.1-stable_linux.x86_64 --headless --path project-kamimon \
##     --script res://scripts/battle/tests/battle_smoke_test.gd
##
## Drives BattleScene.tscn through its real signal wiring (button.pressed.emit()
## on the actual Button nodes, not private-method calls) wherever the check is
## about UI wiring, and pokes Combatant/BattleManager state directly wherever
## the check is about game logic (damage math, downed exclusion, win/loss).
##
## Caveat: emitting a Button's `pressed` signal directly bypasses its
## `disabled` flag (that only blocks real input events, not a scripted
## .emit()) — fine for the checks here since none target a disabled button,
## but worth knowing if this file grows.
##
## Exit code 0 = all checks passed, 1 = at least one failed.

var _fail_count := 0
var _pass_count := 0

func _initialize() -> void:
	_run_tests()

func _run_tests() -> void:
	await process_frame

	await _test_scene_loads_and_menu_opens()
	await _test_attack_hits_and_advances_turn()
	await _test_assigned_move_hits()
	await _test_downed_excluded_from_targets()
	_test_guard_halves_damage()
	await _test_win_detection()
	await _test_run_flees()

	print("\n=== %d passed, %d failed ===" % [_pass_count, _fail_count])
	quit(0 if _fail_count == 0 else 1)

func _check(label: String, condition: bool) -> void:
	if condition:
		_pass_count += 1
		print("[PASS] %s" % label)
	else:
		_fail_count += 1
		print("[FAIL] %s" % label)

func _load_battle() -> Node2D:
	var scene: PackedScene = load("res://scenes/battle/BattleScene.tscn")
	var battle: Node2D = scene.instantiate()
	root.add_child(battle)
	return battle

func _new_combatant(mon_name: String, hp: int, atk: int, def: int, spd: int) -> Combatant:
	var data := MonsterData.new()
	data.display_name = mon_name
	data.max_hp = hp
	data.attack = atk
	data.defense = def
	data.speed = spd
	return Combatant.new(data)

## ---------------------------------------------------------------------

func _test_scene_loads_and_menu_opens() -> void:
	var battle := _load_battle()
	await process_frame

	_check("player party has 4 monsters", battle.player_party.size() == 4)
	_check("enemy party has 3 monsters", battle.enemy_party.size() == 3)
	_check("battle starts in TICKING", battle.state == battle.State.TICKING)

	var actor: Combatant = battle.player_party[0]
	battle._start_turn(actor)
	_check("forcing a turn enters PLAYER_INPUT", battle.state == battle.State.PLAYER_INPUT)
	_check("action menu is visible", battle.action_menu.visible)
	_check("root menu is showing", battle.action_menu.root_menu_scroll.visible)

	var moves := actor.data.moves
	_check("move1 label matches assigned move", battle.action_menu.move1_button.text == moves[0].display_name)
	_check("move2 label matches assigned move", battle.action_menu.move2_button.text == moves[1].display_name)
	_check("move3 label matches assigned move", battle.action_menu.move3_button.text == moves[2].display_name)
	_check("move1 is not disabled", not battle.action_menu.move1_button.disabled)

	battle.action_menu.battle_button.pressed.emit()
	_check("Battle press shows the battle menu", battle.action_menu.battle_menu_scroll.visible)
	_check("Battle press hides the root menu", not battle.action_menu.root_menu_scroll.visible)

	battle.queue_free()
	await process_frame

func _test_attack_hits_and_advances_turn() -> void:
	var battle := _load_battle()
	await process_frame

	var actor: Combatant = battle.player_party[0]
	battle._start_turn(actor)
	battle.action_menu.battle_button.pressed.emit()
	battle.action_menu.attack_button.pressed.emit()

	var living_count := 3
	_check(
		"Attack with 3 living enemies opens the target picker",
		battle.action_menu.target_menu_scroll.visible
	)
	_check(
		"target menu lists 3 targets + Back",
		battle.action_menu.target_menu.get_child_count() == living_count + 1
	)

	var target: Combatant = battle.enemy_party[0]
	var hp_before := target.current_hp
	_confirm_target_index(battle, 0)

	_check("basic Attack (guaranteed accuracy) dealt damage", target.current_hp < hp_before)
	_check("state returns to TICKING after a resolved action", battle.state == battle.State.TICKING)
	_check("action menu hides after the turn resolves", not battle.action_menu.visible)

	battle.queue_free()
	await process_frame

func _test_assigned_move_hits() -> void:
	var battle := _load_battle()
	await process_frame

	# Mossback's first assigned move is Guard Bash, accuracy 1.0 — guaranteed
	# hit, same reasoning as the basic-Attack test above.
	var actor: Combatant = battle.player_party[1]
	battle._start_turn(actor)
	battle.action_menu.battle_button.pressed.emit()
	battle.action_menu.move1_button.pressed.emit()

	var target: Combatant = battle.enemy_party[1]
	var hp_before := target.current_hp
	_confirm_target_index(battle, 1)

	_check("assigned move (100%% accuracy) dealt damage", target.current_hp < hp_before)
	_check("state returns to TICKING after an assigned move", battle.state == battle.State.TICKING)

	battle.queue_free()
	await process_frame

func _test_downed_excluded_from_targets() -> void:
	var battle := _load_battle()
	await process_frame

	battle.enemy_party[2].apply_damage(9999)
	_check("forced damage downs the target enemy", battle.enemy_party[2].is_downed())

	var actor: Combatant = battle.player_party[2]
	battle._start_turn(actor)
	battle.action_menu.battle_button.pressed.emit()
	battle.action_menu.attack_button.pressed.emit()

	_check(
		"target menu excludes the downed enemy (2 living + Back)",
		battle.action_menu.target_menu.get_child_count() == 3
	)
	var downed_name: String = battle.enemy_party[2].data.display_name
	var found_downed := false
	for child in battle.action_menu.target_menu.get_children():
		if child is Button and (child as Button).text.begins_with(downed_name):
			found_downed = true
	_check("downed enemy's name does not appear in the target list", not found_downed)

	# Resolve the turn so we don't leave state stuck for anything after this.
	_confirm_target_index(battle, 0)
	_check("state returns to TICKING after resolving around a downed enemy", battle.state == battle.State.TICKING)

	battle.queue_free()
	await process_frame

func _test_guard_halves_damage() -> void:
	var attacker := _new_combatant("TestAttacker", 100, 20, 5, 10)
	var move := MoveData.new()
	move.display_name = "TestStrike"
	move.power = 20
	move.accuracy = 1.0  # guaranteed hit, isolates the guard effect from miss RNG

	# A throwaway BattleManager instance just to call _resolve_attack on —
	# it needs hud/message_label/etc. wired, so load the real scene rather
	# than constructing BattleManager standalone.
	var battle := _load_battle()
	await process_frame

	var defender_plain := _new_combatant("PlainDefender", 200, 10, 5, 10)
	var defender_guarded := _new_combatant("GuardedDefender", 200, 10, 5, 10)
	defender_guarded.guard()

	seed(1234)
	battle._resolve_attack(attacker, defender_plain, move)
	var plain_damage := 200 - defender_plain.current_hp

	seed(1234)
	battle._resolve_attack(attacker, defender_guarded, move)
	var guarded_damage := 200 - defender_guarded.current_hp

	_check("guarding reduced damage taken (%d vs %d)" % [guarded_damage, plain_damage], guarded_damage < plain_damage)
	_check(
		"guarded damage is roughly half of unguarded (within rounding)",
		guarded_damage <= int(ceil(plain_damage / 2.0)) + 1
	)

	battle.queue_free()

func _test_win_detection() -> void:
	var battle := _load_battle()
	await process_frame

	# GDScript lambdas capture local variables by value at creation time, not
	# by reference — `func(): won = true` would silently mutate a copy and
	# leave this scope's `won` at its original value. Use a 1-element Array
	# as the mutable box instead; the array reference itself is what's
	# captured, so writes to its contents are visible here.
	var won := [false]
	battle.battle_won.connect(func(): won[0] = true)

	for c in battle.enemy_party:
		c.apply_damage(9999)

	var result: bool = battle._check_battle_over()
	_check("_check_battle_over reports true once the enemy party is downed", result)
	_check("state becomes BATTLE_OVER on a win", battle.state == battle.State.BATTLE_OVER)
	_check("battle_won signal fired", won[0])

	battle.queue_free()
	await process_frame

func _test_run_flees() -> void:
	var battle := _load_battle()
	await process_frame

	var fled := [false]  # see the mutable-box note in _test_win_detection
	battle.battle_fled.connect(func(): fled[0] = true)

	var actor: Combatant = battle.player_party[0]
	battle._start_turn(actor)
	battle.action_menu.run_button.pressed.emit()

	_check("battle_fled signal fired on Run", fled[0])
	_check("state becomes BATTLE_OVER after fleeing", battle.state == battle.State.BATTLE_OVER)

	battle.queue_free()
	await process_frame

## ---------------------------------------------------------------------

## Presses whichever target-menu button is at the given living-target index
## (skips the Back button, which _build_target_menu always keeps last).
func _confirm_target_index(battle: Node2D, index: int) -> void:
	var buttons: Array = []
	for child in battle.action_menu.target_menu.get_children():
		if child != battle.action_menu.target_back_button:
			buttons.append(child)
	(buttons[index] as Button).pressed.emit()
