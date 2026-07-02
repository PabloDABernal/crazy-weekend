extends SceneTree
## Test de regresión Bug 1 (fix §7.2 de .ai-studio/specs/bug-1-crazy-bet-confirm-block.md).
##
## Cubre CrazyBetResolver.select_restricted_markets: antes del fix operaba sobre ofertas
## por-OPCIÓN (una entrada por option_key apostable), no por-mercado, así que `allowed` terminaba
## siendo duplicados del mismo market_id (ej. ["1x2", "1x2"]) en vez de 1-2 mercados distintos.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/economy/crazy_bet_resolver_test.gd

const MARKET_MVP_IDS: Array[StringName] = [
	&"1x2", &"btts", &"first_scorer", &"goals_ou_1_5", &"goals_ou_2_5", &"goals_ou_3_5", &"cards_ou", &"fouls_ou",
]

## Opciones apostables por mercado, igual de heterogéneas que las reales del catálogo MVP (ver
## MatchPanel.MARKET_WIDGET_NODE_NAMES): 3 para 1x2, 2 para cada over/under y btts, N para first_scorer.
const OPTIONS_BY_MARKET: Dictionary = {
	&"1x2": [&"home", &"draw", &"away"],
	&"btts": [&"yes", &"no"],
	&"first_scorer": [&"p1", &"p2", &"p3"],
	&"goals_ou_1_5": [&"over", &"under"],
	&"goals_ou_2_5": [&"over", &"under"],
	&"goals_ou_3_5": [&"over", &"under"],
	&"cards_ou": [&"over", &"under"],
	&"fouls_ou": [&"over", &"under"],
}

## Confidence por mercado -- deliberadamente distinta entre mercados, con "1x2" como la más alta
## (0.9) para poder aseverar cuál mercado queda excluido de forma determinista.
const CONFIDENCE_BY_MARKET: Dictionary = {
	&"1x2": 0.9,
	&"btts": 0.4,
	&"first_scorer": 0.2,
	&"goals_ou_1_5": 0.5,
	&"goals_ou_2_5": 0.6,
	&"goals_ou_3_5": 0.3,
	&"cards_ou": 0.35,
	&"fouls_ou": 0.45,
}


func _init() -> void:
	var failures: Array[String] = []

	_test_no_duplicate_market_ids(failures)
	_test_respects_min_max_allowed_markets(failures)
	_test_excludes_highest_confidence_market(failures)
	_test_no_duplicates_across_many_seeds(failures)
	_test_single_distinct_market_is_never_excluded(failures)

	if failures.is_empty():
		print("[PASS] crazy_bet_resolver_test: todos los checks OK")
	else:
		push_error("[FAIL] crazy_bet_resolver_test: %d fallo(s)" % failures.size())
		for failure in failures:
			push_error("  - " + failure)

	quit(0 if failures.is_empty() else 1)


func _build_offers_for_8_markets() -> Array[MarketOffer]:
	var offers: Array[MarketOffer] = []
	for market_id in MARKET_MVP_IDS:
		for option_key in OPTIONS_BY_MARKET[market_id]:
			var offer := MarketOffer.new()
			offer.market_id = market_id
			offer.match_id = &"match_test"
			offer.option_key = option_key
			offer.confidence = CONFIDENCE_BY_MARKET[market_id]
			offer.displayed_probability_min = 0.1
			offer.displayed_probability_max = 0.2
			offers.append(offer)
	return offers


## Regresión directa del defecto secundario (§5 de la spec): `allowed_market_ids` no debe contener
## el mismo market_id dos veces aunque `available` traiga varias ofertas (opciones) por mercado.
func _test_no_duplicate_market_ids(failures: Array[String]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var offers := _build_offers_for_8_markets()
	var result: Dictionary = CrazyBetResolver.select_restricted_markets(offers, rng)
	var allowed: Array = result["allowed"]

	var seen: Dictionary = {}
	for market_id in allowed:
		if seen.has(market_id):
			failures.append("allowed_market_ids contiene un duplicado: %s (allowed=%s)" % [market_id, allowed])
		seen[market_id] = true


func _test_respects_min_max_allowed_markets(failures: Array[String]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var offers := _build_offers_for_8_markets()
	var result: Dictionary = CrazyBetResolver.select_restricted_markets(offers, rng)
	var allowed: Array = result["allowed"]

	if allowed.size() < EconomyRules.CRAZY_BET_MIN_ALLOWED_MARKETS:
		failures.append("allowed_market_ids.size()=%d < MIN=%d" % [allowed.size(), EconomyRules.CRAZY_BET_MIN_ALLOWED_MARKETS])
	if allowed.size() > EconomyRules.CRAZY_BET_MAX_ALLOWED_MARKETS:
		failures.append("allowed_market_ids.size()=%d > MAX=%d" % [allowed.size(), EconomyRules.CRAZY_BET_MAX_ALLOWED_MARKETS])


## El mercado más "informado" (mayor confidence) del fixture es "1x2" (0.9) -- debe ser el excluido,
## nunca uno de los permitidos, con independencia del rng.
func _test_excludes_highest_confidence_market(failures: Array[String]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var offers := _build_offers_for_8_markets()
	var result: Dictionary = CrazyBetResolver.select_restricted_markets(offers, rng)
	var allowed: Array = result["allowed"]
	var excluded: StringName = result["excluded"]

	if allowed.has(&"1x2"):
		failures.append("el mercado de mayor confidence (1x2) quedó permitido: allowed=%s" % [allowed])
	if excluded != &"1x2":
		failures.append("excluded_market_id esperado '1x2', obtenido '%s'" % [excluded])


## Barrido de semillas para reducir la chance de que un caso puntual de rng oculte una regresión.
func _test_no_duplicates_across_many_seeds(failures: Array[String]) -> void:
	for seed_value in range(0, 50):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var offers := _build_offers_for_8_markets()
		var result: Dictionary = CrazyBetResolver.select_restricted_markets(offers, rng)
		var allowed: Array = result["allowed"]

		var seen: Dictionary = {}
		for market_id in allowed:
			if seen.has(market_id):
				failures.append("seed=%d: allowed_market_ids con duplicado %s (allowed=%s)" % [seed_value, market_id, allowed])
				break
			seen[market_id] = true


## Caso límite hallado en review del fix de Bug 1: si solo hay 1 market_id distinto disponible en el
## tick (ej. un futuro catálogo data-driven con un único .tres), `tied_for_highest` es ese único
## mercado y excluirlo dejaría `allowed` vacío, violando la garantía de "al menos 1 mercado permitido".
## `allowed` debe seguir conteniendo ese único mercado, sin excluir nada.
func _test_single_distinct_market_is_never_excluded(failures: Array[String]) -> void:
	for seed_value in range(0, 10):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value

		var offers: Array[MarketOffer] = []
		for option_key in OPTIONS_BY_MARKET[&"1x2"]:
			var offer := MarketOffer.new()
			offer.market_id = &"1x2"
			offer.match_id = &"match_test"
			offer.option_key = option_key
			offer.confidence = CONFIDENCE_BY_MARKET[&"1x2"]
			offer.displayed_probability_min = 0.1
			offer.displayed_probability_max = 0.2
			offers.append(offer)

		var result: Dictionary = CrazyBetResolver.select_restricted_markets(offers, rng)
		var allowed: Array = result["allowed"]
		var excluded: StringName = result["excluded"]

		if allowed.is_empty():
			failures.append("seed=%d: allowed_market_ids quedó vacío con 1 solo mercado distinto disponible" % seed_value)
		if not allowed.has(&"1x2"):
			failures.append("seed=%d: el único mercado disponible (1x2) no quedó en allowed (allowed=%s)" % [seed_value, allowed])
		if excluded != &"":
			failures.append("seed=%d: excluded_market_id esperado vacío, obtenido '%s'" % [seed_value, excluded])
