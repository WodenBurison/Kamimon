import sys

PATH = "project-kamimon/scripts/battle/combatant.gd"


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
"""const ATB_MAX := 100.0

## Stage step/cap for the new stat-modifier mechanic""",
"""const ATB_MAX := 100.0

## Speed-to-gauge-fill diminishing-returns constant (2026-09-03), same
## tanh-bounded shape as battle_manager.gd's LEVEL_CAP/LEVEL_STEEPNESS
## (`cap * tanh(x / steepness)`, not the multiplicative `cap ^ tanh(x)`
## form used there -- this isn't a ratio between two combatants, it's a
## single stat being turned into a bounded fill rate). SPEED_REFERENCE
## does double duty as both the steepness and the asymptotic cap: for
## speed well under this value the curve is close to linear (matches
## today's roster, speed 6-20, within about 8% of the old uncapped
## behavior), and gains taper off hard as speed climbs toward and past
## it, so a very high Speed stat (once real high-end content exists)
## can't buy unbounded turn frequency the way flat `speed * delta` did.
## Placeholder value, not yet reviewed by Woden -- same status as
## GEAR_CAP/ACC_EVA_CAP/CRIT_STAT_REFERENCE.
const SPEED_REFERENCE := 40.0

## Stage step/cap for the new stat-modifier mechanic"""
    ),
    (
"""func effective_speed() -> float:
	return data.speed * _stage_multiplier("Speed")""",
"""## Diminishing-returns curve applied to the raw stat first (see
## SPEED_REFERENCE above), THEN the stage multiplier on top -- a
## temporary Speed buff/debuff from a move effect still swings turn
## frequency by its full linear percentage, it's only the underlying
## stat investment that gets bent toward a cap.
func effective_speed() -> float:
	var curved_speed: float = SPEED_REFERENCE * tanh(data.speed / SPEED_REFERENCE)
	return curved_speed * _stage_multiplier("Speed")"""
    ),
])

print("All done.")
