class_name MarketBetResultBuilder extends RefCounted
## Dado el estado final relevante del partido y la opción apostada por el jugador, arma el
## MarketBetResult completo incluyendo context_tags. Lo invoca la UI de apuestas (Épica E) al
## resolver un tick. Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 9.
##
## Nota de implementación: la firma fijada por la spec no recibe TeamDef de ambos equipos, solo
## match_state (con los team_id). Para calcular el tag "underdog_win" (que requiere p_real de
## OddsEngine, y OddsEngine necesita TeamDef) se resuelven los TeamDef vía el autoload LeagueState
## (LeagueState.get_team(team_id)), que ya es la fuente de verdad de equipos de la liga activa.

const UNDERDOG_WIN_TAG: StringName = &"underdog_win"
const DIRTY_MATCH_FOULS_TAG: StringName = &"dirty_match_fouls_gt_20"
const DIRTY_MATCH_FOULS_THRESHOLD: int = 20


## Arma el MarketBetResult completo. context_tags solo se calculan cuando won == true (fallar una
## apuesta nunca puede cumplir un reto de desbloqueo, ver epic-a-tipos-de-victoria.md sección 2.1).
static func build_result(market_offer: MarketOffer, won: bool, match_state: MatchTickState,
		matchday_id: StringName, run_number: int) -> MarketBetResult:
	var result := MarketBetResult.new()
	result.market_id = market_offer.market_id
	result.match_id = market_offer.match_id
	result.matchday_id = matchday_id
	result.won = won
	result.run_number = run_number
	result.context_tags = _compute_context_tags(market_offer, won, match_state)
	return result


static func _compute_context_tags(market_offer: MarketOffer, won: bool, match_state: MatchTickState) -> Array[StringName]:
	var tags: Array[StringName] = []
	if not won:
		return tags

	if market_offer.market_id == &"1x2" and _is_underdog_win(market_offer, match_state):
		tags.append(UNDERDOG_WIN_TAG)

	if market_offer.market_id == &"fouls_ou" and _is_dirty_match(match_state):
		tags.append(DIRTY_MATCH_FOULS_TAG)

	return tags


## "underdog_win": el ganador del 1x2 (la opción apostada, ya que won == true) tenía menor p_real
## que las demás opciones del mismo mercado en el momento de cierre de la apuesta.
static func _is_underdog_win(market_offer: MarketOffer, match_state: MatchTickState) -> bool:
	var home_team: TeamDef = LeagueState.get_team(match_state.home_team_id)
	var away_team: TeamDef = LeagueState.get_team(match_state.away_team_id)
	if home_team == null or away_team == null:
		return false

	var market_def: MarketDef = MarketCatalog.get_market_definition(&"1x2")
	if market_def == null:
		return false

	var probabilities: Dictionary = OddsEngine.compute_market_probabilities(market_def, match_state, home_team, away_team)
	var won_option_probability: float = probabilities.get(String(market_offer.option_key), 0.0)

	for option_key in probabilities.keys():
		if option_key == String(market_offer.option_key):
			continue
		if probabilities[option_key] > won_option_probability:
			return true
	return false


## "dirty_match_fouls_gt_20": faltas totales del partido > 20 sobre el MatchTickState final.
static func _is_dirty_match(match_state: MatchTickState) -> bool:
	return (match_state.fouls_home + match_state.fouls_away) > DIRTY_MATCH_FOULS_THRESHOLD
