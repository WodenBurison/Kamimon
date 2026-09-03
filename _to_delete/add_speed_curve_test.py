import sys

PATH = "project-kamimon/scripts/battle/tests/battle_smoke_test.gd"


def apply(path, replacements):
    with open(path, "r") as f:
        content = f.read()
    for old, new in replacements:
        count = content.count(old)
        if count != 1:
            print(f"ERROR: {path}: expected 1 occurrence, found {count}", file=sys.stderr)
            print("---- OLD ----")
            print(old)
            sys.exit(1)
        content = content.replace(old, new)
    with open(path, "w") as f:
        f.write(content)
    print(f"OK: {path} ({len(replacements)} edits)")


apply(PATH, [
    (
"""	_test_placeholder_battle_data_returns_independent_instances()

	print(\"\\n=== %d passed, %d failed ===\" % [_pass_count, _fail_count])""",
"""	_test_placeholder_battle_data_returns_independent_instances()
	_test_effective_speed_has_diminishing_returns()

	print(\"\\n=== %d passed, %d failed ===\" % [_pass_count, _fail_count])"""
    ),
    (
"""## New 2026-09-01: verifies tick_stat_modifiers() actually decays and
## removes an expired modifier, and that Combatant.effective_defense()
## returns to the unmodified base stat once it's gone.
func _test_stat_modifier_expires_after_duration() -> void:""",
"""## New 2026-09-03: verifies Combatant.effective_speed() actually applies
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
func _test_effective_speed_has_diminishing_returns() -> void:
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
		"doubling a low speed stat (10->20) nearly doubles effective speed (ratio %.3f)" % low_ratio,
		low_ratio > 1.85
	)
	_check(
		"doubling a high speed stat (100->200) does NOT nearly double effective speed (ratio %.3f)" % high_ratio,
		high_ratio < 1.2
	)
	_check(
		"doubling at the high end gains far less than doubling at the low end (%.3f < %.3f)" % [high_ratio, low_ratio],
		high_ratio < low_ratio
	)
	_check(
		"even an absurdly high speed stat stays strictly under SPEED_REFERENCE",
		extreme.effective_speed() < Combatant.SPEED_REFERENCE
	)

## New 2026-09-01: verifies tick_stat_modifiers() actually decays and
## removes an expired modifier, and that Combatant.effective_defense()
## returns to the unmodified base stat once it's gone.
func _test_stat_modifier_expires_after_duration() -> void:"""
    ),
])

print("All done.")
