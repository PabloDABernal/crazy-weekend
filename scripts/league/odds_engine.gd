class_name OddsEngine extends RefCounted
## Motor de probabilidad real interna (D.5), puro, nunca expuesto al jugador. Calcula p_real por
## mercado a partir de atributos + estado acumulado del partido.
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 5.1.

const TOTAL_MATCH_MINUTES: int = 90


## Devuelve p_real (0.0-1.0) por cada opción del mercado, ya normalizado a que sume 1.0 dentro del
## mismo mercado cuando el mercado tiene opciones mutuamente excluyentes (1x2, over/under).
static func compute_market_probabilities(market: MarketDef, state: MatchTickState, home_team: TeamDef, away_team: TeamDef) -> Dictionary:
	match market.kind:
		MarketDef.MarketKind.MATCH_RESULT_1X2:
			return _compute_1x2(state, home_team, away_team)
		MarketDef.MarketKind.GOALS_OVER_UNDER:
			return _compute_goals_over_under(market.threshold, state, home_team, away_team)
		MarketDef.MarketKind.FIRST_SCORER:
			return _compute_first_scorer(state, home_team, away_team)
		MarketDef.MarketKind.BOTH_TEAMS_SCORE:
			return _compute_btts(state, home_team, away_team)
		MarketDef.MarketKind.CARDS_OVER_UNDER:
			return _compute_cards_over_under(market.threshold, state, home_team, away_team)
		MarketDef.MarketKind.FOULS_OVER_UNDER:
			return _compute_fouls_over_under(market.threshold, state, home_team, away_team)
		_:
			return {}


## Fuerza relativa base de cada equipo, combinando atributos estructurales + estado transcurrido:
## a más minutos jugados, más peso tiene el marcador actual sobre los atributos estructurales, para
## que un partido avanzado refleje lo que ya pasó (criterio de éxito D.3/D.5: un 2-0 en el 60' debe
## subir p_real("home") de 1x2 respecto al inicio del partido).
static func _team_strength(team: TeamDef, is_home: bool) -> float:
	var strength: float = team.offense * 0.5 + team.defense * 0.3 + team.current_form * 0.2
	if is_home:
		strength *= (1.0 + team.home_advantage)
	return max(strength, 0.01)


static func _elapsed_weight(state: MatchTickState) -> float:
	return clampf(float(state.current_minute) / float(TOTAL_MATCH_MINUTES), 0.0, 1.0)


static func _compute_1x2(state: MatchTickState, home_team: TeamDef, away_team: TeamDef) -> Dictionary:
	var home_strength: float = _team_strength(home_team, true)
	var away_strength: float = _team_strength(away_team, false)
	var draw_strength: float = (home_strength + away_strength) * 0.35

	var total: float = home_strength + away_strength + draw_strength
	var p_home: float = home_strength / total
	var p_draw: float = draw_strength / total
	var p_away: float = away_strength / total

	# Ajuste por marcador ya transcurrido: cuanto más avanzado el partido, más pesa la diferencia de
	# goles actual sobre las probabilidades estructurales de pre-partido.
	var elapsed: float = _elapsed_weight(state)
	var goal_diff: int = state.home_goals - state.away_goals
	if goal_diff != 0 and elapsed > 0.0:
		var shift: float = clampf(float(goal_diff) * 0.15 * elapsed, -0.85, 0.85)
		var probabilities: Dictionary = {"home": p_home, "draw": p_draw, "away": p_away}
		var favored_key: String = "home" if shift > 0.0 else "away"
		probabilities = _shift_probability_mass(probabilities, favored_key, absf(shift))
		p_home = probabilities["home"]
		p_draw = probabilities["draw"]
		p_away = probabilities["away"]

	return _normalize({"home": p_home, "draw": p_draw, "away": p_away})


## Traslada masa de probabilidad hacia favored_key desde el resto de claves del diccionario,
## proporcionalmente al peso relativo de cada una: favored_key sube en shift_abs * (suma del resto),
## recortado a [0.01, 0.97], y el resto se redistribuye conservando su proporción relativa dentro de
## la masa restante. Único helper reusado por ambas ramas (home favorecido / away favorecido) de
## _compute_1x2, para evitar duplicar la misma lógica de redistribución dos veces.
static func _shift_probability_mass(probabilities: Dictionary, favored_key: String, shift_abs: float) -> Dictionary:
	var other_keys: Array = []
	for key in probabilities.keys():
		if key != favored_key:
			other_keys.append(key)

	var others_total: float = 0.0
	for key in other_keys:
		others_total += probabilities[key]

	var result: Dictionary = probabilities.duplicate()
	result[favored_key] = clampf(probabilities[favored_key] + shift_abs * others_total, 0.01, 0.97)

	var remaining: float = 1.0 - result[favored_key]
	if others_total > 0.0:
		for key in other_keys:
			result[key] = remaining * (probabilities[key] / others_total)

	return result


## Estima goles totales esperados en los 90 minutos combinando atributos ofensivos/defensivos con los
## goles ya marcados (elapsed) para modelar la distribución de over/under de forma que un partido con
## goles ya suficientes para superar el umbral tenga p_real("under") -> 0.
static func _compute_goals_over_under(threshold: float, state: MatchTickState, home_team: TeamDef, away_team: TeamDef) -> Dictionary:
	var current_goals: int = state.home_goals + state.away_goals
	if float(current_goals) > threshold:
		return {"over": 1.0, "under": 0.0}

	var elapsed: float = _elapsed_weight(state)
	var remaining_fraction: float = 1.0 - elapsed
	var expected_total_goals: float = (home_team.offense + away_team.offense) * 1.6
	var expected_remaining_goals: float = expected_total_goals * remaining_fraction

	var goals_needed: float = threshold - float(current_goals)
	# Aproximación simple: probabilidad de superar goals_needed goles restantes con media esperada
	# expected_remaining_goals, vía función logística centrada en goals_needed.
	var p_over: float = clampf(1.0 / (1.0 + exp(goals_needed - expected_remaining_goals)), 0.01, 0.99)

	return _normalize({"over": p_over, "under": 1.0 - p_over})


## Primer goleador: ponderado por avg_goals_per_match de FORWARD/MIDFIELDER de ambos equipos, salvo
## que ya haya un goleador registrado este partido (en cuyo caso ese jugador ya tiene p_real = 1.0).
static func _compute_first_scorer(state: MatchTickState, home_team: TeamDef, away_team: TeamDef) -> Dictionary:
	if not state.goal_scorers.is_empty():
		var result: Dictionary = {}
		result[String(state.goal_scorers[0])] = 1.0
		return result

	var eligible_players: Array[PlayerDef] = []
	for player in home_team.squad:
		if player.position == PlayerDef.Position.FORWARD or player.position == PlayerDef.Position.MIDFIELDER:
			eligible_players.append(player)
	for player in away_team.squad:
		if player.position == PlayerDef.Position.FORWARD or player.position == PlayerDef.Position.MIDFIELDER:
			eligible_players.append(player)

	if eligible_players.is_empty():
		return {}

	var total_weight: float = 0.0
	for player in eligible_players:
		total_weight += max(player.avg_goals_per_match, 0.001)

	var probabilities: Dictionary = {}
	for player in eligible_players:
		probabilities[String(player.player_id)] = max(player.avg_goals_per_match, 0.001) / total_weight

	return probabilities


## Ambos equipos marcan: si ambos ya marcaron, p_real("yes") = 1.0. Si no, se estima a partir de la
## probabilidad complementaria de que el equipo que aún no marcó lo haga en el tiempo restante.
static func _compute_btts(state: MatchTickState, home_team: TeamDef, away_team: TeamDef) -> Dictionary:
	if state.home_goals > 0 and state.away_goals > 0:
		return {"yes": 1.0, "no": 0.0}

	var elapsed: float = _elapsed_weight(state)
	var remaining_fraction: float = 1.0 - elapsed

	var p_home_scores: float = 1.0 if state.home_goals > 0 else clampf(home_team.offense * (1.0 - away_team.defense) * remaining_fraction * 1.2, 0.02, 0.95)
	var p_away_scores: float = 1.0 if state.away_goals > 0 else clampf(away_team.offense * (1.0 - home_team.defense) * remaining_fraction * 1.2, 0.02, 0.95)

	var p_yes: float = p_home_scores * p_away_scores
	return _normalize({"yes": p_yes, "no": 1.0 - p_yes})


static func _compute_cards_over_under(threshold: float, state: MatchTickState, home_team: TeamDef, away_team: TeamDef) -> Dictionary:
	var current_cards: int = state.cards_home + state.cards_away
	if float(current_cards) > threshold:
		return {"over": 1.0, "under": 0.0}

	var elapsed: float = _elapsed_weight(state)
	var remaining_fraction: float = 1.0 - elapsed
	var avg_card_probability: float = _average_card_probability(home_team) + _average_card_probability(away_team)
	var expected_total_cards: float = avg_card_probability * 22.0  # ~22 jugadores en cancha
	var expected_remaining_cards: float = expected_total_cards * remaining_fraction

	var cards_needed: float = threshold - float(current_cards)
	var p_over: float = clampf(1.0 / (1.0 + exp(cards_needed - expected_remaining_cards)), 0.01, 0.99)

	return _normalize({"over": p_over, "under": 1.0 - p_over})


static func _compute_fouls_over_under(threshold: float, state: MatchTickState, home_team: TeamDef, away_team: TeamDef) -> Dictionary:
	var current_fouls: int = state.fouls_home + state.fouls_away
	if float(current_fouls) > threshold:
		return {"over": 1.0, "under": 0.0}

	var elapsed: float = _elapsed_weight(state)
	var remaining_fraction: float = 1.0 - elapsed
	# Más faltas esperadas cuanto mayor ofensiva rival enfrenta cada defensa.
	var expected_total_fouls: float = (10.0 + home_team.offense * 8.0 + away_team.offense * 8.0)
	var expected_remaining_fouls: float = expected_total_fouls * remaining_fraction

	var fouls_needed: float = threshold - float(current_fouls)
	var p_over: float = clampf(1.0 / (1.0 + exp((fouls_needed - expected_remaining_fouls) * 0.3)), 0.01, 0.99)

	return _normalize({"over": p_over, "under": 1.0 - p_over})


static func _average_card_probability(team: TeamDef) -> float:
	if team.squad.is_empty():
		return 0.0
	var total: float = 0.0
	for player in team.squad:
		total += player.card_probability
	return total / team.squad.size()


## Normaliza un diccionario de probabilidades para que sumen 1.0.
static func _normalize(probabilities: Dictionary) -> Dictionary:
	var total: float = 0.0
	for value in probabilities.values():
		total += value
	if total <= 0.0:
		return probabilities
	var normalized: Dictionary = {}
	for key in probabilities.keys():
		normalized[key] = probabilities[key] / total
	return normalized
