class_name PendingBetsTracker extends Node
## Único lugar que sabe "qué apostó el jugador en qué tick de qué partido todavía sin resolver".
## Nodo de escena (no autoload), hijo de BettingRoot — vive solo durante una run. Invoca
## MarketBetResultBuilder.build_result(...) (Épica D) al resolverse un tick y emite
## EventBus.market_bet_resolved (contrato que Épica A ya consume).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 4.

signal pending_bets_changed(pending: Array[PendingBet])

var _pending: Array[PendingBet] = []


## Invocado por MatchPanel (vía BettingRoot) al confirmar una apuesta.
func register_bet(match_id: StringName, market_offer: MarketOffer, stake: int, tick_index: int) -> void:
	RunState.set_money(RunState.get_money() - stake, "bet_placed")

	var pending_bet := PendingBet.new()
	pending_bet.match_id = match_id
	pending_bet.market_offer = market_offer
	pending_bet.stake = stake
	pending_bet.tick_index_placed = tick_index
	_pending.append(pending_bet)

	pending_bets_changed.emit(_pending)


## Invocado por BettingRoot tras cada MatchSimulationService.advance_tick() ya resuelto, una vez por
## partido cuyo tick avanzó. Evalúa TODAS las PendingBet pendientes de este match_id (no solo las del
## tick recién colocado) contra la condición de resolución de su propio market_id -- ver sección 4.3
## de la spec (first_scorer se resuelve al primer gol, el resto solo al minuto 90).
func resolve_bets_for_match(match_id: StringName, match_state: MatchTickState, matchday_id: StringName) -> void:
	var still_pending: Array[PendingBet] = []
	var changed: bool = false

	for pending_bet in _pending:
		if pending_bet.match_id != match_id:
			still_pending.append(pending_bet)
			continue

		if not is_market_resolved_this_tick(pending_bet.market_offer.market_id, match_state):
			still_pending.append(pending_bet)
			continue

		_resolve_single_bet(pending_bet, match_state, matchday_id)
		changed = true

	_pending = still_pending
	if changed:
		pending_bets_changed.emit(_pending)


func get_pending_bets() -> Array[PendingBet]:
	return _pending


## Reemplaza la lógica simplificada de "resolver el tick recién cerrado": por cada PendingBet
## pendiente de un match_id, comprueba si su market_id ya tiene condición de cierre cumplida en el
## match_state actual. Ver sección 4.3 de la spec.
static func is_market_resolved_this_tick(market_id: StringName, match_state: MatchTickState) -> bool:
	if market_id == &"first_scorer":
		return not match_state.goal_scorers.is_empty() or match_state.current_tick_index == LeagueRules.TICKS_PER_MATCH - 1
	# el resto de mercados: solo se resuelven al llegar al minuto 90 (último tick del partido).
	return match_state.current_tick_index == LeagueRules.TICKS_PER_MATCH - 1


func _resolve_single_bet(pending_bet: PendingBet, match_state: MatchTickState, matchday_id: StringName) -> void:
	var won: bool = _is_bet_won(pending_bet.market_offer, match_state)
	var result: MarketBetResult = MarketBetResultBuilder.build_result(
		pending_bet.market_offer, won, match_state, matchday_id, RunState.run_number,
	)

	if won:
		var payout: int = PayoutCalculator.compute_payout(pending_bet)
		RunState.set_money(RunState.get_money() + payout, "bet_resolved")

	EventBus.market_bet_resolved.emit(result)


## Deriva si la opción apostada resultó ganadora, comparando market_offer.option_key contra el
## resultado real ya contenido en match_state. Se asume match_state en su estado FINAL (minuto 90)
## para todos los mercados salvo first_scorer (que puede resolverse antes, ver is_market_resolved_this_tick).
func _is_bet_won(market_offer: MarketOffer, match_state: MatchTickState) -> bool:
	var market_id: StringName = market_offer.market_id
	var option_key: String = String(market_offer.option_key)

	if market_id == &"1x2":
		if match_state.home_goals > match_state.away_goals:
			return option_key == "home"
		elif match_state.home_goals < match_state.away_goals:
			return option_key == "away"
		else:
			return option_key == "draw"

	if market_id == &"btts":
		var both_scored: bool = match_state.home_goals > 0 and match_state.away_goals > 0
		if option_key == "over":
			return both_scored
		else:
			return not both_scored

	if market_id == &"goals_ou_1_5" or market_id == &"goals_ou_2_5" or market_id == &"goals_ou_3_5":
		var total_goals: int = match_state.home_goals + match_state.away_goals
		var over: bool = float(total_goals) > market_offer.threshold_display
		if option_key == "over":
			return over
		else:
			return not over

	if market_id == &"cards_ou":
		var total_cards: int = match_state.cards_home + match_state.cards_away
		var over: bool = float(total_cards) > market_offer.threshold_display
		if option_key == "over":
			return over
		else:
			return not over

	if market_id == &"fouls_ou":
		var total_fouls: int = match_state.fouls_home + match_state.fouls_away
		var over: bool = float(total_fouls) > market_offer.threshold_display
		if option_key == "over":
			return over
		else:
			return not over

	if market_id == &"first_scorer":
		if match_state.goal_scorers.is_empty():
			return false
		return String(match_state.goal_scorers[0]) == option_key

	return false
