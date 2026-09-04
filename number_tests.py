import sys

PATH = "project-kamimon/scripts/battle/tests/battle_smoke_test.gd"

RENAMES = [
    ("_test_scene_loads_and_menu_opens", "_test000100_scene_loads_and_menu_opens"),
    ("_test_attack_hits_and_advances_turn", "_test000200_attack_hits_and_advances_turn"),
    ("_test_assigned_move_hits", "_test000300_assigned_move_hits"),
    ("_test_downed_excluded_from_targets", "_test000400_downed_excluded_from_targets"),
    ("_test_guard_halves_damage", "_test000500_guard_halves_damage"),
    ("_test_domain_effectiveness", "_test000600_domain_effectiveness"),
    ("_test_win_detection", "_test000700_win_detection"),
    ("_test_run_flees", "_test000800_run_flees"),
    ("_test_level_gap_affects_damage", "_test000900_level_gap_affects_damage"),
    ("_test_gear_affects_damage", "_test001000_gear_affects_damage"),
    ("_test_evasion_reduces_hit_chance", "_test001100_evasion_reduces_hit_chance"),
    ("_test_crit_stat_raises_crit_chance", "_test001200_crit_stat_raises_crit_chance"),
    ("_test_crit_can_multiply_damage", "_test001300_crit_can_multiply_damage"),
    ("_test_stat_modifier_changes_effective_stat_and_damage", "_test001400_stat_modifier_changes_effective_stat_and_damage"),
    ("_test_move_effect_applies_stat_modifier_to_defender", "_test001500_move_effect_applies_stat_modifier_to_defender"),
    ("_test_stat_modifier_expires_after_duration", "_test001600_stat_modifier_expires_after_duration"),
    ("_test_multi_hit_effect_deals_multiple_hits", "_test001700_multi_hit_effect_deals_multiple_hits"),
    ("_test_resolve_multi_target_attack_hits_all_living_targets", "_test001800_resolve_multi_target_attack_hits_all_living_targets"),
    ("_test_multi_target_move_skips_picker_and_hits_all_enemies", "_test001900_multi_target_move_skips_picker_and_hits_all_enemies"),
    ("_test_enemy_ai_uses_multi_target_move_on_all_players", "_test002000_enemy_ai_uses_multi_target_move_on_all_players"),
    ("_test_placeholder_battle_data_returns_independent_instances", "_test002100_placeholder_battle_data_returns_independent_instances"),
    ("_test_effective_speed_has_diminishing_returns", "_test002200_effective_speed_has_diminishing_returns"),
]

RENAMES.sort(key=lambda pair: -len(pair[0]))

LABELS = [
    ("player party has 4 monsters", "000100a: player party has 4 monsters"),
    ("enemy party has 3 monsters", "000100b: enemy party has 3 monsters"),
    ("battle starts in TICKING", "000100c: battle starts in TICKING"),
    ("forcing a turn enters PLAYER_INPUT", "000100d: forcing a turn enters PLAYER_INPUT"),
    ("action menu is visible", "000100e: action menu is visible"),
    ("root menu is showing", "000100f: root menu is showing"),
    ("move1 label matches assigned move", "000100g: move1 label matches assigned move"),
    ("move2 label matches assigned move", "000100h: move2 label matches assigned move"),
    ("move3 label matches assigned move", "000100i: move3 label matches assigned move"),
    ("move1 is not disabled", "000100j: move1 is not disabled"),
    ("Battle press shows the battle menu", "000100k: Battle press shows the battle menu"),
    ("Battle press hides the root menu", "000100l: Battle press hides the root menu"),

    ("Attack with 3 living enemies opens the target picker", "000200a: Attack with 3 living enemies opens the target picker"),
    ("target menu lists 3 targets + Back", "000200b: target menu lists 3 targets + Back"),
    ("basic Attack (guaranteed accuracy) dealt damage", "000200c: basic Attack (guaranteed accuracy) dealt damage"),
    ("state returns to TICKING after a resolved action", "000200d: state returns to TICKING after a resolved action"),
    ("action menu hides after the turn resolves", "000200e: action menu hides after the turn resolves"),

    ("assigned move (100%% accuracy) dealt damage", "000300a: assigned move (100%% accuracy) dealt damage"),
    ("state returns to TICKING after an assigned move", "000300b: state returns to TICKING after an assigned move"),

    ("forced damage downs the target enemy", "000400a: forced damage downs the target enemy"),
    ("target menu excludes the downed enemy (2 living + Back)", "000400b: target menu excludes the downed enemy (2 living + Back)"),
    ("downed enemy's name does not appear in the target list", "000400c: downed enemy's name does not appear in the target list"),
    ("state returns to TICKING after resolving around a downed enemy", "000400d: state returns to TICKING after resolving around a downed enemy"),

    ("guarding reduced damage taken (%d vs %d)", "000500a: guarding reduced damage taken (%d vs %d)"),
    ("guarded damage is roughly half of unguarded (within rounding)", "000500b: guarded damage is roughly half of unguarded (within rounding)"),

    ("Tide move vs Flame defender is super-effective (%d > %d neutral)", "000600a: Tide move vs Flame defender is super-effective (%d > %d neutral)"),
    ("Verdant move vs Flame defender is not-very-effective (%d < %d neutral)", "000600b: Verdant move vs Flame defender is not-very-effective (%d < %d neutral)"),

    ("_check_battle_over reports true once the enemy party is downed", "000700a: _check_battle_over reports true once the enemy party is downed"),
    ("state becomes BATTLE_OVER on a win", "000700b: state becomes BATTLE_OVER on a win"),
    ("battle_won signal fired", "000700c: battle_won signal fired"),

    ("battle_fled signal fired on Run", "000800a: battle_fled signal fired on Run"),
    ("state becomes BATTLE_OVER after fleeing", "000800b: state becomes BATTLE_OVER after fleeing"),

    ("higher attacker level deals more damage at equal stats (%d > %d)", "000900: higher attacker level deals more damage at equal stats (%d > %d)"),

    ("equipped gear deals more damage than none, equal stats (%d > %d)", "001000: equipped gear deals more damage than none, equal stats (%d > %d)"),

    ("higher defender evasion lowers hit chance (%.3f < %.3f)", "001100a: higher defender evasion lowers hit chance (%.3f < %.3f)"),
    ("hit chance never drops below the MIN_HIT_CHANCE floor", "001100b: hit chance never drops below the MIN_HIT_CHANCE floor"),

    ("default crit stat matches the flat baseline exactly (%.4f == %.4f)", "001200a: default crit stat matches the flat baseline exactly (%.4f == %.4f)"),
    ("higher crit stat raises crit chance (%.3f > %.3f)", "001200b: higher crit stat raises crit chance (%.3f > %.3f)"),
    ("crit chance never exceeds the hard clamp", "001200c: crit chance never exceeds the hard clamp"),

    ("a high crit-stat attacker lands at least one crit over 40 seeded trials", "001300: a high crit-stat attacker lands at least one crit over 40 seeded trials"),

    ("a -1 Defense stage lowers effective_defense() below the base stat (%.2f < %d)", "001400a: a -1 Defense stage lowers effective_defense() below the base stat (%.2f < %d)"),
    ("a defense-debuffed defender takes more computed damage (%d > %d)", "001400b: a defense-debuffed defender takes more computed damage (%d > %d)"),

    ("a guaranteed-trigger effect adds an entry to the defender's stat_modifiers", "001500a: a guaranteed-trigger effect adds an entry to the defender's stat_modifiers"),
    ("the applied stage matches the effect's stages", "001500b: the applied stage matches the effect's stages"),
    ("a move with no effects leaves the defender's stat_modifiers empty", "001500c: a move with no effects leaves the defender's stat_modifiers empty"),

    ("modifier is active immediately after being applied", "001600a: modifier is active immediately after being applied"),
    ("a 1-turn modifier is gone after a single tick", "001600b: a 1-turn modifier is gone after a single tick"),
    ("effective_defense() returns to the base stat once the modifier expires", "001600c: effective_defense() returns to the base stat once the modifier expires"),

    ("a 3-hit move deals noticeably more total damage than a 1-hit move of equal power (%d > %d)", "001700a: a 3-hit move deals noticeably more total damage than a 1-hit move of equal power (%d > %d)"),
    ("a multi-hit move downs a frail target and stops there", "001700b: a multi-hit move downs a frail target and stops there"),

    ("MultiTargetEffect reports target_mode all_enemies", "001800a: MultiTargetEffect reports target_mode all_enemies"),
    ("target A took damage from the AoE sweep", "001800b: target A took damage from the AoE sweep"),
    ("target B took damage from the AoE sweep", "001800c: target B took damage from the AoE sweep"),
    ("an already-downed target is skipped, not attacked again", "001800d: an already-downed target is skipped, not attacked again"),

    ("a multi-target move skips the target picker entirely", "001900a: a multi-target move skips the target picker entirely"),
    ("action menu hides after an AoE move resolves", "001900b: action menu hides after an AoE move resolves"),
    ("state returns to TICKING after an AoE move resolves", "001900c: state returns to TICKING after an AoE move resolves"),
    ("every living enemy took damage from the AoE move", "001900d: every living enemy took damage from the AoE move"),

    ("enemy AI's multi-target move damages every living player-party member", "002000a: enemy AI's multi-target move damages every living player-party member"),
    ("state returns to TICKING after the enemy's AoE turn", "002000b: state returns to TICKING after the enemy's AoE turn"),

    ("mutating one get_player_party() call's Emberkit doesn't affect a second call's Emberkit", "002100a: mutating one get_player_party() call's Emberkit doesn't affect a second call's Emberkit"),
    ("both calls still return the expected 4-monster party", "002100b: both calls still return the expected 4-monster party"),

    ("doubling a low speed stat (10->20) nearly doubles effective speed (ratio %.3f)", "002200a: doubling a low speed stat (10->20) nearly doubles effective speed (ratio %.3f)"),
    ("doubling a high speed stat (100->200) does NOT nearly double effective speed (ratio %.3f)", "002200b: doubling a high speed stat (100->200) does NOT nearly double effective speed (ratio %.3f)"),
    ("doubling at the high end gains far less than doubling at the low end (%.3f < %.3f)", "002200c: doubling at the high end gains far less than doubling at the low end (%.3f < %.3f)"),
    ("even an absurdly high speed stat stays strictly under SPEED_REFERENCE", "002200d: even an absurdly high speed stat stays strictly under SPEED_REFERENCE"),
]

assert len(LABELS) == 66, "expected 66 labels, got %d" % len(LABELS)


def main():
    with open(PATH, "r") as f:
        content = f.read()

    for old, new in RENAMES:
        count = content.count(old)
        if count < 2:
            print("ERROR renaming %r -> %r: found %d occurrences (expected >=2)" % (old, new, count), file=sys.stderr)
            sys.exit(1)
        content = content.replace(old, new)

    for bare_old, prefixed_new in LABELS:
        old_q = '"' + bare_old + '"'
        new_q = '"' + prefixed_new + '"'
        count = content.count(old_q)
        if count != 1:
            print("ERROR label %r: found %d occurrences (expected 1)" % (bare_old, count), file=sys.stderr)
            sys.exit(1)
        content = content.replace(old_q, new_q)

    with open(PATH, "w") as f:
        f.write(content)

    print("OK: %d renames, %d labels applied to %s" % (len(RENAMES), len(LABELS), PATH))


main()
