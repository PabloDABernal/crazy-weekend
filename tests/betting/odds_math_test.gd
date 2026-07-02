extends SceneTree
## Test de OddsMath (E.7) -- fuente única de verdad de la aritmética de cuota/payout comercial. Ver
## .ai-studio/specs/story-e7-cuota-ganancia-potencial.md sección 2.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/betting/odds_math_test.gd

func _init() -> void:
	var failures: Array[String] = []

	_test_odds_from_probability_basic(failures)
	_test_odds_from_probability_clamps_min_p(failures)
	_test_odds_range_from_probability_range_orders_min_max(failures)
	_test_odds_range_collapses_when_probability_fixed(failures)
	_test_potential_return_rounds_up(failures)
	_test_potential_net_is_return_minus_stake(failures)
	_test_payout_calculator_matches_odds_math(failures)

	if failures.is_empty():
		print("[PASS] odds_math_test: todos los checks OK")
	else:
		push_error("[FAIL] odds_math_test: %d fallo(s)" % failures.size())
		for failure in failures:
			push_error("  - " + failure)

	quit(0 if failures.is_empty() else 1)


func _test_odds_from_probability_basic(failures: Array[String]) -> void:
	var odds: float = OddsMath.odds_from_probability(0.5)
	if not is_equal_approx(odds, 2.0):
		failures.append("odds_from_probability(0.5) esperado 2.0, obtenido %f" % odds)

	var odds_quarter: float = OddsMath.odds_from_probability(0.25)
	if not is_equal_approx(odds_quarter, 4.0):
		failures.append("odds_from_probability(0.25) esperado 4.0, obtenido %f" % odds_quarter)


func _test_odds_from_probability_clamps_min_p(failures: Array[String]) -> void:
	var odds: float = OddsMath.odds_from_probability(0.0)
	if not is_equal_approx(odds, 100.0):
		failures.append("odds_from_probability(0.0) esperado clamp a MIN_P=0.01 -> 100.0, obtenido %f" % odds)

	var odds_negative: float = OddsMath.odds_from_probability(-0.5)
	if not is_equal_approx(odds_negative, 100.0):
		failures.append("odds_from_probability(-0.5) esperado clamp a MIN_P=0.01 -> 100.0, obtenido %f" % odds_negative)


## Menor probabilidad => mayor cuota: el mínimo de cuota se deriva del máximo de probabilidad y
## viceversa (sección 2 de la spec).
func _test_odds_range_from_probability_range_orders_min_max(failures: Array[String]) -> void:
	var odds_range: Vector2 = OddsMath.odds_range_from_probability_range(0.3, 0.5)
	var expected_min: float = 1.0 / 0.5
	var expected_max: float = 1.0 / 0.3

	if not is_equal_approx(odds_range.x, expected_min):
		failures.append("odds_range.x esperado %f, obtenido %f" % [expected_min, odds_range.x])
	if not is_equal_approx(odds_range.y, expected_max):
		failures.append("odds_range.y esperado %f, obtenido %f" % [expected_max, odds_range.y])
	if odds_range.x > odds_range.y:
		failures.append("odds_range.x (%f) no debería ser mayor que odds_range.y (%f)" % [odds_range.x, odds_range.y])


func _test_odds_range_collapses_when_probability_fixed(failures: Array[String]) -> void:
	var odds_range: Vector2 = OddsMath.odds_range_from_probability_range(0.4, 0.4)
	if not is_equal_approx(odds_range.x, odds_range.y):
		failures.append("con p_min == p_max el rango de cuota debería colapsar, obtenido (%f, %f)" % [odds_range.x, odds_range.y])


func _test_potential_return_rounds_up(failures: Array[String]) -> void:
	var payout_exact: int = OddsMath.potential_return(100, 2.1)
	if payout_exact != 210:
		failures.append("potential_return(100, 2.1) esperado 210, obtenido %d" % payout_exact)

	var payout_fractional: int = OddsMath.potential_return(33, 1.5)  # 49.5 -> ceil 50
	if payout_fractional != 50:
		failures.append("potential_return(33, 1.5) esperado 50 (ceil de 49.5), obtenido %d" % payout_fractional)


func _test_potential_net_is_return_minus_stake(failures: Array[String]) -> void:
	var stake: int = 100
	var odds: float = 2.1
	var expected_net: int = OddsMath.potential_return(stake, odds) - stake
	var net: int = OddsMath.potential_net(stake, odds)
	if net != expected_net:
		failures.append("potential_net(100, 2.1) esperado %d, obtenido %d" % [expected_net, net])


## Regresión directa de la sección 2 de la spec: la cuota mostrada al apostar y la usada al pagar
## deben ser idénticas por construcción, ambas derivadas de OddsMath.
func _test_payout_calculator_matches_odds_math(failures: Array[String]) -> void:
	var offer := MarketOffer.new()
	offer.market_id = &"1x2"
	offer.match_id = &"match_test"
	offer.option_key = &"home"
	offer.displayed_probability_min = 0.3
	offer.displayed_probability_max = 0.5

	var pending_bet := PendingBet.new()
	pending_bet.match_id = &"match_test"
	pending_bet.market_offer = offer
	pending_bet.stake = 150

	var shown_center: float = (offer.displayed_probability_min + offer.displayed_probability_max) / 2.0
	var expected_payout: int = OddsMath.potential_return(pending_bet.stake, OddsMath.odds_from_probability(shown_center))

	var payout: int = PayoutCalculator.compute_payout(pending_bet)
	if payout != expected_payout:
		failures.append("PayoutCalculator.compute_payout esperado %d (vía OddsMath), obtenido %d" % [expected_payout, payout])
