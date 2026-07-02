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
	_shuffle(shuffled, rng)

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


## Jornada especial (CONCENTRATED / "Super Sunday"): todos los partidos comparten el mismo kickoff
## (offset 0), concentrando la máxima audiencia posible en un único arranque simultáneo.
static func assign_concentrated_offsets(matches: Array[MatchFixture]) -> void:
	for match_fixture in matches:
		match_fixture.kickoff_offset_minutes = 0


static func _shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
