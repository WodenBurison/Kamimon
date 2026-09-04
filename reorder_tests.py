import sys

PATH = "project-kamimon/scripts/battle/tests/battle_smoke_test.gd"

RENAMES = [
    ("_test000900_level_gap_affects_damage", "_test000700_level_gap_affects_damage"),
    ("_test001000_gear_affects_damage", "_test000800_gear_affects_damage"),
    ("_test001100_evasion_reduces_hit_chance", "_test000900_evasion_reduces_hit_chance"),
    ("_test001200_crit_stat_raises_crit_chance", "_test001000_crit_stat_raises_crit_chance"),
    ("_test001300_crit_can_multiply_damage", "_test001100_crit_can_multiply_damage"),
    ("_test001400_stat_modifier_changes_effective_stat_and_damage", "_test001200_stat_modifier_changes_effective_stat_and_damage"),
    ("_test001500_move_effect_applies_stat_modifier_to_defender", "_test001300_move_effect_applies_stat_modifier_to_defender"),
    ("_test001700_multi_hit_effect_deals_multiple_hits", "_test001400_multi_hit_effect_deals_multiple_hits"),
    ("_test001800_resolve_multi_target_attack_hits_all_living_targets", "_test001500_resolve_multi_target_attack_hits_all_living_targets"),
    ("_test001900_multi_target_move_skips_picker_and_hits_all_enemies", "_test001600_multi_target_move_skips_picker_and_hits_all_enemies"),
    ("_test002000_enemy_ai_uses_multi_target_move_on_all_players", "_test001700_enemy_ai_uses_multi_target_move_on_all_players"),
    ("_test002100_placeholder_battle_data_returns_independent_instances", "_test001800_placeholder_battle_data_returns_independent_instances"),
    ("_test002200_effective_speed_has_diminishing_returns", "_test001900_effective_speed_has_diminishing_returns"),
    ("_test001600_stat_modifier_expires_after_duration", "_test002000_stat_modifier_expires_after_duration"),
    ("_test000700_win_detection", "_test002100_win_detection"),
    ("_test000800_run_flees", "_test002200_run_flees"),
]

LABELS = [
    ("000900: higher attacker level deals more damage at equal stats (%d > %d)", "000700: higher attacker level deals more damage at equal stats (%d > %d)"),

    ("001000: equipped gear deals more damage than none, equal stats (%d > %d)", "000800: equipped gear deals more damage than none, equal stats (%d > %d)"),

    ("001100a: higher defender evasion lowers hit chance (%.3f < %.3f)", "000900a: higher defender evasion lowers hit chance (%.3f < %.3f)"),
    ("001100b: hit chance never drops below the MIN_HIT_CHANCE floor", "000900b: hit chance never drops below the MIN_HIT_CHANCE floor"),

    ("001200a: default crit stat matches the flat baseline exactly (%.4f == %.4f)", "001000a: default crit stat matches the flat baseline exactly (%.4f == %.4f)"),
    ("001200b: higher crit stat raises crit chance (%.3f > %.3f)", "001000b: higher crit stat raises crit chance (%.3f > %.3f)"),
    ("001200c: crit chance never exceeds the hard clamp", "001000c: crit chance never exceeds the hard clamp"),

    ("001300: a high crit-stat attacker lands at least one crit over 40 seeded trials", "001100: a high crit-stat attacker lands at least one crit over 40 seeded trials"),

    ("001400a: a -1 Defense stage lowers effective_defense() below the base stat (%.2f < %d)", "001200a: a -1 Defense stage lowers effective_defense() below the base stat (%.2f < %d)"),
    ("001400b: a defense-debuffed defender takes more computed damage (%d > %d)", "001200b: a defense-debuffed defender takes more computed damage (%d > %d)"),

    ("001500a: a guaranteed-trigger effect adds an entry to the defender's stat_modifiers", "001300a: a guaranteed-trigger effect adds an entry to the defender's stat_modifiers"),
    ("001500b: the applied stage matches the effect's stages", "001300b: the applied stage matches the effect's stages"),
    ("001500c: a move with no effects leaves the defender's stat_modifiers empty", "001300c: a move with no effects leaves the defender's stat_modifiers empty"),

    ("001700a: a 3-hit move deals noticeably more total damage than a 1-hit move of equal power (%d > %d)", "001400a: a 3-hit move deals noticeably more total damage than a 1-hit move of equal power (%d > %d)"),
    ("001700b: a multi-hit move downs a frail target and stops there", "001400b: a multi-hit move downs a frail target and stops there"),

    ("001800a: MultiTargetEffect reports target_mode all_enemies", "001500a: MultiTargetEffect reports target_mode all_enemies"),
    ("001800b: target A took damage from the AoE sweep", "001500b: target A took damage from the AoE sweep"),
    ("001800c: target B took damage from the AoE sweep", "001500c: target B took damage from the AoE sweep"),
    ("001800d: an already-downed target is skipped, not attacked again", "001500d: an already-downed target is skipped, not attacked again"),

    ("001900a: a multi-target move skips the target picker entirely", "001600a: a multi-target move skips the target picker entirely"),
    ("001900b: action menu hides after an AoE move resolves", "001600b: action menu hides after an AoE move resolves"),
    ("001900c: state returns to TICKING after an AoE move resolves", "001600c: state returns to TICKING after an AoE move resolves"),
    ("001900d: every living enemy took damage from the AoE move", "001600d: every living enemy took damage from the AoE move"),

    ("002000a: enemy AI's multi-target move damages every living player-party member", "001700a: enemy AI's multi-target move damages every living player-party member"),
    ("002000b: state returns to TICKING after the enemy's AoE turn", "001700b: state returns to TICKING after the enemy's AoE turn"),

    ("002100a: mutating one get_player_party() call's Emberkit doesn't affect a second call's Emberkit", "001800a: mutating one get_player_party() call's Emberkit doesn't affect a second call's Emberkit"),
    ("002100b: both calls still return the expected 4-monster party", "001800b: both calls still return the expected 4-monster party"),

    ("002200a: doubling a low speed stat (10->20) nearly doubles effective speed (ratio %.3f)", "001900a: doubling a low speed stat (10->20) nearly doubles effective speed (ratio %.3f)"),
    ("002200b: doubling a high speed stat (100->200) does NOT nearly double effective speed (ratio %.3f)", "001900b: doubling a high speed stat (100->200) does NOT nearly double effective speed (ratio %.3f)"),
    ("002200c: doubling at the high end gains far less than doubling at the low end (%.3f < %.3f)", "001900c: doubling at the high end gains far less than doubling at the low end (%.3f < %.3f)"),
    ("002200d: even an absurdly high speed stat stays strictly under SPEED_REFERENCE", "001900d: even an absurdly high speed stat stays strictly under SPEED_REFERENCE"),

    ("001600a: modifier is active immediately after being applied", "002000a: modifier is active immediately after being applied"),
    ("001600b: a 1-turn modifier is gone after a single tick", "002000b: a 1-turn modifier is gone after a single tick"),
    ("001600c: effective_defense() returns to the base stat once the modifier expires", "002000c: effective_defense() returns to the base stat once the modifier expires"),

    ("000700a: _check_battle_over reports true once the enemy party is downed", "002100a: _check_battle_over reports true once the enemy party is downed"),
    ("000700b: state becomes BATTLE_OVER on a win", "002100b: state becomes BATTLE_OVER on a win"),
    ("000700c: battle_won signal fired", "002100c: battle_won signal fired"),

    ("000800a: battle_fled signal fired on Run", "002200a: battle_fled signal fired on Run"),
    ("000800b: state becomes BATTLE_OVER after fleeing", "002200b: state becomes BATTLE_OVER after fleeing"),
]

assert len(RENAMES) == 16, "expected 16 renames, got %d" % len(RENAMES)
assert len(LABELS) == 39, "expected 39 labels, got %d" % len(LABELS)


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
