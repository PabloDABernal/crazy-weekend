class_name MatchSimulationService extends Node
## Nodo de escena (no autoload) que orquesta la simulación de todos los partidos de una jornada de
## apuestas. Solo tiene sentido mientras hay una jornada en curso: se instancia al entrar a la escena
## de apuestas y se libera (queue_free()) al salir de ella.
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md secciones 1 y 4.4.
##
## No avanza de tick automáticamente por temporizador real: avanza cuando advance_tick() es invocado
## por la UI de apuestas (Épica E), tras validar que el jugador cumplió su apuesta obligatoria del
## tick vigente (regla de B.2/B.3, no de esta épica).

var active_matches: Dictionary = {}   # match_id (StringName) -> MatchTickState
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _current_day: BettingDay.Day = BettingDay.Day.FRIDAY
var _current_matchday: MatchdayFixture = null

## Threshold elegido una vez por partido para cards_ou/fouls_ou (sección 5.4): no cambia tick a tick.
## match_id (StringName) -> { "cards_ou": float, "fouls_ou": float }
var _resolved_variable_thresholds: Dictionary = {}

## MatchTickState.tick_events se reemplaza cada tick (sección 4.1: "no acumula"), así que los
## player_id de jugadores amonestados a lo largo de todo el partido se acumulan aquí tick a tick,
## para poder poblar MatchResult.carded_player_ids completo al finalizar el partido (D.2).
## match_id (StringName) -> Array[StringName] (player_id)
var _carded_players_by_match: Dictionary = {}


func _ready() -> void:
	_rng.randomize()


## Llamado una vez al entrar a la escena de apuestas de una run, con la jornada ya resuelta por
## LeagueState. Instancia un MatchTickState inicial (todo en cero, current_tick_index=0) por cada
## MatchFixture del día.
func start_matchday(matchday: MatchdayFixture, day: BettingDay.Day) -> void:
	_current_matchday = matchday
	_current_day = day
	active_matches = {}
	_resolved_variable_thresholds = {}
	_carded_players_by_match = {}

	for match_fixture in matchday.matches:
		var initial_state := MatchTickState.new()
		initial_state.match_id = match_fixture.match_id
		initial_state.home_team_id = match_fixture.home_team_id
		initial_state.away_team_id = match_fixture.away_team_id
		active_matches[match_fixture.match_id] = initial_state
		_carded_players_by_match[match_fixture.match_id] = []

		_resolved_variable_thresholds[match_fixture.match_id] = _choose_variable_thresholds(
			LeagueState.get_team(match_fixture.home_team_id),
			LeagueState.get_team(match_fixture.away_team_id),
			initial_state,
		)


## Avanza manualmente al siguiente tick de todos los partidos en curso de este día.
func advance_tick() -> void:
	var market_definitions: Array[MarketDef] = MarketCatalog.get_all_market_definitions()

	for match_id in active_matches.keys():
		var previous_state: MatchTickState = active_matches[match_id]
		if previous_state.current_tick_index >= LeagueRules.TICKS_PER_MATCH:
			continue

		var home_team: TeamDef = LeagueState.get_team(previous_state.home_team_id)
		var away_team: TeamDef = LeagueState.get_team(previous_state.away_team_id)

		var new_state: MatchTickState = MatchTickEngine.resolve_tick(previous_state, home_team, away_team, _rng)
		active_matches[match_id] = new_state
		_record_carded_players(match_id, new_state)

		var available_markets: Array[MarketOffer] = _build_market_offers(market_definitions, new_state, home_team, away_team)

		var context := BetTickContext.new()
		context.day = _current_day
		context.tick_index_in_day = new_state.current_tick_index
		context.available_markets = available_markets

		# Orden estricto (fix de integración Épica E): bet_tick_resolved ANTES de bet_tick_opened para
		# este mismo match_id, para que la UI de apuestas resuelva/acredite el payout del tick recién
		# cerrado antes de que RunState (conectado a bet_tick_opened) evalúe StakeResolver.is_run_dead().
		EventBus.bet_tick_resolved.emit(match_id, new_state.current_tick_index)
		EventBus.bet_tick_opened.emit(context)

	if is_matchday_finished():
		_finish_matchday()


## Acumula los player_id amonestados de este tick en _carded_players_by_match, porque
## MatchTickState.tick_events se reemplaza (no acumula) cada tick.
func _record_carded_players(match_id: StringName, state: MatchTickState) -> void:
	var carded_players: Array = _carded_players_by_match.get(match_id, [])
	for event in state.tick_events:
		if event.kind == MatchTickEvent.EventKind.CARD and event.player_id != &"":
			carded_players.append(event.player_id)
	_carded_players_by_match[match_id] = carded_players


## Añadido por Épica E (contrato fijado en epic-e-pantalla-de-apuestas.md sección 3.2): expone el
## MatchTickState acumulado de un partido para que la UI de apuestas pueble marcador/estadísticas sin
## que Épica E necesite conocer active_matches directamente.
func get_match_tick_state(match_id: StringName) -> MatchTickState:
	return active_matches.get(match_id, null)


## Añadido por Épica E (misma sección que get_match_tick_state): arma el TickCommentaryContext del
## tick recién resuelto de un partido para que CommentaryPanel (E) invoque CommentaryResolver (D).
func get_tick_commentary_context(match_id: StringName) -> TickCommentaryContext:
	var state: MatchTickState = active_matches.get(match_id, null)
	if state == null:
		return null

	var home_team: TeamDef = LeagueState.get_team(state.home_team_id)
	var away_team: TeamDef = LeagueState.get_team(state.away_team_id)

	var context := TickCommentaryContext.new()
	context.match_id = state.match_id
	context.tick_index_in_day = state.current_tick_index
	context.phase = NarrativePhase.get_current_phase()
	context.is_crazy_moment = false
	context.events = state.tick_events.duplicate()
	context.score_home = state.home_goals
	context.score_away = state.away_goals
	context.home_team_display_name = home_team.display_name if home_team != null else ""
	context.away_team_display_name = away_team.display_name if away_team != null else ""
	return context


## true si todos los partidos del día ya llegaron al minuto 90.
func is_matchday_finished() -> bool:
	if active_matches.is_empty():
		return false
	for state in active_matches.values():
		if state.current_tick_index < LeagueRules.TICKS_PER_MATCH:
			return false
	return true


## Arma todas las MarketOffer (una por opción apostable) de un partido para este tick, resolviendo
## primero el threshold variable de cards_ou/fouls_ou de este partido en concreto.
func _build_market_offers(market_definitions: Array[MarketDef], state: MatchTickState, home_team: TeamDef, away_team: TeamDef) -> Array[MarketOffer]:
	var offers: Array[MarketOffer] = []
	var thresholds_for_match: Dictionary = _resolved_variable_thresholds.get(state.match_id, {})

	for market_def in market_definitions:
		var effective_market: MarketDef = _resolve_effective_market(market_def, thresholds_for_match)
		var probabilities: Dictionary = OddsEngine.compute_market_probabilities(effective_market, state, home_team, away_team)

		for option_key in probabilities.keys():
			var p_real: float = probabilities[option_key]
			var offer: MarketOffer = OddsDisclosureResolver.build_market_offer(
				effective_market, option_key, p_real, effective_market.base_house_margin,
				state.match_id, NarrativePhase.get_current_phase(), _current_day, _rng,
			)
			offers.append(offer)

	return offers


## cards_ou/fouls_ou no tienen threshold fijo (sección 5.4 de la spec): se construye una copia de
## MarketDef con el threshold ya elegido para este partido, sin tocar las firmas de
## OddsEngine/OddsDisclosureResolver (fijadas por la spec sin parámetro de threshold explícito).
func _resolve_effective_market(market_def: MarketDef, thresholds_for_match: Dictionary) -> MarketDef:
	if not thresholds_for_match.has(market_def.market_id):
		return market_def

	var effective := MarketDef.new()
	effective.market_id = market_def.market_id
	effective.kind = market_def.kind
	effective.threshold = thresholds_for_match[market_def.market_id]
	effective.base_house_margin = market_def.base_house_margin
	return effective


## Elige, una vez al iniciar el partido, el umbral de cards_ou/fouls_ou cuya probabilidad real quede
## más cerca de 50/50 dado el estado del partido en curso al momento de decidir (sección 5.4).
func _choose_variable_thresholds(home_team: TeamDef, away_team: TeamDef, state: MatchTickState) -> Dictionary:
	var chosen: Dictionary = {}
	chosen["cards_ou"] = _pick_closest_to_50_50(&"cards_ou", MarketDef.MarketKind.CARDS_OVER_UNDER, LeagueRules.CARDS_THRESHOLDS, home_team, away_team, state)
	chosen["fouls_ou"] = _pick_closest_to_50_50(&"fouls_ou", MarketDef.MarketKind.FOULS_OVER_UNDER, LeagueRules.FOULS_THRESHOLDS, home_team, away_team, state)
	return chosen


func _pick_closest_to_50_50(market_id: StringName, kind: MarketDef.MarketKind, candidate_thresholds: Array[float], home_team: TeamDef, away_team: TeamDef, state: MatchTickState) -> float:
	var best_threshold: float = candidate_thresholds[0]
	var best_distance: float = INF

	for threshold in candidate_thresholds:
		var candidate_market := MarketDef.new()
		candidate_market.market_id = market_id
		candidate_market.kind = kind
		candidate_market.threshold = threshold

		var probabilities: Dictionary = OddsEngine.compute_market_probabilities(candidate_market, state, home_team, away_team)
		var p_over: float = probabilities.get("over", 0.5)
		var distance: float = abs(p_over - 0.5)

		if distance < best_distance:
			best_distance = distance
			best_threshold = threshold

	return best_threshold


## Arma el MatchResult final de cada partido y llama LeagueState.apply_matchday_results(...), y emite
## EventBus.matchday_finished(matchday_index) para el resto de sistemas (UI). Ver nota de
## LeagueState sobre por qué apply_matchday_results se llama directamente en vez de vía suscripción.
func _finish_matchday() -> void:
	var results: Array[MatchResult] = []
	for state in active_matches.values():
		results.append(_build_match_result(state))

	LeagueState.apply_matchday_results(results)
	EventBus.matchday_finished.emit(_current_matchday.matchday_index)


func _build_match_result(state: MatchTickState) -> MatchResult:
	var result := MatchResult.new()
	result.match_id = state.match_id
	result.home_team_id = state.home_team_id
	result.away_team_id = state.away_team_id
	result.home_goals = state.home_goals
	result.away_goals = state.away_goals
	result.cards_home = state.cards_home
	result.cards_away = state.cards_away
	result.goal_scorers = state.goal_scorers.duplicate()
	var carded_players: Array = _carded_players_by_match.get(state.match_id, [])
	var carded_player_ids: Array[StringName] = []
	for player_id in carded_players:
		carded_player_ids.append(player_id)
	result.carded_player_ids = carded_player_ids
	return result
