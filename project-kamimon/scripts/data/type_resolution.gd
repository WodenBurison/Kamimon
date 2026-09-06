extends RefCounted
class_name TypeResolution
## Resolves the locked multi-domain stab/weakness/resistance rule against the
## real DomainChart.BEATS graph.
##
## A move carries an UNRANKED set of domain tags (MoveData.domains — any
## number, order doesn't matter). A monster's domains are RANKED
## (MonsterData.domains — Primary/Secondary/Tertiary/Last, index 0..3). For
## stab, weakness, and resistance independently, this walks the relevant
## monster's ranked domain list from Primary downward and uses the first
## slot that qualifies — "best match per category." Position matters: a
## monster with Flame in slot 0 and Wyrm in slot 1 gets a bigger Flame stab
## bonus than one with the same two Domains reversed.

const RANK_PCT: Array[float] = [0.40, 0.30, 0.20, 0.10]

## Called from: internal only -- derive_type_factors(), once per category
## (stab/weakness/resistance).
## Purpose: walks ranked_domains from index 0 and returns RANK_PCT for the
## first slot where test.call(domain) is true, or 0.0 if nothing qualifies
## (including every slot being "").
static func best_rank_match(ranked_domains: Array[String], test: Callable) -> float:
	for i in ranked_domains.size():
		var d: String = ranked_domains[i]
		if d != "" and test.call(d):
			return RANK_PCT[i] if i < RANK_PCT.size() else 0.0
	return 0.0

## Called from: internal only -- derive_type_factors()'s three test
## Callables.
## Purpose: looks up what a domain beats in DomainChart, or [] if it's not
## in the chart.
static func _beats_of(domain: String) -> Array:
	return DomainChart.BEATS.get(domain, [])

## Called from: battle_manager.gd's _compute_damage(), once per hit.
## Purpose: returns {stab_pct, weak_pct, resist_pct}, each already the
## resolved rank percentage (0.0, or one of 0.40/0.30/0.20/0.10) -- the
## caller ADDS them per the locked formula (stab% + weak% - resist%), never
## multiplies them.
static func derive_type_factors(
	move_domains: Array[String],
	attacker_domains: Array[String],
	defender_domains: Array[String]
) -> Dictionary:
	var stab_pct := best_rank_match(attacker_domains, func(ad: String) -> bool:
		return move_domains.has(ad)
	)
	var weak_pct := best_rank_match(defender_domains, func(dd: String) -> bool:
		for md in move_domains:
			if _beats_of(md).has(dd):
				return true
		return false
	)
	var resist_pct := best_rank_match(defender_domains, func(dd: String) -> bool:
		for md in move_domains:
			if _beats_of(dd).has(md):
				return true
		return false
	)
	return {"stab_pct": stab_pct, "weak_pct": weak_pct, "resist_pct": resist_pct}
