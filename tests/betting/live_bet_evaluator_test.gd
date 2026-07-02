extends SceneTree
## Test de LiveBetEvaluator (E.8) -- estado vivo tri-estado + ticks restantes hasta resolución. Ver
## .ai-studio/specs/story-e8-boleto-vivo.md sección 2.
##
## Cubre también la consistencia con PendingBetsTracker._is_bet_won (misma tabla de reglas, sin
## duplicar criterios -- la resolución final debe coincidir siempre con evaluate() == WINNING).
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/betting/live_bet_evaluator_test.gd

const FINAL_TICK_INDEX: int = 5   # LeagueRules.TICKS_PER_MATCH - 1


func _init() -> void:
	var failures: Array[String] = []

	_test_1x2_reflects_current_leader(failures)
	_test_1x2_draw(failures)
	_test_monotonic_market_undecided_mid_match(failures)
	_test_monotonic_market_locked_once_condition_true(failures)
	_test_monotonic_market_locked_at_final_tick_without_condition(failures)
	_test_first_scorer_undecided_before_any_goal(failures)
	_test_first_scorer_locked_after_goal(failures)
	_test_first_scorer_all_lose_if_no_goal_by_final_tick(failures)
	_test_ticks_until_resolution_counts_down(failures)
	_test_ticks_until_resolution_zero_when_resolved(failures)
	_test_is_bet_won_consistent_with_evaluate(failures)

	if failures.is_empty():
		print("[PASS] live_bet_evaluator_test: todos los checks OK")
	else:
		push_error("[FAIL] live_bet_evaluator_test: %d fallo(s)" % failures.size())
		for failure in failures:
			push_error("  - " + failure)

	quit(0 if failures.is_empty() else 1)


func _build_match_state(tick_index: int, home_goals: int, away_goals: int) -> MatchTickState:
	var state := MatchTickState.new()
	state.match_id = &"match_test"
	state.current_tick_index = tick_index
	state.current_minute = tick_index * LeagueRules.MATCH_MINUTES_PER_TICK
	state.home_goals = home_goals
	state.away_goals = away_goals
	return state


func _build_offer(market_id: StringName, option_key: StringName, threshold: float = -1.0) -> MarketOffer:
	var offer := MarketOffer.new()
	offer.market_id = market_id
	offer.match_id = &"match_test"
	offer.option_key = option_key
	offer.threshold_display = threshold
	offer.displayed_probability_min = 0.3
	offer.displayed_probability_max = 0.5
	return offer


func _test_1x2_reflects_current_leader(failures: Array[String]) -> void:
	var state := _build_match_state(2, 2, 0)  # home leading, partido en curso
	var home_offer := _build_offer(&"1x2", &"home")
	var away_offer := _build_offer(&"1x2", &"away")
	var draw_offer := _build_offer(&"1x2", &"draw")

	if LiveBetEvaluator.evaluate(home_offer, state) != LiveBetEvaluator.LiveStatus.WINNING:
		failures.append("1x2 'home' con home_goals=2 > away_goals=0 debería ser WINNING")
	if LiveBetEvaluator.evaluate(away_offer, state) != LiveBetEvaluator.LiveStatus.LOSING:
		failures.append("1x2 'away' con home_goals=2 > away_goals=0 debería ser LOSING")
	if LiveBetEvaluator.evaluate(draw_offer, state) != LiveBetEvaluator.LiveStatus.LOSING:
		failures.append("1x2 'draw' con home_goals=2 > away_goals=0 debería ser LOSING")


func _test_1x2_draw(failures: Array[String]) -> void:
	var state := _build_match_state(2, 1, 1)
	var draw_offer := _build_offer(&"1x2", &"draw")
	if LiveBetEvaluator.evaluate(draw_offer, state) != LiveBetEvaluator.LiveStatus.WINNING:
		failures.append("1x2 'draw' con marcador empatado en curso debería ser WINNING")


## btts con 0-0 en curso -- ejemplo explícito de la spec de UNDECIDED (sección 2).
func _test_monotonic_market_undecided_mid_match(failures: Array[String]) -> void:
	var state := _build_match_state(2, 0, 0)
	var over_offer := _build_offer(&"btts", &"over")
	var under_offer := _build_offer(&"btts", &"under")

	if LiveBetEvaluator.evaluate(over_offer, state) != LiveBetEvaluator.LiveStatus.UNDECIDED:
		failures.append("btts 'over' (ambos anotan) con 0-0 en curso debería ser UNDECIDED")
	if LiveBetEvaluator.evaluate(under_offer, state) != LiveBetEvaluator.LiveStatus.UNDECIDED:
		failures.append("btts 'under' con 0-0 en curso debería ser UNDECIDED")

	# over/under de goles con margen todavía alcanzable.
	var goals_offer_over := _build_offer(&"goals_ou_2_5", &"over", 2.5)
	var state_goals := _build_match_state(3, 1, 1)  # 2 goles totales, aún no supera 2.5
	if LiveBetEvaluator.evaluate(goals_offer_over, state_goals) != LiveBetEvaluator.LiveStatus.UNDECIDED:
		failures.append("goals_ou_2_5 'over' con 2 goles en curso (umbral 2.5, margen alcanzable) debería ser UNDECIDED")


## Una vez la condición monótona ya es verdadera (ej. ya se superó el umbral), queda irreversiblemente
## WINNING para "over" / LOSING para "under", sin esperar al final del partido.
func _test_monotonic_market_locked_once_condition_true(failures: Array[String]) -> void:
	var offer_over := _build_offer(&"goals_ou_2_5", &"over", 2.5)
	var offer_under := _build_offer(&"goals_ou_2_5", &"under", 2.5)
	var state := _build_match_state(3, 2, 1)  # 3 goles totales, ya supera 2.5, partido en curso

	if LiveBetEvaluator.evaluate(offer_over, state) != LiveBetEvaluator.LiveStatus.WINNING:
		failures.append("goals_ou_2_5 'over' con 3 goles ya marcados (umbral 2.5) debería ser WINNING de forma irreversible")
	if LiveBetEvaluator.evaluate(offer_under, state) != LiveBetEvaluator.LiveStatus.LOSING:
		failures.append("goals_ou_2_5 'under' con 3 goles ya marcados (umbral 2.5) debería ser LOSING de forma irreversible")

	var both_scored_offer := _build_offer(&"btts", &"over")
	var state_both_scored := _build_match_state(2, 1, 1)
	if LiveBetEvaluator.evaluate(both_scored_offer, state_both_scored) != LiveBetEvaluator.LiveStatus.WINNING:
		failures.append("btts 'over' en cuanto ambos ya anotaron debería ser WINNING de forma irreversible, aunque el partido siga en curso")


## Si el partido termina sin que la condición monótona se cumpliera, "under"/"no" gana.
func _test_monotonic_market_locked_at_final_tick_without_condition(failures: Array[String]) -> void:
	var offer_over := _build_offer(&"goals_ou_2_5", &"over", 2.5)
	var offer_under := _build_offer(&"goals_ou_2_5", &"under", 2.5)
	var state := _build_match_state(FINAL_TICK_INDEX, 1, 0)  # 1 gol total al final, nunca superó 2.5

	if LiveBetEvaluator.evaluate(offer_over, state) != LiveBetEvaluator.LiveStatus.LOSING:
		failures.append("goals_ou_2_5 'over' al final del partido sin superar el umbral debería ser LOSING")
	if LiveBetEvaluator.evaluate(offer_under, state) != LiveBetEvaluator.LiveStatus.WINNING:
		failures.append("goals_ou_2_5 'under' al final del partido sin superar el umbral debería ser WINNING")


func _test_first_scorer_undecided_before_any_goal(failures: Array[String]) -> void:
	var offer := _build_offer(&"first_scorer", &"p1")
	var state := _build_match_state(2, 0, 0)
	if LiveBetEvaluator.evaluate(offer, state) != LiveBetEvaluator.LiveStatus.UNDECIDED:
		failures.append("first_scorer antes de cualquier gol, partido en curso, debería ser UNDECIDED")


func _test_first_scorer_locked_after_goal(failures: Array[String]) -> void:
	var state := _build_match_state(2, 1, 0)
	state.goal_scorers = [&"p1"]
	var offer_p1 := _build_offer(&"first_scorer", &"p1")
	var offer_p2 := _build_offer(&"first_scorer", &"p2")

	if LiveBetEvaluator.evaluate(offer_p1, state) != LiveBetEvaluator.LiveStatus.WINNING:
		failures.append("first_scorer 'p1' tras marcar el primer gol debería ser WINNING")
	if LiveBetEvaluator.evaluate(offer_p2, state) != LiveBetEvaluator.LiveStatus.LOSING:
		failures.append("first_scorer 'p2' tras marcar p1 el primer gol debería ser LOSING")


func _test_first_scorer_all_lose_if_no_goal_by_final_tick(failures: Array[String]) -> void:
	var offer := _build_offer(&"first_scorer", &"p1")
	var state := _build_match_state(FINAL_TICK_INDEX, 0, 0)
	if LiveBetEvaluator.evaluate(offer, state) != LiveBetEvaluator.LiveStatus.LOSING:
		failures.append("first_scorer al final del partido sin ningún gol marcado debería ser LOSING")


func _test_ticks_until_resolution_counts_down(failures: Array[String]) -> void:
	var offer := _build_offer(&"goals_ou_2_5", &"over", 2.5)
	var state := _build_match_state(2, 0, 0)
	var ticks_left: int = LiveBetEvaluator.ticks_until_resolution(offer, state)
	var expected: int = FINAL_TICK_INDEX - 2
	if ticks_left != expected:
		failures.append("ticks_until_resolution en tick_index=2 esperado %d, obtenido %d" % [expected, ticks_left])


func _test_ticks_until_resolution_zero_when_resolved(failures: Array[String]) -> void:
	var offer := _build_offer(&"goals_ou_2_5", &"over", 2.5)
	var state_final := _build_match_state(FINAL_TICK_INDEX, 1, 1)
	if LiveBetEvaluator.ticks_until_resolution(offer, state_final) != 0:
		failures.append("ticks_until_resolution en el tick final debería ser 0")

	var first_scorer_offer := _build_offer(&"first_scorer", &"p1")
	var state_goal_scored := _build_match_state(1, 1, 0)
	state_goal_scored.goal_scorers = [&"p1"]
	if LiveBetEvaluator.ticks_until_resolution(first_scorer_offer, state_goal_scored) != 0:
		failures.append("ticks_until_resolution de first_scorer tras el primer gol debería ser 0 (se resuelve este tick)")


## PendingBetsTracker._is_bet_won solo se invoca cuando is_market_resolved_this_tick ya dio true --
## en ese punto, evaluate() nunca debería devolver UNDECIDED, y _is_bet_won debe coincidir exactamente
## con evaluate() == WINNING (misma tabla de reglas, sin duplicar criterios).
func _test_is_bet_won_consistent_with_evaluate(failures: Array[String]) -> void:
	var tracker := PendingBetsTracker.new()

	var cases: Array[Dictionary] = [
		{"offer": _build_offer(&"1x2", &"home"), "state": _build_match_state(FINAL_TICK_INDEX, 2, 1)},
		{"offer": _build_offer(&"1x2", &"draw"), "state": _build_match_state(FINAL_TICK_INDEX, 1, 1)},
		{"offer": _build_offer(&"btts", &"over"), "state": _build_match_state(FINAL_TICK_INDEX, 1, 1)},
		{"offer": _build_offer(&"btts", &"under"), "state": _build_match_state(FINAL_TICK_INDEX, 0, 0)},
		{"offer": _build_offer(&"goals_ou_2_5", &"over", 2.5), "state": _build_match_state(FINAL_TICK_INDEX, 2, 1)},
		{"offer": _build_offer(&"goals_ou_2_5", &"under", 2.5), "state": _build_match_state(FINAL_TICK_INDEX, 1, 0)},
	]

	var first_scorer_state := _build_match_state(2, 1, 0)
	first_scorer_state.goal_scorers = [&"p1"]
	cases.append({"offer": _build_offer(&"first_scorer", &"p1"), "state": first_scorer_state})
	cases.append({"offer": _build_offer(&"first_scorer", &"p2"), "state": first_scorer_state})

	for test_case in cases:
		var offer: MarketOffer = test_case["offer"]
		var state: MatchTickState = test_case["state"]
		var status: LiveBetEvaluator.LiveStatus = LiveBetEvaluator.evaluate(offer, state)

		if status == LiveBetEvaluator.LiveStatus.UNDECIDED:
			failures.append("market_id=%s option_key=%s: evaluate() no debería ser UNDECIDED cuando el mercado ya está resuelto" % [offer.market_id, offer.option_key])
			continue

		var won: bool = tracker._is_bet_won(offer, state)
		var expected_won: bool = status == LiveBetEvaluator.LiveStatus.WINNING
		if won != expected_won:
			failures.append("market_id=%s option_key=%s: _is_bet_won()=%s no coincide con evaluate()==WINNING (%s)" % [offer.market_id, offer.option_key, won, expected_won])
