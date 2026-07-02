class_name MarketAvailabilityResolver extends RefCounted
## Predicado puro (D.7): decide si un MarketDef sigue teniendo sentido ofertar dado el estado vivo
## del partido. Comportamiento base, independiente de las restricciones narrativas de Momento Crazy
## (B.3) o de domingo (que se apilan encima, sobre el conjunto ya filtrado aquí).
## Ver .ai-studio/specs/story-d7-recalculo-mercados-por-minuto.md sección 3.
##
## Decisión tomada siguiendo la recomendación explícita de la spec (sección 2): mercados
## decididos/imposibles se RETIRAN (no se ofertan con cuota residual). `is_residual` queda fuera de
## alcance del MVP.


## true si `market` sigue teniendo sentido ofertar dado `state`. `1x2`/`btts` nunca se retiran por
## minuto (garantiza que un partido LIVE nunca se quede sin mercados ofertables, ver sección 4).
static func is_market_available(market: MarketDef, state: MatchTickState) -> bool:
	match market.kind:
		MarketDef.MarketKind.FIRST_SCORER:
			return state.goal_scorers.is_empty()
		MarketDef.MarketKind.GOALS_OVER_UNDER:
			return not _is_over_under_decided(state.home_goals + state.away_goals, market.threshold)
		MarketDef.MarketKind.CARDS_OVER_UNDER:
			return not _is_over_under_decided(state.cards_home + state.cards_away, market.threshold)
		MarketDef.MarketKind.FOULS_OVER_UNDER:
			return not _is_over_under_decided(state.fouls_home + state.fouls_away, market.threshold)
		MarketDef.MarketKind.MATCH_RESULT_1X2, MarketDef.MarketKind.BOTH_TEAMS_SCORE:
			return true
		_:
			return true


## Un mercado over/under de umbral X.5 queda decidido (sin vuelta atrás) en cuanto el total ya
## ocurrido supera el umbral: "over" ya no puede fallar y "under" ya es imposible (sección 3).
static func _is_over_under_decided(total_so_far: int, threshold: float) -> bool:
	return float(total_so_far) > threshold
