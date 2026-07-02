extends SceneTree
## Test de MarketAvailabilityResolver (D.7) -- retirada de mercados ya resueltos/imposibles como capa
## base, independiente de Momento Crazy/domingo. Ver
## .ai-studio/specs/story-d7-recalculo-mercados-por-minuto.md secciones 3 y 4.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/league/market_availability_resolver_test.gd

func _init() -> void:
	var failures: Array[String] = []

	_test_first_scorer_available_before_any_goal(failures)
	_test_first_scorer_retired_after_first_goal(failures)
	_test_goals_ou_available_while_undecided(failures)
	_test_goals_ou_retired_once_total_exceeds_threshold(failures)
	_test_goals_ou_still_available_exactly_at_threshold(failures)
	_test_cards_ou_retired_once_decided(failures)
	_test_fouls_ou_retired_once_decided(failures)
	_test_1x2_never_retired(failures)
	_test_btts_never_retired(failures)
	_test_live_match_never_left_without_offerable_markets(failures)

	if failures.is_empty():
		print("[PASS] market_availability_resolver_test: todos los checks OK")
	else:
		push_error("[FAIL] market_availability_resolver_test: %d fallo(s)" % failures.size())
		for failure in failures:
			push_error("  - " + failure)

	quit(0 if failures.is_empty() else 1)


func _build_state(home_goals: int, away_goals: int, cards_home: int, cards_away: int, fouls_home: int, fouls_away: int, goal_scorers: Array[StringName]) -> MatchTickState:
	var state := MatchTickState.new()
	state.match_id = &"match_test"
	state.home_goals = home_goals
	state.away_goals = away_goals
	state.cards_home = cards_home
	state.cards_away = cards_away
	state.fouls_home = fouls_home
	state.fouls_away = fouls_away
	state.goal_scorers = goal_scorers
	return state


func _build_market(market_id: StringName, kind: MarketDef.MarketKind, threshold: float) -> MarketDef:
	var market := MarketDef.new()
	market.market_id = market_id
	market.kind = kind
	market.threshold = threshold
	market.base_house_margin = 0.05
	return market


func _test_first_scorer_available_before_any_goal(failures: Array[String]) -> void:
	var market := _build_market(&"first_scorer", MarketDef.MarketKind.FIRST_SCORER, -1.0)
	var state := _build_state(0, 0, 0, 0, 0, 0, [])

	if not MarketAvailabilityResolver.is_market_available(market, state):
		failures.append("first_scorer debería seguir disponible sin goles marcados")


func _test_first_scorer_retired_after_first_goal(failures: Array[String]) -> void:
	var market := _build_market(&"first_scorer", MarketDef.MarketKind.FIRST_SCORER, -1.0)
	var state := _build_state(1, 0, 0, 0, 0, 0, [&"player_1"])

	if MarketAvailabilityResolver.is_market_available(market, state):
		failures.append("first_scorer debería retirarse tras el primer gol (ya resuelto)")


func _test_goals_ou_available_while_undecided(failures: Array[String]) -> void:
	var market := _build_market(&"goals_ou_2_5", MarketDef.MarketKind.GOALS_OVER_UNDER, 2.5)
	var state := _build_state(1, 0, 0, 0, 0, 0, [&"player_1"])  # total=1, umbral=2.5, aún indeciso

	if not MarketAvailabilityResolver.is_market_available(market, state):
		failures.append("goals_ou_2_5 debería seguir disponible con total=1 y umbral=2.5 (aún indeciso)")


func _test_goals_ou_retired_once_total_exceeds_threshold(failures: Array[String]) -> void:
	var market := _build_market(&"goals_ou_2_5", MarketDef.MarketKind.GOALS_OVER_UNDER, 2.5)
	var state := _build_state(2, 1, 0, 0, 0, 0, [&"p1", &"p2", &"p3"])  # total=3 > 2.5, over ya ganó

	if MarketAvailabilityResolver.is_market_available(market, state):
		failures.append("goals_ou_2_5 debería retirarse con total=3 > umbral=2.5 (over ya no puede fallar)")


func _test_goals_ou_still_available_exactly_at_threshold(failures: Array[String]) -> void:
	# Umbrales del catálogo MVP son siempre X.5 (nunca coincide exacto con un total entero), pero el
	# predicado usa ">" estricto: un total igual al umbral (caso límite defensivo) no debería retirar.
	var market := _build_market(&"goals_ou_2_5", MarketDef.MarketKind.GOALS_OVER_UNDER, 2.0)
	var state := _build_state(1, 1, 0, 0, 0, 0, [&"p1", &"p2"])  # total=2, umbral=2.0

	if not MarketAvailabilityResolver.is_market_available(market, state):
		failures.append("goals_ou con total==threshold no debería retirarse (solo total > threshold decide)")


func _test_cards_ou_retired_once_decided(failures: Array[String]) -> void:
	var market := _build_market(&"cards_ou", MarketDef.MarketKind.CARDS_OVER_UNDER, 3.5)
	var undecided_state := _build_state(0, 0, 1, 1, 0, 0, [])   # total cards=2
	var decided_state := _build_state(0, 0, 2, 2, 0, 0, [])     # total cards=4 > 3.5

	if not MarketAvailabilityResolver.is_market_available(market, undecided_state):
		failures.append("cards_ou debería seguir disponible con total=2 y umbral=3.5")
	if MarketAvailabilityResolver.is_market_available(market, decided_state):
		failures.append("cards_ou debería retirarse con total=4 > umbral=3.5")


func _test_fouls_ou_retired_once_decided(failures: Array[String]) -> void:
	var market := _build_market(&"fouls_ou", MarketDef.MarketKind.FOULS_OVER_UNDER, 19.5)
	var undecided_state := _build_state(0, 0, 0, 0, 10, 8, [])   # total fouls=18
	var decided_state := _build_state(0, 0, 0, 0, 12, 10, [])    # total fouls=22 > 19.5

	if not MarketAvailabilityResolver.is_market_available(market, undecided_state):
		failures.append("fouls_ou debería seguir disponible con total=18 y umbral=19.5")
	if MarketAvailabilityResolver.is_market_available(market, decided_state):
		failures.append("fouls_ou debería retirarse con total=22 > umbral=19.5")


## 1x2/btts se mantienen hasta el final (sección 3): siempre pueden cambiar hasta el min 90, ninguna
## combinación de marcador los retira por minuto (solo Crazy/domingo, fuera de esta capa).
func _test_1x2_never_retired(failures: Array[String]) -> void:
	var market := _build_market(&"1x2", MarketDef.MarketKind.MATCH_RESULT_1X2, -1.0)
	var lopsided_state := _build_state(9, 0, 5, 5, 20, 20, [&"p1", &"p2", &"p3", &"p4", &"p5", &"p6", &"p7", &"p8", &"p9"])

	if not MarketAvailabilityResolver.is_market_available(market, lopsided_state):
		failures.append("1x2 nunca debería retirarse por minuto, sea cual sea el marcador")


func _test_btts_never_retired(failures: Array[String]) -> void:
	var market := _build_market(&"btts", MarketDef.MarketKind.BOTH_TEAMS_SCORE, -1.0)
	var already_both_scored_state := _build_state(1, 1, 0, 0, 0, 0, [&"p1", &"p2"])

	if not MarketAvailabilityResolver.is_market_available(market, already_both_scored_state):
		failures.append("btts nunca debería retirarse por minuto, ni siquiera con ambos equipos ya anotados")


## Garantía de no-bloqueo (relación Bug 1, sección 4): un partido LIVE nunca debe quedarse con cero
## mercados ofertables. Con el catálogo MVP completo y un estado extremo donde todos los mercados de
## umbral quedan decididos y first_scorer ya resuelto, 1x2 y btts deben seguir disponibles.
func _test_live_match_never_left_without_offerable_markets(failures: Array[String]) -> void:
	var markets: Array[MarketDef] = [
		_build_market(&"1x2", MarketDef.MarketKind.MATCH_RESULT_1X2, -1.0),
		_build_market(&"btts", MarketDef.MarketKind.BOTH_TEAMS_SCORE, -1.0),
		_build_market(&"first_scorer", MarketDef.MarketKind.FIRST_SCORER, -1.0),
		_build_market(&"goals_ou_1_5", MarketDef.MarketKind.GOALS_OVER_UNDER, 1.5),
		_build_market(&"goals_ou_2_5", MarketDef.MarketKind.GOALS_OVER_UNDER, 2.5),
		_build_market(&"goals_ou_3_5", MarketDef.MarketKind.GOALS_OVER_UNDER, 3.5),
		_build_market(&"cards_ou", MarketDef.MarketKind.CARDS_OVER_UNDER, 3.5),
		_build_market(&"fouls_ou", MarketDef.MarketKind.FOULS_OVER_UNDER, 19.5),
	]
	var extreme_state := _build_state(4, 3, 3, 3, 15, 15, [&"p1", &"p2", &"p3", &"p4", &"p5", &"p6", &"p7"])  # total goles=7 > todos los umbrales, total cards=6 > 3.5, total fouls=30 > 19.5

	var available_market_ids: Array[StringName] = []
	for market in markets:
		if MarketAvailabilityResolver.is_market_available(market, extreme_state):
			available_market_ids.append(market.market_id)

	if available_market_ids.is_empty():
		failures.append("un partido LIVE se quedó sin ningún mercado ofertable (available_market_ids vacío)")
	if not available_market_ids.has(&"1x2"):
		failures.append("1x2 debería seguir garantizado disponible incluso en el estado extremo")
	if not available_market_ids.has(&"btts"):
		failures.append("btts debería seguir garantizado disponible incluso en el estado extremo")
