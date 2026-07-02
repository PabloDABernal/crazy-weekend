class_name PendingBetsTracker extends Node
## Único lugar que sabe "qué apostó el jugador en qué tick de qué partido todavía sin resolver".
## Nodo de escena (no autoload), hijo de BettingRoot — vive solo durante una run. Invoca
## MarketBetResultBuilder.build_result(...) (Épica D) al resolverse un tick y emite
## EventBus.market_bet_resolved (contrato que Épica A ya consume).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 4.

signal pending_bets_changed(pending: Array[PendingBet])
## Señal propia de la UI de apuestas (E.8), no cruza épicas -- distinta de
## EventBus.market_bet_resolved (contrato de Épica A, que no lleva importe). Consumida por
## BettingRoot para disparar el feedback enérgico de resolución.
## payout = dinero acreditado (0 si perdida). El stake vive en pending_bet.stake.
## Ver .ai-studio/specs/story-e8-boleto-vivo.md sección 4.
signal bet_resolved(pending_bet: PendingBet, won: bool, payout: int)

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

	var payout: int = 0
	if won:
		payout = PayoutCalculator.compute_payout(pending_bet)
		RunState.set_money(RunState.get_money() + payout, "bet_resolved")

	EventBus.market_bet_resolved.emit(result)
	bet_resolved.emit(pending_bet, won, payout)


## Deriva si la opción apostada resultó ganadora, comparando market_offer.option_key contra el
## resultado real ya contenido en match_state. Se asume match_state en su estado FINAL (minuto 90)
## para todos los mercados salvo first_scorer (que puede resolverse antes, ver is_market_resolved_this_tick).
## Delega en LiveBetEvaluator.evaluate (E.8) -- misma tabla de reglas que el estado vivo, para no
## duplicar criterios (ver .ai-studio/specs/story-e8-boleto-vivo.md sección 2). Como esta función solo
## se invoca cuando is_market_resolved_this_tick ya dio true, el match_state pasado siempre corresponde
## a un estado ya decidible para ese market_id, así que evaluate() nunca devuelve UNDECIDED aquí.
func _is_bet_won(market_offer: MarketOffer, match_state: MatchTickState) -> bool:
	return LiveBetEvaluator.evaluate(market_offer, match_state) == LiveBetEvaluator.LiveStatus.WINNING
