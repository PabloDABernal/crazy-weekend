class_name MatchTickEngine extends RefCounted
## Motor de simulación de partido por ticks de 15 minutos (D.3). Lógica pura, sin nodo, testeable
## aislada, mismo patrón que StakeResolver/CrazyBetResolver de Épica B.
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 4.

const MINUTES_PER_TICK: int = 15


## Resuelve un único tick de 15 minutos para un partido, mutando/devolviendo el nuevo MatchTickState.
## No conoce mercados ni apuestas — solo produce el estado del partido en sí.
static func resolve_tick(previous_state: MatchTickState, home_team: TeamDef, away_team: TeamDef, rng: RandomNumberGenerator) -> MatchTickState:
	var state := MatchTickState.new()
	state.match_id = previous_state.match_id
	state.home_team_id = previous_state.home_team_id
	state.away_team_id = previous_state.away_team_id
	state.current_tick_index = previous_state.current_tick_index + 1
	state.current_minute = previous_state.current_minute + MINUTES_PER_TICK
	state.home_goals = previous_state.home_goals
	state.away_goals = previous_state.away_goals
	state.shots_on_target_home = previous_state.shots_on_target_home
	state.shots_on_target_away = previous_state.shots_on_target_away
	state.cards_home = previous_state.cards_home
	state.cards_away = previous_state.cards_away
	state.corners_home = previous_state.corners_home
	state.corners_away = previous_state.corners_away
	state.fouls_home = previous_state.fouls_home
	state.fouls_away = previous_state.fouls_away
	state.goal_scorers = previous_state.goal_scorers.duplicate()

	var tick_events: Array[MatchTickEvent] = []

	# 1. Pesos de presión ofensiva de este tick.
	var attack_pressure_home: float = home_team.offense * (1.0 + home_team.home_advantage) * home_team.current_form
	var attack_pressure_away: float = away_team.offense * away_team.current_form

	# 2. Intentos ofensivos por equipo (Poisson aproximado por muestreo acumulado de eventos independientes).
	_resolve_team_attempts(state, tick_events, home_team, away_team, attack_pressure_home, true, rng)
	_resolve_team_attempts(state, tick_events, away_team, home_team, attack_pressure_away, false, rng)

	# 4. Tarjetas/faltas/corners, muestreados de forma independiente por tick.
	_resolve_discipline_and_set_pieces(state, tick_events, home_team, away_team, true, rng)
	_resolve_discipline_and_set_pieces(state, tick_events, away_team, home_team, false, rng)

	# Posesión: se re-normaliza cada tick a partir de la presión ofensiva relativa de este tick.
	var total_pressure: float = attack_pressure_home + attack_pressure_away
	if total_pressure > 0.0:
		state.possession_home_pct = (attack_pressure_home / total_pressure) * 100.0
	else:
		state.possession_home_pct = 50.0

	state.tick_events = tick_events
	return state


## Resuelve los intentos ofensivos de un equipo en este tick: cada intento se clasifica como
## SHOT_OFF_TARGET, SHOT_ON_TARGET o GOAL. GOAL solo posible desde un intento ya SHOT_ON_TARGET,
## ponderado por 1 - defense del rival.
static func _resolve_team_attempts(state: MatchTickState, tick_events: Array[MatchTickEvent], attacking_team: TeamDef, defending_team: TeamDef, attack_pressure: float, is_home: bool, rng: RandomNumberGenerator) -> void:
	var expected_attempts: float = 1.0 + attack_pressure * 2.0
	var attempt_count: int = _sample_poisson(expected_attempts, rng)

	for _i in range(attempt_count):
		var minute: int = state.current_minute - MINUTES_PER_TICK + rng.randi_range(1, MINUTES_PER_TICK)
		var on_target_chance: float = clampf(0.3 + attack_pressure * 0.3, 0.05, 0.85)

		if rng.randf() >= on_target_chance:
			tick_events.append(_build_event(MatchTickEvent.EventKind.SHOT_OFF_TARGET, attacking_team.team_id, &"", minute))
			continue

		if is_home:
			state.shots_on_target_home += 1
		else:
			state.shots_on_target_away += 1

		var goal_chance: float = clampf((1.0 - defending_team.defense) * 0.45, 0.05, 0.9)
		if rng.randf() < goal_chance:
			var scorer_id: StringName = _pick_goal_scorer(attacking_team, rng)
			if is_home:
				state.home_goals += 1
			else:
				state.away_goals += 1
			state.goal_scorers.append(scorer_id)
			tick_events.append(_build_event(MatchTickEvent.EventKind.GOAL, attacking_team.team_id, scorer_id, minute))
		else:
			tick_events.append(_build_event(MatchTickEvent.EventKind.SHOT_ON_TARGET, attacking_team.team_id, &"", minute))


## Tarjetas, faltas y corners de un equipo en este tick. Ajustados levemente por defense/offense del
## rival (más faltas cuando defiendes contra más ofensiva rival).
static func _resolve_discipline_and_set_pieces(state: MatchTickState, tick_events: Array[MatchTickEvent], team: TeamDef, rival_team: TeamDef, is_home: bool, rng: RandomNumberGenerator) -> void:
	var fouls_range: Vector2 = LeagueRules.BASE_FOULS_PER_TICK_RANGE
	var foul_bias: float = 1.0 + rival_team.offense * 0.5
	var foul_count: int = int(round(rng.randf_range(fouls_range.x, fouls_range.y) * foul_bias))

	for _i in range(foul_count):
		var minute: int = state.current_minute - MINUTES_PER_TICK + rng.randi_range(1, MINUTES_PER_TICK)
		if is_home:
			state.fouls_home += 1
		else:
			state.fouls_away += 1
		tick_events.append(_build_event(MatchTickEvent.EventKind.FOUL, team.team_id, &"", minute))

		if rng.randf() < LeagueRules.BASE_CARDS_PER_TICK_CHANCE:
			var carded_player: PlayerDef = _pick_carded_player(team, rng)
			if is_home:
				state.cards_home += 1
			else:
				state.cards_away += 1
			var carded_player_id: StringName = carded_player.player_id if carded_player != null else &""
			tick_events.append(_build_event(MatchTickEvent.EventKind.CARD, team.team_id, carded_player_id, minute))

	var corners_range: Vector2 = LeagueRules.BASE_CORNERS_PER_TICK_RANGE
	var corner_count: int = int(round(rng.randf_range(corners_range.x, corners_range.y)))
	for _i in range(corner_count):
		var minute: int = state.current_minute - MINUTES_PER_TICK + rng.randi_range(1, MINUTES_PER_TICK)
		if is_home:
			state.corners_home += 1
		else:
			state.corners_away += 1
		tick_events.append(_build_event(MatchTickEvent.EventKind.CORNER, team.team_id, &"", minute))


## Muestrea un player_id de FORWARD/MIDFIELDER del equipo, ponderado por avg_goals_per_match.
static func _pick_goal_scorer(team: TeamDef, rng: RandomNumberGenerator) -> StringName:
	var eligible: Array[PlayerDef] = []
	for player in team.squad:
		if player.position == PlayerDef.Position.FORWARD or player.position == PlayerDef.Position.MIDFIELDER:
			eligible.append(player)

	if eligible.is_empty():
		return &""

	var total_weight: float = 0.0
	for player in eligible:
		total_weight += max(player.avg_goals_per_match, 0.001)

	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for player in eligible:
		cumulative += max(player.avg_goals_per_match, 0.001)
		if roll < cumulative:
			return player.player_id

	return eligible[-1].player_id


## Muestrea un jugador de la plantilla ponderado por card_probability.
static func _pick_carded_player(team: TeamDef, rng: RandomNumberGenerator) -> PlayerDef:
	if team.squad.is_empty():
		return null

	var total_weight: float = 0.0
	for player in team.squad:
		total_weight += max(player.card_probability, 0.001)

	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for player in team.squad:
		cumulative += max(player.card_probability, 0.001)
		if roll < cumulative:
			return player

	return team.squad[-1]


static func _build_event(kind: MatchTickEvent.EventKind, team_id: StringName, player_id: StringName, minute: int) -> MatchTickEvent:
	var event := MatchTickEvent.new()
	event.kind = kind
	event.team_id = team_id
	event.player_id = player_id
	event.minute = minute
	return event


## Muestreo aproximado de una distribución Poisson(lambda) por el método de Knuth, adecuado para
## los valores de lambda pequeños que se usan en este motor (intentos por tick).
static func _sample_poisson(lambda: float, rng: RandomNumberGenerator) -> int:
	var l: float = exp(-lambda)
	var k: int = 0
	var p: float = 1.0
	while true:
		k += 1
		p *= rng.randf()
		if p <= l:
			break
	return k - 1
