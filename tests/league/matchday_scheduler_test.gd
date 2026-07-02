extends SceneTree
## Test de MatchdayScheduler (D.6) -- generación de horarios escalonados, jornada especial concentrada,
## y la garantía de arranque (invariante anti-bloqueo, sección 4.1). Ver
## .ai-studio/specs/story-d6-calendario-horarios-escalonados.md secciones 4 y 4.1.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/league/matchday_scheduler_test.gd

func _init() -> void:
	var failures: Array[String] = []

	_test_staggered_offsets_are_multiples_of_tick(failures)
	_test_staggered_always_has_at_least_one_offset_zero(failures)
	_test_staggered_guarantee_holds_across_many_seeds_and_sizes(failures)
	_test_concentrated_all_matches_share_offset(failures)
	_test_build_schedule_marks_last_matchday_as_concentrated(failures)
	_test_build_schedule_marks_normal_matchday_as_staggered(failures)
	_test_build_schedule_never_leaves_a_matchday_without_a_live_start(failures)

	if failures.is_empty():
		print("[PASS] matchday_scheduler_test: todos los checks OK")
	else:
		push_error("[FAIL] matchday_scheduler_test: %d fallo(s)" % failures.size())
		for failure in failures:
			push_error("  - " + failure)

	quit(0 if failures.is_empty() else 1)


func _build_matches(count: int) -> Array[MatchFixture]:
	var matches: Array[MatchFixture] = []
	for i in range(count):
		var match_fixture := MatchFixture.new()
		match_fixture.match_id = StringName("m%d" % i)
		match_fixture.home_team_id = StringName("home_%d" % i)
		match_fixture.away_team_id = StringName("away_%d" % i)
		matches.append(match_fixture)
	return matches


func _test_staggered_offsets_are_multiples_of_tick(failures: Array[String]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var matches := _build_matches(10)

	MatchdayScheduler.assign_staggered_offsets(matches, rng)

	for match_fixture in matches:
		if match_fixture.kickoff_offset_minutes % LeagueRules.MATCH_MINUTES_PER_TICK != 0:
			failures.append("kickoff_offset_minutes=%d no es múltiplo de MATCH_MINUTES_PER_TICK (%d)" % [match_fixture.kickoff_offset_minutes, LeagueRules.MATCH_MINUTES_PER_TICK])


## Garantía de arranque (sección 4.1): sin esto, un día podría quedar sin ningún partido LIVE al
## empezar, y el primer tick obligatorio de BettingRoot se quedaría sin mercado legal (bloqueo del
## mismo tipo que motivó el Bug 1).
func _test_staggered_always_has_at_least_one_offset_zero(failures: Array[String]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var matches := _build_matches(10)

	MatchdayScheduler.assign_staggered_offsets(matches, rng)

	var has_zero: bool = false
	for match_fixture in matches:
		if match_fixture.kickoff_offset_minutes == 0:
			has_zero = true
			break

	if not has_zero:
		failures.append("assign_staggered_offsets no dejó ningún partido en offset 0 -- invariante anti-bloqueo violada")


## Barrido de semillas y tamaños de jornada (incluidos casos límite: 1 partido, más partidos que
## offsets candidatos en LeagueRules.KICKOFF_OFFSETS_STAGGERED) para reducir la chance de que un caso
## puntual oculte una regresión de la garantía de arranque.
func _test_staggered_guarantee_holds_across_many_seeds_and_sizes(failures: Array[String]) -> void:
	var sizes: Array[int] = [1, 2, 9, 10, 11, 23]
	for size in sizes:
		for seed_value in range(0, 15):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var matches := _build_matches(size)

			MatchdayScheduler.assign_staggered_offsets(matches, rng)

			var has_zero: bool = false
			for match_fixture in matches:
				if match_fixture.kickoff_offset_minutes == 0:
					has_zero = true
					break

			if not has_zero:
				failures.append("size=%d seed=%d: ningún partido en offset 0" % [size, seed_value])


func _test_concentrated_all_matches_share_offset(failures: Array[String]) -> void:
	var matches := _build_matches(10)

	MatchdayScheduler.assign_concentrated_offsets(matches)

	var shared_offset: int = matches[0].kickoff_offset_minutes
	for match_fixture in matches:
		if match_fixture.kickoff_offset_minutes != shared_offset:
			failures.append("assign_concentrated_offsets dejó offsets distintos: %d vs %d" % [match_fixture.kickoff_offset_minutes, shared_offset])


func _test_build_schedule_marks_last_matchday_as_concentrated(failures: Array[String]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5

	var matchday := MatchdayFixture.new()
	matchday.matchday_index = LeagueRules.TOTAL_MATCHDAYS - 1
	matchday.matches = _build_matches(10)

	MatchdayScheduler.build_schedule(matchday, rng)

	if matchday.schedule_kind != MatchdayFixture.ScheduleKind.CONCENTRATED:
		failures.append("la última jornada de la temporada debería quedar CONCENTRATED (obtenido: %d)" % matchday.schedule_kind)


func _test_build_schedule_marks_normal_matchday_as_staggered(failures: Array[String]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5

	var matchday := MatchdayFixture.new()
	matchday.matchday_index = 3
	matchday.matches = _build_matches(10)

	MatchdayScheduler.build_schedule(matchday, rng)

	if matchday.schedule_kind != MatchdayFixture.ScheduleKind.STAGGERED:
		failures.append("una jornada normal (índice 3) debería quedar STAGGERED (obtenido: %d)" % matchday.schedule_kind)


## Invariante anti-bloqueo end-to-end: cualquier jornada que salga de build_schedule (STAGGERED o
## CONCENTRATED) deja al menos un partido en offset 0, sin importar el índice de jornada.
func _test_build_schedule_never_leaves_a_matchday_without_a_live_start(failures: Array[String]) -> void:
	for matchday_index in [0, 1, 3, 10, LeagueRules.TOTAL_MATCHDAYS - 1]:
		var rng := RandomNumberGenerator.new()
		rng.seed = matchday_index * 31 + 1

		var matchday := MatchdayFixture.new()
		matchday.matchday_index = matchday_index
		matchday.matches = _build_matches(10)

		MatchdayScheduler.build_schedule(matchday, rng)

		var has_zero: bool = false
		for match_fixture in matchday.matches:
			if match_fixture.kickoff_offset_minutes == 0:
				has_zero = true
				break

		if not has_zero:
			failures.append("matchday_index=%d (schedule_kind=%d): ningún partido en offset 0 tras build_schedule" % [matchday_index, matchday.schedule_kind])
