extends SceneTree
## Test de LiveBetTicket (E.8) -- ticket por PendingBet con cuota fijada (OddsMath), ganancia
## potencial, estado vivo (LiveBetEvaluator) y cuánto falta para su resolución. Ver
## .ai-studio/specs/story-e8-boleto-vivo.md sección 3.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/betting/live_bet_ticket_test.gd

const LIVE_BET_TICKET_SCENE: PackedScene = preload("res://scenes/betting/live_bet_ticket.tscn")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	_test_setup_shows_stake_odds_and_payout()
	_test_refresh_live_state_shows_winning_status_and_ticks_left()
	_test_refresh_live_state_shows_undecided_status()
	_test_get_match_id_returns_pending_bet_match_id()

	_finish()


func _build_pending_bet(market_id: StringName, option_key: StringName, stake: int, threshold: float = -1.0) -> PendingBet:
	var offer := MarketOffer.new()
	offer.market_id = market_id
	offer.match_id = &"match_test"
	offer.option_key = option_key
	offer.threshold_display = threshold
	offer.displayed_probability_min = 0.3
	offer.displayed_probability_max = 0.5

	var pending_bet := PendingBet.new()
	pending_bet.match_id = &"match_test"
	pending_bet.market_offer = offer
	pending_bet.stake = stake
	pending_bet.tick_index_placed = 0
	return pending_bet


func _test_setup_shows_stake_odds_and_payout() -> void:
	var ticket: LiveBetTicket = LIVE_BET_TICKET_SCENE.instantiate()
	root.add_child(ticket)

	var pending_bet: PendingBet = _build_pending_bet(&"goals_ou_2_5", &"over", 100, 2.5)
	ticket.setup(pending_bet, "Equipo A vs Equipo B")

	var odds_range: Vector2 = OddsMath.odds_range_from_probability_range(pending_bet.market_offer.displayed_probability_min, pending_bet.market_offer.displayed_probability_max)
	var odds_center: float = (odds_range.x + odds_range.y) / 2.0
	var expected_payout: int = OddsMath.potential_return(pending_bet.stake, odds_center)

	if not ticket._stake_label.text.contains(str(pending_bet.stake)):
		_fail("StakeLabel debería incluir el importe apostado ($%d), texto=%s" % [pending_bet.stake, ticket._stake_label.text])
	if not ticket._stake_label.text.contains(str(expected_payout)):
		_fail("StakeLabel debería incluir la ganancia potencial ($%d), texto=%s" % [expected_payout, ticket._stake_label.text])
	if ticket._match_label.text != "Equipo A vs Equipo B":
		_fail("MatchLabel debería mostrar el partido pasado a setup(), texto=%s" % ticket._match_label.text)

	ticket.queue_free()


func _test_refresh_live_state_shows_winning_status_and_ticks_left() -> void:
	var ticket: LiveBetTicket = LIVE_BET_TICKET_SCENE.instantiate()
	root.add_child(ticket)

	var pending_bet: PendingBet = _build_pending_bet(&"goals_ou_2_5", &"over", 100, 2.5)
	ticket.setup(pending_bet, "Equipo A vs Equipo B")

	var match_state := MatchTickState.new()
	match_state.match_id = &"match_test"
	match_state.current_tick_index = 3
	match_state.current_minute = 45
	match_state.home_goals = 2
	match_state.away_goals = 1  # 3 goles > 2.5 -> ya ganando de forma irreversible

	ticket.refresh_live_state(match_state)

	if ticket._status_badge.text != "vas ganando esta":
		_fail("StatusBadge esperado 'vas ganando esta', obtenido '%s'" % ticket._status_badge.text)

	var expected_minute: int = match_state.current_minute + (LeagueRules.TICKS_PER_MATCH - 1 - match_state.current_tick_index) * LeagueRules.MATCH_MINUTES_PER_TICK
	if not ticket._resolution_label.text.contains(str(expected_minute)):
		_fail("ResolutionLabel debería mencionar el minuto de cierre %d, texto=%s" % [expected_minute, ticket._resolution_label.text])

	ticket.queue_free()


func _test_refresh_live_state_shows_undecided_status() -> void:
	var ticket: LiveBetTicket = LIVE_BET_TICKET_SCENE.instantiate()
	root.add_child(ticket)

	var pending_bet: PendingBet = _build_pending_bet(&"btts", &"over", 50)

	ticket.setup(pending_bet, "Equipo A vs Equipo B")

	var match_state := MatchTickState.new()
	match_state.match_id = &"match_test"
	match_state.current_tick_index = 1
	match_state.current_minute = 15
	match_state.home_goals = 0
	match_state.away_goals = 0

	ticket.refresh_live_state(match_state)

	if ticket._status_badge.text != "aún indeciso":
		_fail("StatusBadge esperado 'aún indeciso' con btts 0-0 en curso, obtenido '%s'" % ticket._status_badge.text)

	ticket.queue_free()


func _test_get_match_id_returns_pending_bet_match_id() -> void:
	var ticket: LiveBetTicket = LIVE_BET_TICKET_SCENE.instantiate()
	root.add_child(ticket)

	var pending_bet: PendingBet = _build_pending_bet(&"1x2", &"home", 20)
	ticket.setup(pending_bet, "Equipo A vs Equipo B")

	if ticket.get_match_id() != &"match_test":
		_fail("get_match_id() esperado 'match_test', obtenido '%s'" % ticket.get_match_id())

	ticket.queue_free()


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] live_bet_ticket_test: todos los checks OK")
	else:
		push_error("[FAIL] live_bet_ticket_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)
