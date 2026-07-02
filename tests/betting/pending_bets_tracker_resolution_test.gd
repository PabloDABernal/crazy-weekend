extends SceneTree
## Test de PendingBetsTracker.bet_resolved (E.8) -- señal propia de la UI de apuestas que expone
## pending_bet, won y payout para el feedback de resolución (ResolutionFeedbackOverlay). Ver
## .ai-studio/specs/story-e8-boleto-vivo.md sección 4.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/betting/pending_bets_tracker_resolution_test.gd

var _failures: Array[String] = []
var _resolved_events: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	LeagueState.generate_new_league(1, 42)
	RunState.start_new_run()

	var tracker := PendingBetsTracker.new()
	tracker.bet_resolved.connect(_on_bet_resolved)

	_test_winning_bet_emits_positive_payout(tracker)
	_test_losing_bet_emits_zero_payout(tracker)

	_finish()


## Usa goals_ou_2_5 (no 1x2/fouls_ou) para no depender de LeagueState/OddsEngine en
## MarketBetResultBuilder._compute_context_tags -- ver market_bet_result_builder.gd.
func _test_winning_bet_emits_positive_payout(tracker: PendingBetsTracker) -> void:
	_resolved_events.clear()

	var offer := MarketOffer.new()
	offer.market_id = &"goals_ou_2_5"
	offer.match_id = &"match_win"
	offer.option_key = &"over"
	offer.threshold_display = 2.5
	offer.displayed_probability_min = 0.3
	offer.displayed_probability_max = 0.5

	tracker.register_bet(&"match_win", offer, 100, 0)

	var match_state := MatchTickState.new()
	match_state.match_id = &"match_win"
	match_state.current_tick_index = LeagueRules.TICKS_PER_MATCH - 1
	match_state.home_goals = 2
	match_state.away_goals = 1  # 3 goles totales > 2.5 -> "over" gana

	tracker.resolve_bets_for_match(&"match_win", match_state, &"matchday_1")

	if _resolved_events.size() != 1:
		_fail("se esperaba exactamente 1 emisión de bet_resolved para la apuesta ganada, obtenidas %d" % _resolved_events.size())
		return

	var event: Dictionary = _resolved_events[0]
	if not event["won"]:
		_fail("bet_resolved.won debería ser true para una apuesta ganadora")

	var expected_payout: int = OddsMath.potential_return(100, OddsMath.odds_from_probability((offer.displayed_probability_min + offer.displayed_probability_max) / 2.0))
	if event["payout"] != expected_payout:
		_fail("bet_resolved.payout esperado %d, obtenido %d" % [expected_payout, event["payout"]])

	if tracker.get_pending_bets().size() != 0:
		_fail("la apuesta resuelta debería salir de get_pending_bets()")


func _test_losing_bet_emits_zero_payout(tracker: PendingBetsTracker) -> void:
	_resolved_events.clear()

	var offer := MarketOffer.new()
	offer.market_id = &"goals_ou_2_5"
	offer.match_id = &"match_lose"
	offer.option_key = &"over"
	offer.threshold_display = 2.5
	offer.displayed_probability_min = 0.3
	offer.displayed_probability_max = 0.5

	tracker.register_bet(&"match_lose", offer, 50, 0)

	var match_state := MatchTickState.new()
	match_state.match_id = &"match_lose"
	match_state.current_tick_index = LeagueRules.TICKS_PER_MATCH - 1
	match_state.home_goals = 1
	match_state.away_goals = 0  # 1 gol total, no supera 2.5 -> "over" pierde

	tracker.resolve_bets_for_match(&"match_lose", match_state, &"matchday_1")

	if _resolved_events.size() != 1:
		_fail("se esperaba exactamente 1 emisión de bet_resolved para la apuesta perdida, obtenidas %d" % _resolved_events.size())
		return

	var event: Dictionary = _resolved_events[0]
	if event["won"]:
		_fail("bet_resolved.won debería ser false para una apuesta perdida")
	if event["payout"] != 0:
		_fail("bet_resolved.payout esperado 0 para una apuesta perdida, obtenido %d" % event["payout"])


func _on_bet_resolved(pending_bet: PendingBet, won: bool, payout: int) -> void:
	_resolved_events.append({"pending_bet": pending_bet, "won": won, "payout": payout})


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] pending_bets_tracker_resolution_test: todos los checks OK")
	else:
		push_error("[FAIL] pending_bets_tracker_resolution_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)
