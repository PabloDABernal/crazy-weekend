extends SceneTree
## Test de regresión D.6 (sección 9) -- dedupe del disparo de Momento Crazy con relojes por partido
## independientes.
##
## El dedupe de RunState (fix Bug 1, §7.1) deduplicaba por (day, tick_index_in_day), asumiendo que
## tick_index_in_day era común a TODOS los partidos vivos de la jornada -- cierto en el modelo lockstep
## anterior a D.6. Con D.6, cada partido tiene su propio kickoff_offset_minutes: dos partidos vivos en
## el mismo advance_tick() ya NO comparten necesariamente current_tick_index. Este test arma una
## jornada con offsets deliberadamente distintos y ejercita el dedupe REAL de RunState (no una copia
## simulada), verificando que crazy_moment_triggered se emite EXACTAMENTE una vez por ciclo de reloj
## global, aunque los dos partidos vivos en ese ciclo reporten tick_index_in_day distinto.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/integration/crazy_moment_dedupe_divergent_clocks_test.gd

var _trigger_count: int = 0
var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	LeagueState.generate_new_league(1, 999)
	RunState.start_new_run()

	var teams: Array[TeamDef] = LeagueState.teams
	var match_a := MatchFixture.new()
	match_a.match_id = &"dedupe_test_match_a"
	match_a.home_team_id = teams[0].team_id
	match_a.away_team_id = teams[1].team_id
	match_a.kickoff_offset_minutes = 0   # LIVE desde clock=0

	var match_b := MatchFixture.new()
	match_b.match_id = &"dedupe_test_match_b"
	match_b.home_team_id = teams[2].team_id
	match_b.away_team_id = teams[3].team_id
	match_b.kickoff_offset_minutes = 30   # arranca 2 ciclos más tarde que match_a

	var matchday := MatchdayFixture.new()
	matchday.matchday_index = 0
	matchday.matches = [match_a, match_b]

	var service := MatchSimulationService.new()
	root.add_child(service)
	service.start_matchday(matchday, BettingDay.Day.FRIDAY)

	# Fuerza el plan de Momentos Crazy de la run a un único slot determinista en clock_cycle=3: en ese
	# ciclo, match_a (LIVE desde el principio) va por su tick 3, y match_b (kickoff en clock=30, es
	# decir en el ciclo 2) va por su tick 1 -- current_tick_index DISTINTO para cada uno, mismo
	# clock_cycle. Exactamente el escenario de relojes divergentes que D.6 introduce.
	RunState.crazy_moment_schedule = [CrazyMomentScheduler.ScheduledCrazyMoment.new(BettingDay.Day.FRIDAY, 3)]

	EventBus.crazy_moment_triggered.connect(_on_crazy_moment_triggered)

	service.open_initial_tick()   # clock=0 (clock_cycle=0)
	service.advance_tick()        # clock=15 (clock_cycle=1)
	service.advance_tick()        # clock=30 (clock_cycle=2) -- kickoff de match_b
	service.advance_tick()        # clock=45 (clock_cycle=3) -- el ciclo marcado como Crazy

	EventBus.crazy_moment_triggered.disconnect(_on_crazy_moment_triggered)

	var state_a: MatchTickState = service.get_match_tick_state(match_a.match_id)
	var state_b: MatchTickState = service.get_match_tick_state(match_b.match_id)

	if state_a.current_tick_index == state_b.current_tick_index:
		_fail("el test no ejercita relojes divergentes de verdad: ambos partidos comparten current_tick_index=%d en el ciclo marcado como Crazy" % state_a.current_tick_index)

	if _trigger_count != 1:
		_fail("crazy_moment_triggered se emitió %d veces (esperado: 1) con current_tick_index=%d (match_a) y current_tick_index=%d (match_b) en el mismo ciclo de reloj -- el dedupe de RunState debe basarse en clock_cycle, no en tick_index_in_day" % [_trigger_count, state_a.current_tick_index, state_b.current_tick_index])

	service.queue_free()
	_finish()


func _on_crazy_moment_triggered(_context: CrazyBetContext) -> void:
	_trigger_count += 1


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] crazy_moment_dedupe_divergent_clocks_test: una sola emisión de crazy_moment_triggered con relojes por partido divergentes")
	else:
		push_error("[FAIL] crazy_moment_dedupe_divergent_clocks_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)
