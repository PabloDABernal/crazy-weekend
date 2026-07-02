extends SceneTree
## Test de MatchSimulationService (D.6) -- reloj de jornada por partido (kickoff_offset_minutes),
## estados PRE_MATCH/LIVE/FINISHED derivados del reloj, y el arranque consciente del reloj de
## open_initial_tick()/advance_tick(). Ver
## .ai-studio/specs/story-d6-calendario-horarios-escalonados.md secciones 2.2 y 5.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/league/match_simulation_service_schedule_test.gd

func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame
	var failures: Array[String] = []

	LeagueState.generate_new_league(1, 555)

	_test_offset_zero_match_is_live_from_the_start(failures)
	_test_offset_positive_match_stays_pre_match_until_its_offset(failures)
	_test_kickoff_tick_does_not_resolve_a_new_tick(failures)
	_test_finished_match_status(failures)
	_test_clock_cycle_is_shared_across_matches_with_different_kickoffs(failures)

	if failures.is_empty():
		print("[PASS] match_simulation_service_schedule_test: todos los checks OK")
	else:
		push_error("[FAIL] match_simulation_service_schedule_test: %d fallo(s)" % failures.size())
		for failure in failures:
			push_error("  - " + failure)

	quit(0 if failures.is_empty() else 1)


## Arma una jornada de 2 partidos con offsets fijos y controlados a mano (en vez de MatchdayScheduler,
## para que el test sea determinista sobre exactamente los offsets que le interesan).
func _build_two_match_fixture(offset_a: int, offset_b: int) -> MatchdayFixture:
	var teams: Array[TeamDef] = LeagueState.teams
	var match_a := MatchFixture.new()
	match_a.match_id = &"test_match_a"
	match_a.home_team_id = teams[0].team_id
	match_a.away_team_id = teams[1].team_id
	match_a.kickoff_offset_minutes = offset_a

	var match_b := MatchFixture.new()
	match_b.match_id = &"test_match_b"
	match_b.home_team_id = teams[2].team_id
	match_b.away_team_id = teams[3].team_id
	match_b.kickoff_offset_minutes = offset_b

	var matchday := MatchdayFixture.new()
	matchday.matchday_index = 0
	matchday.matches = [match_a, match_b]
	return matchday


func _new_service(matchday: MatchdayFixture) -> MatchSimulationService:
	var service := MatchSimulationService.new()
	root.add_child(service)
	service.start_matchday(matchday, BettingDay.Day.FRIDAY)
	return service


func _test_offset_zero_match_is_live_from_the_start(failures: Array[String]) -> void:
	var matchday := _build_two_match_fixture(0, 30)
	var service := _new_service(matchday)

	if service.get_match_status(&"test_match_a") != MatchSimulationService.MatchStatus.LIVE:
		failures.append("un partido con kickoff_offset_minutes=0 debería estar LIVE en clock=0")

	service.queue_free()


func _test_offset_positive_match_stays_pre_match_until_its_offset(failures: Array[String]) -> void:
	var matchday := _build_two_match_fixture(0, 30)
	var service := _new_service(matchday)

	if service.get_match_status(&"test_match_b") != MatchSimulationService.MatchStatus.PRE_MATCH:
		failures.append("un partido con kickoff_offset_minutes=30 debería estar PRE_MATCH en clock=0")

	service.open_initial_tick()
	service.advance_tick()   # clock=15 -- match_b sigue PRE_MATCH (offset=30)
	if service.get_match_status(&"test_match_b") != MatchSimulationService.MatchStatus.PRE_MATCH:
		failures.append("match_b debería seguir PRE_MATCH en clock=15 (offset=30)")
	if service.get_match_tick_state(&"test_match_b").current_tick_index != 0:
		failures.append("match_b no debería haber avanzado de tick mientras sigue PRE_MATCH")

	service.advance_tick()   # clock=30 -- match_b pasa a LIVE (kickoff)
	if service.get_match_status(&"test_match_b") != MatchSimulationService.MatchStatus.LIVE:
		failures.append("match_b debería estar LIVE en clock=30 (offset=30)")

	service.queue_free()


## El avance que hace kickoff (PRE_MATCH -> LIVE) no debe resolver un tick nuevo (sección 5 de la spec):
## el partido sigue en su tick 0 recién anunciado, listo para que el SIGUIENTE advance_tick() resuelva
## sus primeros 15 minutos de juego.
func _test_kickoff_tick_does_not_resolve_a_new_tick(failures: Array[String]) -> void:
	var matchday := _build_two_match_fixture(0, 30)
	var service := _new_service(matchday)

	service.open_initial_tick()
	service.advance_tick()   # clock=15
	service.advance_tick()   # clock=30 -- kickoff de match_b

	var state_b: MatchTickState = service.get_match_tick_state(&"test_match_b")
	if state_b.current_tick_index != 0:
		failures.append("el tick de kickoff de match_b no debería resolver un tick nuevo (current_tick_index=%d, esperado 0)" % state_b.current_tick_index)

	service.advance_tick()   # clock=45 -- primer tick LIVE real de match_b
	state_b = service.get_match_tick_state(&"test_match_b")
	if state_b.current_tick_index != 1:
		failures.append("el primer advance_tick() tras el kickoff de match_b debería resolver su tick 1 (obtenido %d)" % state_b.current_tick_index)

	service.queue_free()


func _test_finished_match_status(failures: Array[String]) -> void:
	var matchday := _build_two_match_fixture(0, 0)
	var service := _new_service(matchday)

	service.open_initial_tick()
	for _i in range(LeagueRules.TICKS_PER_MATCH):
		service.advance_tick()

	if service.get_match_status(&"test_match_a") != MatchSimulationService.MatchStatus.FINISHED:
		failures.append("tras %d ticks el partido debería estar FINISHED" % LeagueRules.TICKS_PER_MATCH)

	service.queue_free()


## D.6 §9 / dedupe del Momento Crazy: clock_cycle debe ser el MISMO para todos los BetTickContext
## emitidos dentro de la misma llamada a advance_tick(), aunque los partidos tengan tick_index_in_day
## distinto por tener kickoffs distintos -- la clave que RunState debe usar para el dedupe.
func _test_clock_cycle_is_shared_across_matches_with_different_kickoffs(failures: Array[String]) -> void:
	var matchday := _build_two_match_fixture(0, 30)
	var service := _new_service(matchday)

	var contexts_this_advance: Array[BetTickContext] = []
	var handler := func(context: BetTickContext) -> void:
		contexts_this_advance.append(context)

	service.open_initial_tick()
	service.advance_tick()   # clock=15

	EventBus.bet_tick_opened.connect(handler)
	service.advance_tick()   # clock=30 -- match_a LIVE (tick 2), match_b hace kickoff (tick 0)
	EventBus.bet_tick_opened.disconnect(handler)

	if contexts_this_advance.size() != 2:
		failures.append("se esperaban 2 BetTickContext emitidos en el advance_tick de clock=30 (obtenidos %d)" % contexts_this_advance.size())
	else:
		var clock_cycles: Array[int] = []
		var tick_indices: Array[int] = []
		for context in contexts_this_advance:
			clock_cycles.append(context.clock_cycle)
			tick_indices.append(context.tick_index_in_day)

		if clock_cycles[0] != clock_cycles[1]:
			failures.append("clock_cycle debería ser igual para ambos partidos en el mismo advance_tick() (obtenidos %s)" % [clock_cycles])
		if tick_indices[0] == tick_indices[1]:
			failures.append("este test debería ejercitar tick_index_in_day DISTINTO entre partidos (ambos dieron %d) -- si no, no reproduce el escenario de relojes divergentes" % tick_indices[0])

	service.queue_free()
