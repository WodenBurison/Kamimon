extends SceneTree
## Headless smoke test for the battle prototype. Run with:
##   Godot_v4.7.1-stable_linux.x86_64 --headless --path project-kamimon \
##     --script res://scripts/battle/tests/battle_smoke_test.gd
##
## Drives BattleScene.tscn through its real signal wiring (button.pressed.emit()
## on the actual Button nodes, not private-method calls) wherever the check is
## about UI wiring, and pokes Combatant/BattleManager state directly wherever
## the check is about game logic (damage math, downed exclusion, win/loss,
## Domain effectiveness).
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

	await _test000100_scene_loads_and_menu_opens()
	await _test000200_attack_hits_and_advances_turn()
	await _test000300_assigned_move_hits()
	await _test000400_downed_excluded_from_targets()
	_test000500_guard_halves_damage()
	_test000600_domain_effectiveness()
	await _test002100_win_detection()
	await _test002200_run_flees()
	await _test000700_level_gap_affects_damage()
	await _test000800_gear_affects_damage()
	await _test000900_evasion_reduces_hit_chance()
	await _test001000_crit_stat_raises_crit_chance()
	await _test001100_crit_can_multiply_damage()
	await _test001200_stat_modifier_changes_effective_stat_and_damage()
	await _test001300_move_effect_applies_stat_modifier_to_defender()
	_test002000_stat_modifier_expires_after_duration()
	await _test001400_multi_hit_effect_deals_multiple_hits()
	await _test001500_resolve_multi_target_attack_hits_all_living_targets()
	await _test001600_multi_target_move_skips_picker_and_hits_all_enemies()
	await _test001700_enemy_ai_uses_multi_target_move_on_all_players()
	_test001800_placeholder_battle_data_returns_independent_instances()
	_test001900_effective_speed_has_diminishing_returns()

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

func _test000100_scene_loads_and_menu_opens() -> void:
	var battle := _load_battle()
	await process_frame

	_check("000100a: player party has 4 monsters", battle.player_party.size() == 4)
	_check("000100b: enemy party has 3 monsters", battle.enemy_party.size() == 3)
	_check("000100c: battle starts in TICKING", battle.state == battle.State.TICKING)

	var actor: Combatant = battle.player_party[0]
	battle._start_turn(actor)
	_check("000100d: forcing a turn enters PLAYER_INPUT", battle.state == battle.State.PLAYER_INPUT)
	_check("000100e: action menu is visible", battle.action_menu.visible)
	_check("000100f: root menu is showing", battle.action_menu.root_menu_scroll.visible)

	var moves := actor.data.assigned_moves
	_check("000100g: move1 label matches assigned move", battle.action_menu.move1_button.text == moves[0].display_name)
	_check("000100h: move2 label matches assigned move", battle.action_menu.move2_button.text == moves[1].display_name)
	_check("000100i: move3 label matches assigned move", battle.action_menu.move3_button.text == moves[2].display_name)
	_check("000100j: move1 is not disabled", not battle.action_menu.move1_button.disabled)

	battle.action_menu.battle_button.pressed.emit()
	_check("000100k: Battle press shows the battle menu", battle.action_menu.battle_menu_scroll.visible)
	_check("000100l: Battle press hides the root menu", not battle.action_menu.root_menu_scroll.visible)

	battle.queue_free()
	await process_frame

func _test000200_attack_hits_and_advances_turn() -> void:
	var battle := _load_battle()
	await process_frame

	var actor: Combatant = battle.player_party[0]
	battle._start_turn(actor)
	battle.action_menu.battle_button.pressed.emit()
	battle.action_menu.attack_button.pressed.emit()

	var living_count := 3
	_check(
		"000200a: Attack with 3 living enemies opens the target picker",
		battle.action_menu.target_menu_scroll.visible
	)
	_check(
		"000200b: target menu lists 3 targets + Back",
		battle.action_menu.target_menu.get_child_count() == living_count + 1
	)

	var target: Combatant = battle.enemy_party[0]
	var hp_before := target.current_hp
	_confirm_target_index(battle, 0)

	_check("000200c: basic Attack (guaranteed accuracy) dealt damage", target.current_hp < hp_before)
	_check("000200d: state returns to TICKING after a resolved action", battle.state == battle.State.TICKING)
	_check("000200e: action menu hides after the turn resolves", not battle.action_menu.visible)

	battle.queue_free()
	await process_frame

func _test000300_assigned_move_hits() -> void:
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

	_check("000300a: assigned move (100%% accuracy) dealt damage", target.current_hp < hp_before)
	_check("000300b: state returns to TICKING after an assigned move", battle.state == battle.State.TICKING)

	battle.queue_free()
	await process_frame

func _test000400_downed_excluded_from_targets() -> void:
	var battle := _load_battle()
	await process_frame

	battle.enemy_party[2].apply_damage(9999)
	_check("000400a: forced damage downs the target enemy", battle.enemy_party[2].is_downed())

	var actor: Combatant = battle.player_party[2]
	battle._start_turn(actor)
	battle.action_menu.battle_button.pressed.emit()
	battle.action_menu.attack_button.pressed.emit()

	_check(
		"000400b: target menu excludes the downed enemy (2 living + Back)",
		battle.action_menu.target_menu.get_child_count() == 3
	)
	var downed_name: String = battle.enemy_party[2].data.display_name
	var found_downed := false
	for child in battle.action_menu.target_menu.get_children():
		if child is Button and (child as Button).text.begins_with(downed_name):
			found_downed = true
	_check("000400c: downed enemy's name does not appear in the target list", not found_downed)

	# Resolve the turn so we don't leave state stuck for anything after this.
	_confirm_target_index(battle, 0)
	_check("000400d: state returns to TICKING after resolving around a downed enemy", battle.state == battle.State.TICKING)

	battle.queue_free()
	await process_frame

func _test000500_guard_halves_damage() -> void:
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

	_check("000500a: guarding reduced damage taken (%d vs %d)" % [guarded_damage, plain_damage], guarded_damage < plain_damage)
	_check(
		"000500b: guarded damage is roughly half of unguarded (within rounding)",
		guarded_damage <= int(ceil(plain_damage / 2.0)) + 1
	)

	battle.queue_free()

## Verifies DomainChart is actually plugged into _resolve_attack, using the
## real locked graph: Tide beats Flame (super-effective), Flame beats
## Verdant (so a Verdant-domain move into a Flame-domain defender is
## not-very-effective).
func _test000600_domain_effectiveness() -> void:
	var attacker := _new_combatant("TestAttacker", 100, 20, 5, 10)
	# No domains set on the attacker deliberately — isolates this test to
	# weakness/resistance (defender-side) only, no stab in the mix.

	var move_neutral := MoveData.new()
	move_neutral.display_name = "NeutralStrike"
	move_neutral.power = 20
	move_neutral.accuracy = 1.0
	move_neutral.domains = []

	var move_super := MoveData.new()
	move_super.display_name = "TideStrike"
	move_super.power = 20
	move_super.accuracy = 1.0
	move_super.domains = ["Tide"]

	var move_weak := MoveData.new()
	move_weak.display_name = "VerdantStrike"
	move_weak.power = 20
	move_weak.accuracy = 1.0
	move_weak.domains = ["Verdant"]

	var battle := _load_battle()
	await process_frame

	var defender_neutral := _new_combatant("FlameDefenderA", 300, 10, 5, 10)
	defender_neutral.data.domains = ["Flame", "", "", ""]
	var defender_super := _new_combatant("FlameDefenderB", 300, 10, 5, 10)
	defender_super.data.domains = ["Flame", "", "", ""]
	var defender_weak := _new_combatant("FlameDefenderC", 300, 10, 5, 10)
	defender_weak.data.domains = ["Flame", "", "", ""]

	seed(99)
	battle._resolve_attack(attacker, defender_neutral, move_neutral)
	var neutral_damage := 300 - defender_neutral.current_hp

	seed(99)
	battle._resolve_attack(attacker, defender_super, move_super)
	var super_damage := 300 - defender_super.current_hp

	seed(99)
	battle._resolve_attack(attacker, defender_weak, move_weak)
	var weak_damage := 300 - defender_weak.current_hp

	_check(
		"000600a: Tide move vs Flame defender is super-effective (%d > %d neutral)" % [super_damage, neutral_damage],
		super_damage > neutral_damage
	)
	_check(
		"000600b: Verdant move vs Flame defender is not-very-effective (%d < %d neutral)" % [weak_damage, neutral_damage],
		weak_damage < neutral_damage
	)

	battle.queue_free()

## New 2026-08-31: verifies levelFactor is actually wired into
## _resolve_attack now that MonsterData carries a real level field — same
## power/stats/domains on both sides, only level differs, so any damage
## difference has to come from the level-gap term.
func _test000700_level_gap_affects_damage() -> void:
	var battle := _load_battle()
	await process_frame

	var move := MoveData.new()
	move.display_name = "TestStrike"
	move.power = 20
	move.accuracy = 1.0

	var low_attacker := _new_combatant("LowLevelAttacker", 100, 20, 10, 10)
	low_attacker.data.level = 5
	var high_attacker := _new_combatant("HighLevelAttacker", 100, 20, 10, 10)
	high_attacker.data.level = 20

	var defender_a := _new_combatant("DefenderA", 300, 10, 10, 10)
	defender_a.data.level = 10
	var defender_b := _new_combatant("DefenderB", 300, 10, 10, 10)
	defender_b.data.level = 10

	seed(42)
	battle._resolve_attack(low_attacker, defender_a, move)
	var low_level_damage := 300 - defender_a.current_hp

	seed(42)
	battle._resolve_attack(high_attacker, defender_b, move)
	var high_level_damage := 300 - defender_b.current_hp

	_check(
		"000700: higher attacker level deals more damage at equal stats (%d > %d)" % [high_level_damage, low_level_damage],
		high_level_damage > low_level_damage
	)

	battle.queue_free()
	await process_frame

## New 2026-08-31: verifies the equipment skeleton's equip_power()/
## gearFactor plumbing actually affects damage, using the 3-slot array
## directly (no real gear items exist yet, see MonsterData.equipped_gear).
func _test000800_gear_affects_damage() -> void:
	var battle := _load_battle()
	await process_frame

	var move := MoveData.new()
	move.display_name = "TestStrike"
	move.power = 20
	move.accuracy = 1.0

	var geared_attacker := _new_combatant("GearedAttacker", 100, 20, 10, 10)
	geared_attacker.data.equipped_gear = [5.0, 5.0, 5.0]
	var plain_attacker := _new_combatant("PlainAttacker", 100, 20, 10, 10)

	var defender_a := _new_combatant("DefenderA", 300, 10, 10, 10)
	var defender_b := _new_combatant("DefenderB", 300, 10, 10, 10)

	seed(7)
	battle._resolve_attack(geared_attacker, defender_a, move)
	var geared_damage := 300 - defender_a.current_hp

	seed(7)
	battle._resolve_attack(plain_attacker, defender_b, move)
	var plain_damage := 300 - defender_b.current_hp

	_check(
		"000800: equipped gear deals more damage than none, equal stats (%d > %d)" % [geared_damage, plain_damage],
		geared_damage > plain_damage
	)

	battle.queue_free()
	await process_frame

## New 2026-08-31: verifies BattleManager._compute_hit_chance actually
## reads Accuracy/Evasion (background stats, see MonsterData doc comment) —
## a defender with much higher Evasion than the attacker's Accuracy should
## get a lower hit chance than an equal-evasion defender, but never below
## the MIN_HIT_CHANCE floor. Tests the pure formula directly (like
## _compute_damage) rather than over many random trials, since the formula
## itself is deterministic.
func _test000900_evasion_reduces_hit_chance() -> void:
	var battle := _load_battle()
	await process_frame

	var move := MoveData.new()
	move.display_name = "TestStrike"
	move.accuracy = 0.9

	var attacker := _new_combatant("Attacker", 100, 20, 10, 10)
	var low_evasion_defender := _new_combatant("LowEva", 100, 10, 10, 10)
	var high_evasion_defender := _new_combatant("HighEva", 100, 10, 10, 10)
	high_evasion_defender.data.evasion = 40.0

	var low_eva_chance: float = battle._compute_hit_chance(attacker, low_evasion_defender, move)
	var high_eva_chance: float = battle._compute_hit_chance(attacker, high_evasion_defender, move)

	_check(
		"000900a: higher defender evasion lowers hit chance (%.3f < %.3f)" % [high_eva_chance, low_eva_chance],
		high_eva_chance < low_eva_chance
	)
	_check("000900b: hit chance never drops below the MIN_HIT_CHANCE floor", high_eva_chance >= battle.MIN_HIT_CHANCE)

	battle.queue_free()
	await process_frame

## New 2026-08-31: verifies BattleManager._compute_crit_chance actually
## reads the attacker's Crit stat, and that a default-stat monster (equal to
## CRIT_STAT_REFERENCE) lands exactly on BASE_CRIT_CHANCE — i.e. this is a
## true no-op for every existing test that doesn't set crit_stat.
func _test001000_crit_stat_raises_crit_chance() -> void:
	var battle := _load_battle()
	await process_frame

	var default_attacker := _new_combatant("DefaultCrit", 100, 20, 10, 10)
	var high_crit_attacker := _new_combatant("HighCrit", 100, 20, 10, 10)
	high_crit_attacker.data.crit_stat = 40.0

	var default_chance: float = battle._compute_crit_chance(default_attacker)
	var high_chance: float = battle._compute_crit_chance(high_crit_attacker)

	_check(
		"001000a: default crit stat matches the flat baseline exactly (%.4f == %.4f)" % [default_chance, battle.BASE_CRIT_CHANCE],
		is_equal_approx(default_chance, battle.BASE_CRIT_CHANCE)
	)
	_check(
		"001000b: higher crit stat raises crit chance (%.3f > %.3f)" % [high_chance, default_chance],
		high_chance > default_chance
	)
	_check("001000c: crit chance never exceeds the hard clamp", high_chance <= battle.MAX_CRIT_CHANCE)

	battle.queue_free()
	await process_frame

## New 2026-08-31: integration check that a landed crit actually multiplies
## real damage through _resolve_attack (not just that the chance formula
## moves, per the test above). A crit-stat-maxed attacker's chance is well
## under 100%%, so this checks across 40 independently seeded trials rather
## than asserting on one — with the constants above that's a well under
## 1-in-a-million chance of a false failure, while still being a real
## end-to-end check through the same code path battles use.
func _test001100_crit_can_multiply_damage() -> void:
	var battle := _load_battle()
	await process_frame

	var move := MoveData.new()
	move.display_name = "TestStrike"
	move.power = 20
	move.accuracy = 1.0

	var attacker := _new_combatant("CritAttacker", 100, 20, 10, 10)
	attacker.data.crit_stat = 1000.0

	var probe_defender := _new_combatant("Probe", 500, 10, 10, 10)
	var base_result: Dictionary = battle._compute_damage(attacker, probe_defender, move)
	# Anything above base x the top of the 0.9-1.1 variance band had to come
	# from the crit multiplier, not ordinary variance.
	var non_crit_ceiling: int = int(base_result.damage * 1.1)

	var saw_crit := false
	for i in range(40):
		var trial_defender := _new_combatant("Trial%d" % i, 500, 10, 10, 10)
		seed(i)
		battle._resolve_attack(attacker, trial_defender, move)
		var dealt := 500 - trial_defender.current_hp
		if dealt > non_crit_ceiling:
			saw_crit = true
			break

	_check("001100: a high crit-stat attacker lands at least one crit over 40 seeded trials", saw_crit)

	battle.queue_free()
	await process_frame

## New 2026-09-01: verifies Combatant.apply_stat_modifier actually lowers
## effective_defense() and that the lowered value flows through into
## _compute_damage - a debuffed defender should take more damage than an
## unmodified one at otherwise-identical stats. Pure/deterministic, no RNG
## involved (unlike the move-effect trigger tests below).
func _test001200_stat_modifier_changes_effective_stat_and_damage() -> void:
	var battle := _load_battle()
	await process_frame

	var move := MoveData.new()
	move.display_name = "TestStrike"
	move.power = 20

	var attacker := _new_combatant("Attacker", 100, 20, 10, 10)
	var plain_defender := _new_combatant("PlainDefender", 100, 10, 10, 10)
	var debuffed_defender := _new_combatant("DebuffedDefender", 100, 10, 10, 10)
	debuffed_defender.apply_stat_modifier("Defense", -1, 3)

	_check(
		"001200a: a -1 Defense stage lowers effective_defense() below the base stat (%.2f < %d)" % [debuffed_defender.effective_defense(), 10],
		debuffed_defender.effective_defense() < 10.0
	)

	var plain_result: Dictionary = battle._compute_damage(attacker, plain_defender, move)
	var debuffed_result: Dictionary = battle._compute_damage(attacker, debuffed_defender, move)
	_check(
		"001200b: a defense-debuffed defender takes more computed damage (%d > %d)" % [debuffed_result.damage, plain_result.damage],
		debuffed_result.damage > plain_result.damage
	)

	battle.queue_free()
	await process_frame

## New 2026-09-01 (rewritten same day for the MoveEffect refactor):
## verifies a MoveEffect in a move's `effects` array actually applies
## through _resolve_attack -- StatModifierEffect.chance forced to 1.0 for
## determinism (the chance roll itself is just a single randf() call, not
## worth testing separately). Also confirms a move with effects == []
## leaves the defender's stat_modifiers untouched, so the whole mechanic is
## a true no-op for every other move/test in this file.
func _test001300_move_effect_applies_stat_modifier_to_defender() -> void:
	var battle := _load_battle()
	await process_frame

	var debuff_effect := StatModifierEffect.new()
	debuff_effect.stat = "Defense"
	debuff_effect.stages = -1
	debuff_effect.chance = 1.0
	debuff_effect.duration = 3

	var debuff_move := MoveData.new()
	debuff_move.display_name = "AcidSplash"
	debuff_move.power = 10
	debuff_move.accuracy = 1.0
	debuff_move.effects = [debuff_effect]

	var plain_move := MoveData.new()
	plain_move.display_name = "TestStrike"
	plain_move.power = 10
	plain_move.accuracy = 1.0

	var attacker := _new_combatant("Attacker", 100, 20, 10, 10)
	var defender_a := _new_combatant("DefenderA", 100, 10, 10, 10)
	var defender_b := _new_combatant("DefenderB", 100, 10, 10, 10)

	battle._resolve_attack(attacker, defender_a, debuff_move)
	_check("001300a: a guaranteed-trigger effect adds an entry to the defender's stat_modifiers", defender_a.stat_modifiers.has("Defense"))
	_check("001300b: the applied stage matches the effect's stages", defender_a.stat_modifiers.get("Defense", {}).get("stages") == -1)

	battle._resolve_attack(attacker, defender_b, plain_move)
	_check("001300c: a move with no effects leaves the defender's stat_modifiers empty", defender_b.stat_modifiers.is_empty())

	battle.queue_free()
	await process_frame

## New 2026-09-01: verifies MultiHitEffect actually makes _resolve_attack
## hit multiple times -- a fixed-range (3-3, no randomness to fight) multi-
## hit move against a plain single-hit move of identical power should deal
## roughly 3x the damage (not exactly, since each hit rolls its own 0.9-1.1
## variance independently -- checked with a wide tolerance band, not an
## exact multiple).
func _test001400_multi_hit_effect_deals_multiple_hits() -> void:
	var battle := _load_battle()
	await process_frame

	var multi_move := MoveData.new()
	multi_move.display_name = "TripleStrike"
	multi_move.power = 10
	multi_move.accuracy = 1.0
	multi_move.attempts = 3

	var single_move := MoveData.new()
	single_move.display_name = "TestStrike"
	single_move.power = 10
	single_move.accuracy = 1.0

	var attacker := _new_combatant("Attacker", 100, 20, 10, 10)
	var multi_defender := _new_combatant("MultiDefender", 300, 10, 10, 10)
	var single_defender := _new_combatant("SingleDefender", 300, 10, 10, 10)

	battle._resolve_attack(attacker, multi_defender, multi_move)
	var multi_damage := 300 - multi_defender.current_hp

	battle._resolve_attack(attacker, single_defender, single_move)
	var single_damage := 300 - single_defender.current_hp

	_check(
		"001400a: a 3-hit move deals noticeably more total damage than a 1-hit move of equal power (%d > %d)" % [multi_damage, single_damage],
		multi_damage > single_damage * 2
	)

	# A target downed partway through a multi-hit sequence should stop the
	# remaining hits, not deal damage to an already-downed combatant.
	var frail_defender := _new_combatant("FrailDefender", 5, 10, 10, 10)
	battle._resolve_attack(attacker, frail_defender, multi_move)
	_check("001400b: a multi-hit move downs a frail target and stops there", frail_defender.is_downed())

	battle.queue_free()
	await process_frame

## New 2026-09-01: verifies resolve_multi_target_attack hits every living
## target and skips downed ones, using MultiTargetEffect-tagged move (the
## effect itself doesn't drive this helper -- it's called directly, same as
## MultiTargetEffect's own doc comment explains the action menu doesn't
## consult target_mode() yet).
func _test001500_resolve_multi_target_attack_hits_all_living_targets() -> void:
	var battle := _load_battle()
	await process_frame

	var aoe := MultiTargetEffect.new()
	var move := MoveData.new()
	move.display_name = "Sweep"
	move.power = 15
	move.accuracy = 1.0
	move.effects = [aoe]
	_check("001500a: MultiTargetEffect reports target_mode all_enemies", aoe.target_mode() == "all_enemies")

	var attacker := _new_combatant("Attacker", 100, 20, 10, 10)
	var target_a := _new_combatant("TargetA", 100, 10, 10, 10)
	var target_b := _new_combatant("TargetB", 100, 10, 10, 10)
	var already_downed := _new_combatant("AlreadyDowned", 100, 10, 10, 10)
	already_downed.apply_damage(9999)

	var targets: Array[Combatant] = [target_a, target_b, already_downed]
	battle.resolve_multi_target_attack(attacker, targets, move)

	_check("001500b: target A took damage from the AoE sweep", target_a.current_hp < 100)
	_check("001500c: target B took damage from the AoE sweep", target_b.current_hp < 100)
	_check("001500d: an already-downed target is skipped, not attacked again", already_downed.current_hp == 0)

	battle.queue_free()
	await process_frame

## New 2026-09-02: real UI-level check (button presses through
## BattleActionMenu, not calling BattleManager methods directly) that a
## move whose effects include a MultiTargetEffect skips the target picker
## entirely and damages every living enemy, exercising the exact same path
## a player takes: Battle -> a move button -> (no target menu) -> resolved.
func _test001600_multi_target_move_skips_picker_and_hits_all_enemies() -> void:
	var battle := _load_battle()
	await process_frame

	var move := MoveData.new()
	move.display_name = "GroupSweep"
	move.power = 15
	move.accuracy = 1.0
	move.target_all = true

	var actor: Combatant = battle.player_party[0]
	actor.data.assigned_moves = [move, move, move]

	var hp_before: Array[int] = []
	for c in battle.enemy_party:
		hp_before.append(c.current_hp)

	battle._start_turn(actor)
	battle.action_menu.battle_button.pressed.emit()
	battle.action_menu.move1_button.pressed.emit()

	_check(
		"001600a: a multi-target move skips the target picker entirely",
		not battle.action_menu.target_menu_scroll.visible
	)
	_check("001600b: action menu hides after an AoE move resolves", not battle.action_menu.visible)
	_check("001600c: state returns to TICKING after an AoE move resolves", battle.state == battle.State.TICKING)

	var all_hit := true
	for i in battle.enemy_party.size():
		if battle.enemy_party[i].current_hp >= hp_before[i]:
			all_hit = false
	_check("001600d: every living enemy took damage from the AoE move", all_hit)

	battle.queue_free()
	await process_frame

## New 2026-09-02: verifies the enemy-turn AI side of the same wiring --
## _start_enemy_turn routes a MoveData.targets_all_enemies() move to
## resolve_multi_target_attack against the whole living player party,
## instead of the single randomly-picked target it uses for every other
## move.
func _test001700_enemy_ai_uses_multi_target_move_on_all_players() -> void:
	var battle := _load_battle()
	await process_frame

	var move := MoveData.new()
	move.display_name = "EnemySweep"
	move.power = 15
	move.accuracy = 1.0
	move.target_all = true

	var actor: Combatant = battle.enemy_party[0]
	actor.data.assigned_moves = [move]

	var hp_before: Array[int] = []
	for c in battle.player_party:
		hp_before.append(c.current_hp)

	battle._start_turn(actor)

	var all_hit := true
	for i in battle.player_party.size():
		if battle.player_party[i].current_hp >= hp_before[i]:
			all_hit = false
	_check("001700a: enemy AI's multi-target move damages every living player-party member", all_hit)
	_check("001700b: state returns to TICKING after the enemy's AoE turn", battle.state == battle.State.TICKING)

	battle.queue_free()
	await process_frame

## New 2026-09-02: verifies PlaceholderBattleData._load_monster()'s
## .duplicate() call actually does its job -- this is the exact bug the
## 2026-09-02 loader rewire exists to prevent (load() caches the same
## Resource instance per path, so two calls without duplicating would
## hand back the same MonsterData object twice). Mutates one party's
## Emberkit and confirms a second, independently-fetched party's Emberkit
## is unaffected.
func _test001800_placeholder_battle_data_returns_independent_instances() -> void:
	var party_a := PlaceholderBattleData.get_player_party()
	var party_b := PlaceholderBattleData.get_player_party()

	party_a[0].level = 99
	_check(
		"001800a: mutating one get_player_party() call's Emberkit doesn't affect a second call's Emberkit",
		party_b[0].level != 99
	)
	_check("001800b: both calls still return the expected 4-monster party", party_a.size() == 4 and party_b.size() == 4)

## New 2026-09-03: verifies Combatant.effective_speed() actually applies
## the SPEED_REFERENCE tanh curve rather than staying flat `speed *
## stage_multiplier` -- this is the diminishing-returns behavior Woden
## asked for after confirming the ATB gauge fill itself is plain linear.
## Checks three things: (1) doubling a low speed value roughly doubles
## effective speed (curve is close to linear well under SPEED_REFERENCE,
## so today's roster -- speed 6-20 -- barely changes), (2) doubling a
## HIGH speed value (already near/above SPEED_REFERENCE) does NOT come
## close to doubling effective speed -- the actual diminishing-returns
## check, (3) effective speed always stays strictly below SPEED_REFERENCE
## no matter how high the base stat goes, confirming it's a true
## asymptotic cap and not just a slower linear climb.
func _test001900_effective_speed_has_diminishing_returns() -> void:
	var low_slow := _new_combatant("LowSlow", 100, 10, 10, 10)
	var low_fast := _new_combatant("LowFast", 100, 10, 10, 20)
	var high_slow := _new_combatant("HighSlow", 100, 10, 10, 100)
	var high_fast := _new_combatant("HighFast", 100, 10, 10, 200)
	# speed=400 (x=10 in the tanh) rather than something even more
	# extreme: 1-tanh(x) shrinks so fast that past roughly x=20 it
	# underflows below double-precision resolution and tanh(x) rounds to
	# an exact 1.0, which would make this assertion falsely fail on a
	# correct implementation. x=10 leaves 1-tanh(x) ~= 4e-9, comfortably
	# representable and still nowhere near the cap.
	var extreme := _new_combatant("Extreme", 100, 10, 10, 400)

	var low_ratio: float = low_fast.effective_speed() / low_slow.effective_speed()
	var high_ratio: float = high_fast.effective_speed() / high_slow.effective_speed()

	_check(
		"001900a: doubling a low speed stat (10->20) nearly doubles effective speed (ratio %.3f)" % low_ratio,
		low_ratio > 1.85
	)
	_check(
		"001900b: doubling a high speed stat (100->200) does NOT nearly double effective speed (ratio %.3f)" % high_ratio,
		high_ratio < 1.2
	)
	_check(
		"001900c: doubling at the high end gains far less than doubling at the low end (%.3f < %.3f)" % [high_ratio, low_ratio],
		high_ratio < low_ratio
	)
	_check(
		"001900d: even an absurdly high speed stat stays strictly under SPEED_REFERENCE",
		extreme.effective_speed() < Combatant.SPEED_REFERENCE
	)

## New 2026-09-01: verifies tick_stat_modifiers() actually decays and
## removes an expired modifier, and that Combatant.effective_defense()
## returns to the unmodified base stat once it's gone.
func _test002000_stat_modifier_expires_after_duration() -> void:
	var defender := _new_combatant("Defender", 100, 10, 10, 10)
	defender.apply_stat_modifier("Defense", -1, 1)
	_check("002000a: modifier is active immediately after being applied", defender.stat_modifiers.has("Defense"))

	defender.tick_stat_modifiers()
	_check("002000b: a 1-turn modifier is gone after a single tick", not defender.stat_modifiers.has("Defense"))
	_check("002000c: effective_defense() returns to the base stat once the modifier expires", defender.effective_defense() == 10.0)

func _test002100_win_detection() -> void:
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
	_check("002100a: _check_battle_over reports true once the enemy party is downed", result)
	_check("002100b: state becomes BATTLE_OVER on a win", battle.state == battle.State.BATTLE_OVER)
	_check("002100c: battle_won signal fired", won[0])

	battle.queue_free()
	await process_frame

func _test002200_run_flees() -> void:
	var battle := _load_battle()
	await process_frame

	var fled := [false]  # see the mutable-box note in _test002100_win_detection
	battle.battle_fled.connect(func(): fled[0] = true)

	var actor: Combatant = battle.player_party[0]
	battle._start_turn(actor)
	battle.action_menu.run_button.pressed.emit()

	_check("002200a: battle_fled signal fired on Run", fled[0])
	_check("002200b: state becomes BATTLE_OVER after fleeing", battle.state == battle.State.BATTLE_OVER)

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
