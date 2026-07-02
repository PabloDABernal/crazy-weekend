class_name MatchdayScheduler extends RefCounted
## Lógica pura de D.6 — asigna kickoff_offset_minutes a los partidos de una jornada y decide su
## schedule_kind (STAGGERED / CONCENTRATED). Sustituye el reparto ad-hoc de BettingRoot._split_
## matches_for_day (que sigue existiendo, pero ahora solo gobierna en qué DÍA cae cada partido, no A
## QUÉ HORA arranca dentro de ese día). Sin nodo, testeable aislada, mismo patrón que MatchTickEngine.
## Ver .ai-studio/specs/story-d6-calendario-horarios-escalonados.md secciones 4 y 4.1.


## Decide si la jornada es especial (CONCENTRATED) según su índice y LeagueRules.
## SPECIAL_MATCHDAY_EVERY_N, y asigna kickoff_offset_minutes + schedule_kind a los partidos de la
## jornada. Muta `matchday` in place (matchday.schedule_kind y cada MatchFixture.kickoff_offset_minutes
## de matchday.matches).
static func build_schedule(matchday: MatchdayFixture, rng: RandomNumberGenerator) -> void:
	if _is_concentrated_matchday(matchday.matchday_index):
		matchday.schedule_kind = MatchdayFixture.ScheduleKind.CONCENTRATED
		assign_concentrated_offsets(matchday.matches)
	else:
		matchday.schedule_kind = MatchdayFixture.ScheduleKind.STAGGERED
		assign_staggered_offsets(matchday.matches, rng)


static func _is_concentrated_matchday(matchday_index: int) -> bool:
	if matchday_index == LeagueRules.TOTAL_MATCHDAYS - 1:
		return true
	if LeagueRules.SPECIAL_MATCHDAY_EVERY_N > 0 and matchday_index > 0 and matchday_index % LeagueRules.SPECIAL_MATCHDAY_EVERY_N == 0:
		return true
	return false


## Reparte offsets escalonados (múltiplos de 15) entre los partidos de un día, tomándolos de
## LeagueRules.KICKOFF_OFFSETS_STAGGERED en un orden aleatorio de partidos (para que no sea siempre el
## mismo partido el que abre la jornada a la hora 0) y ciclando la lista si hay más partidos que
## offsets candidatos. Sin techo de solapamiento (sección 2.3): ningún límite fijo de partidos LIVE
## simultáneos.
##
## Garantía de arranque (sección 4.1, relación con Bug 1): SIEMPRE deja al menos un partido en offset
## 0. Sin esto, un día podría arrancar sin ningún partido LIVE, y el primer tick obligatorio de
## BettingRoot se quedaría sin ningún mercado legal donde apostar -- el mismo tipo de bloqueo que
## motivó el Bug 1, pero a nivel de jornada en vez de a nivel de mercado.
static func assign_staggered_offsets(matches: Array[MatchFixture], rng: RandomNumberGenerator) -> void:
	if matches.is_empty():
		return

	var shuffled: Array[MatchFixture] = matches.duplicate()
	ArrayUtils.shuffle(shuffled, rng)

	var offsets: Array[int] = LeagueRules.KICKOFF_OFFSETS_STAGGERED
	var has_zero_offset: bool = false
	for i in range(shuffled.size()):
		var offset: int = offsets[i % offsets.size()]
		shuffled[i].kickoff_offset_minutes = offset
		if offset == 0:
			has_zero_offset = true

	# Defensivo: si LeagueRules.KICKOFF_OFFSETS_STAGGERED cambiara en el futuro y dejara de incluir un
	# 0, la garantía de arranque se sigue cumpliendo forzando un partido a offset 0.
	if not has_zero_offset:
		shuffled[0].kickoff_offset_minutes = 0

	_assert_no_live_coverage_gap(shuffled)


## Invariante estructural (no accidente de los valores actuales de LeagueRules.
## KICKOFF_OFFSETS_STAGGERED): en CADA ciclo de reloj de la jornada debe haber al menos 1 partido
## LIVE, o el gate de tick obligatorio de BettingRoot se queda sin ningún mercado legal donde apostar
## -- el mismo bloqueo que motivó el Bug 1. La garantía de offset 0 de arriba solo cubre el primer
## ciclo; esto cubre los siguientes: mientras el hueco entre dos kickoffs consecutivos (ordenados) no
## exceda la ventana LIVE de un partido (TICKS_PER_MATCH * MATCH_MINUTES_PER_TICK), el partido que
## abrió el hueco sigue LIVE cuando arranca el siguiente, así que nunca hay un ciclo sin ningún LIVE.
## Si KICKOFF_OFFSETS_STAGGERED cambiara a un espaciado mayor, esta aserción debe fallar en vez de
## dejar pasar un deadlock silencioso.
static func _assert_no_live_coverage_gap(matches: Array[MatchFixture]) -> void:
	var used_offsets: Array[int] = []
	for match_fixture in matches:
		if not used_offsets.has(match_fixture.kickoff_offset_minutes):
			used_offsets.append(match_fixture.kickoff_offset_minutes)
	used_offsets.sort()

	var max_gap_allowed: int = LeagueRules.TICKS_PER_MATCH * LeagueRules.MATCH_MINUTES_PER_TICK
	for i in range(1, used_offsets.size()):
		var gap: int = used_offsets[i] - used_offsets[i - 1]
		assert(gap <= max_gap_allowed, "MatchdayScheduler: hueco de %d min entre kickoffs %d y %d excede la ventana LIVE de un partido (%d min) -- puede reintroducir el deadlock del Bug 1 (ningún partido LIVE en algún ciclo de reloj)" % [gap, used_offsets[i - 1], used_offsets[i], max_gap_allowed])


## Jornada especial (CONCENTRATED / "Super Sunday"): todos los partidos comparten el mismo kickoff
## (offset 0), concentrando la máxima audiencia posible en un único arranque simultáneo.
static func assign_concentrated_offsets(matches: Array[MatchFixture]) -> void:
	for match_fixture in matches:
		match_fixture.kickoff_offset_minutes = 0
