class_name LiveBetEvaluator extends RefCounted
## Estado vivo tri-estado de una apuesta pendiente, evaluado contra el `MatchTickState` actual
## (parcial o final) de su partido. Ver .ai-studio/specs/story-e8-boleto-vivo.md sección 2.
##
## Comparte la tabla de reglas por `market_id` con `PendingBetsTracker._is_bet_won` (resolución
## final): `_is_bet_won` delega en `evaluate()` para no duplicar criterios -- ver nota en
## pending_bets_tracker.gd.

enum LiveStatus { WINNING, LOSING, UNDECIDED }


## Estado vivo de una apuesta contra el estado actual (parcial o final) del partido.
static func evaluate(market_offer: MarketOffer, match_state: MatchTickState) -> LiveStatus:
	var market_id: StringName = market_offer.market_id
	var option_key: String = String(market_offer.option_key)
	var is_final: bool = _is_match_finished(match_state)

	if market_id == &"1x2":
		return _evaluate_1x2(option_key, match_state)

	if market_id == &"btts":
		var both_scored: bool = match_state.home_goals > 0 and match_state.away_goals > 0
		return _evaluate_monotonic_condition(option_key, both_scored, is_final)

	if market_id == &"goals_ou_1_5" or market_id == &"goals_ou_2_5" or market_id == &"goals_ou_3_5":
		var total_goals: int = match_state.home_goals + match_state.away_goals
		var over: bool = float(total_goals) > market_offer.threshold_display
		return _evaluate_monotonic_condition(option_key, over, is_final)

	if market_id == &"cards_ou":
		var total_cards: int = match_state.cards_home + match_state.cards_away
		var over: bool = float(total_cards) > market_offer.threshold_display
		return _evaluate_monotonic_condition(option_key, over, is_final)

	if market_id == &"fouls_ou":
		var total_fouls: int = match_state.fouls_home + match_state.fouls_away
		var over: bool = float(total_fouls) > market_offer.threshold_display
		return _evaluate_monotonic_condition(option_key, over, is_final)

	if market_id == &"first_scorer":
		return _evaluate_first_scorer(option_key, match_state)

	return LiveStatus.LOSING


## Ticks restantes hasta la resolución de este mercado (0 = se resuelve este tick). first_scorer se
## cierra al primer gol; el resto al minuto 90 -- misma condición que
## `PendingBetsTracker.is_market_resolved_this_tick`, reutilizada aquí para no duplicar el criterio de
## cierre.
static func ticks_until_resolution(market_offer: MarketOffer, match_state: MatchTickState) -> int:
	if PendingBetsTracker.is_market_resolved_this_tick(market_offer.market_id, match_state):
		return 0
	return (LeagueRules.TICKS_PER_MATCH - 1) - match_state.current_tick_index


static func _is_match_finished(match_state: MatchTickState) -> bool:
	return match_state.current_tick_index == LeagueRules.TICKS_PER_MATCH - 1


static func _evaluate_1x2(option_key: String, match_state: MatchTickState) -> LiveStatus:
	var current_leader: String
	if match_state.home_goals > match_state.away_goals:
		current_leader = "home"
	elif match_state.home_goals < match_state.away_goals:
		current_leader = "away"
	else:
		current_leader = "draw"
	return LiveStatus.WINNING if option_key == current_leader else LiveStatus.LOSING


## Condición monótona (solo puede pasar de falsa a verdadera dentro de un mismo partido -- goles,
## tarjetas y faltas solo se acumulan, "ambos anotan" solo puede pasar de no cumplido a cumplido).
## "over" gana en cuanto la condición ya es verdadera (irreversible, ya no puede "des-cumplirse").
## Mientras la condición siga siendo falsa y el partido no haya terminado, el resultado aún puede caer
## a ambos lados -> UNDECIDED. Al terminar el partido sin que la condición se cumpliera, "under" gana.
static func _evaluate_monotonic_condition(option_key: String, condition_true: bool, is_final: bool) -> LiveStatus:
	var wants_true: bool = option_key == "over"
	if condition_true:
		return LiveStatus.WINNING if wants_true else LiveStatus.LOSING
	if is_final:
		return LiveStatus.LOSING if wants_true else LiveStatus.WINNING
	return LiveStatus.UNDECIDED


## first_scorer se cierra en cuanto se marca el primer gol (irreversible) o al final del partido si
## nunca se marcó ningún gol (todas las opciones pierden).
static func _evaluate_first_scorer(option_key: String, match_state: MatchTickState) -> LiveStatus:
	if match_state.goal_scorers.is_empty():
		return LiveStatus.LOSING if _is_match_finished(match_state) else LiveStatus.UNDECIDED
	return LiveStatus.WINNING if String(match_state.goal_scorers[0]) == option_key else LiveStatus.LOSING
