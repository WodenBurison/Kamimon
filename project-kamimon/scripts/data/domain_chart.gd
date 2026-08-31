extends RefCounted
class_name DomainChart
## The locked 10-Domain, 23-relationship effectiveness graph from
## Types & Charts.md.
##
## BEATS[X] is the list of Domains that an X-domain move is super-effective
## against. The reverse direction (defending with the Domain that beats the
## attacker) is not-very-effective — same asymmetric relationship as the
## design doc's "Tide beats Flame" edges. Any pair with no listed
## relationship (in either direction) is neutral, same domain vs itself is
## also neutral (no explicit same-domain rule in the design).
##
## This is pure graph data now — the ranked multi-domain stab/weakness/
## resistance resolution that actually reads this table lives in
## TypeResolution (scripts/data/type_resolution.gd), which replaced the old
## single-Domain get_multiplier()/1.5x/0.5x placeholder that used to live in
## this file (2026-08-31 — see the locked Combat damage formula design in
## Kamimon_Design_Notes/050 Combat.md).
const BEATS := {
	"Tide": ["Flame", "Metal"],
	"Flame": ["Verdant", "Stone", "Frost"],
	"Verdant": ["Tide", "Stone"],
	"Stone": ["Gale", "Bolt"],
	"Metal": ["Stone", "Frost", "Verdant"],
	"Gale": ["Aether", "Miasma"],
	"Bolt": ["Aether", "Miasma", "Tide"],
	"Miasma": ["Metal", "Frost", "Verdant"],
	"Aether": ["Metal", "Miasma"],
	"Frost": ["Tide"],
}
