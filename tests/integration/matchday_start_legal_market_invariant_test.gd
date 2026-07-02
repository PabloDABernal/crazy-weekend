extends SceneTree
## Test de la invariante anti-bloqueo compartida entre Bug 1, D.6 y D.7 (explícitamente pedido por
## D.6 sección 4.1): en el arranque de cualquier jornada, y en cualquier partido LIVE mientras dure,
## debe existir SIEMPRE al menos 1 mercado legal en el que apostar -- si no, el gate de tick
## obligatorio (BettingRoot._all_matches_satisfied_this_cycle) se queda sin salida posible.
##
## Cubre el camino real end-to-end (MatchdayScheduler -> MatchSimulationService -> MarketAvailability
## Resolver), tanto para una jornada STAGGERED normal como para la jornada especial CONCENTRATED
## ("Super Sunday", la última de la temporada) -- no da la garantía por hecha, la ejercita con datos
## reales de una liga generada.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/integration/matchday_start_legal_market_invariant_test.gd

var _failures: Array[String] = []
var _opened_live_with_markets: Array[StringName] = []
var _service: MatchSimulationService = null


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame

	LeagueState.generate_new_league(1, 2024)

	_assert_matchday_start_has_live_open_market(LeagueState.calendar[0], "STAGGERED (matchday 0)")
	_assert_matchday_start_has_live_open_market(LeagueState.calendar[LeagueRules.TOTAL_MATCHDAYS - 1], "CONCENTRATED (última jornada)")
	_assert_live_match_never_runs_out_of_markets_across_ticks(LeagueState.calendar[0])

	if _failures.is_empty():
		print("[PASS] matchday_start_legal_market_invariant_test: todos los checks OK")
	else:
		push_error("[FAIL] matchday_start_legal_market_invariant_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)


func _assert_matchday_start_has_live_open_market(matchday_fixture: MatchdayFixture, label: String) -> void:
	var service := MatchSimulationService.new()
	root.add_child(service)
	service.start_matchday(matchday_fixture, BettingDay.Day.FRIDAY)

	var live_count: int = 0
	for match_fixture in matchday_fixture.matches:
		if service.get_match_status(match_fixture.match_id) == MatchSimulationService.MatchStatus.LIVE:
			live_count += 1

	if live_count == 0:
		_failures.append("%s: ningún partido queda LIVE al arrancar la jornada (clock=0) -- MatchdayScheduler no garantizó offset 0" % label)

	_opened_live_with_markets = []
	_service = service
	EventBus.bet_tick_opened.connect(_on_bet_tick_opened_track_live_markets)
	service.open_initial_tick()
	EventBus.bet_tick_opened.disconnect(_on_bet_tick_opened_track_live_markets)

	if _opened_live_with_markets.is_empty():
		_failures.append("%s: open_initial_tick() no ofreció ningún mercado en un partido LIVE -- el jugador se quedaría sin nada legal que apostar al arrancar la jornada" % label)

	service.queue_free()
	_service = null


func _on_bet_tick_opened_track_live_markets(context: BetTickContext) -> void:
	if context.available_markets.is_empty():
		return
	var match_id: StringName = context.available_markets[0].match_id
	if _service.get_match_status(match_id) == MatchSimulationService.MatchStatus.LIVE:
		_opened_live_with_markets.append(match_id)


## Recorre varios ciclos de reloj (suficientes para que todos los partidos de una jornada STAGGERED
## real terminen de arrancar y de jugarse) y verifica que TODO partido que estaba LIVE justo antes de
## un advance_tick() (y que no terminó ya en ese mismo avance) emitió un bet_tick_opened con
## available_markets no vacío en ese ciclo -- ejercita MarketAvailabilityResolver con estados reales
## del motor, no solo con el estado extremo sintético de market_availability_resolver_test. Un partido
## LIVE que se quede sin ningún contexto atribuible (porque su available_markets llegó vacío, o porque
## no emitió nada) es exactamente el bloqueo que esta invariante prohíbe.
func _assert_live_match_never_runs_out_of_markets_across_ticks(matchday_fixture: MatchdayFixture) -> void:
	var service := MatchSimulationService.new()
	root.add_child(service)
	service.start_matchday(matchday_fixture, BettingDay.Day.FRIDAY)

	var seen_match_ids_this_cycle: Array[StringName] = []
	var handler := func(context: BetTickContext) -> void:
		if context.available_markets.is_empty():
			return
		seen_match_ids_this_cycle.append(context.available_markets[0].match_id)

	EventBus.bet_tick_opened.connect(handler)
	service.open_initial_tick()

	for i in range(LeagueRules.TICKS_PER_MATCH + 8):   # margen suficiente para que arranquen todos los kickoffs escalonados y terminen todos los partidos
		if service.is_matchday_finished():
			break

		var live_before_advance: Array[StringName] = []
		for match_fixture in matchday_fixture.matches:
			if service.get_match_status(match_fixture.match_id) == MatchSimulationService.MatchStatus.LIVE:
				live_before_advance.append(match_fixture.match_id)

		# IMPORTANTE: .clear() (no reasignar `seen_match_ids_this_cycle = []`) -- el lambda `handler`
		# capturó la referencia al Array original al crearse; reasignar la variable a un Array nuevo
		# rompería ese vínculo y el handler seguiría escribiendo en el Array viejo, invisible aquí.
		seen_match_ids_this_cycle.clear()
		service.advance_tick()

		for match_id in live_before_advance:
			if service.get_match_status(match_id) == MatchSimulationService.MatchStatus.FINISHED:
				continue   # este avance lo terminó -- ya no necesita mercados abiertos
			if not seen_match_ids_this_cycle.has(match_id):
				_failures.append("partido %s estaba LIVE antes del avance #%d y no recibió mercados ofertables en ese ciclo" % [match_id, i])

	EventBus.bet_tick_opened.disconnect(handler)
	service.queue_free()
