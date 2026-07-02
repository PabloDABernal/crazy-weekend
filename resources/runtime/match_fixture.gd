class_name MatchFixture extends Resource
## Un partido concreto de una jornada (par de equipos). Ver
## .ai-studio/specs/epic-d-liga-y-partidos.md sección 2.3.

@export var match_id: StringName                # único por temporada, ej. "s1_md3_m7"
@export var home_team_id: StringName
@export var away_team_id: StringName

## D.6 -- offset de kickoff en minutos, múltiplo de 15 (misma rejilla que
## LeagueRules.MATCH_MINUTES_PER_TICK), dentro de la ventana del día en que se juega. Asignado por
## MatchdayScheduler al generar el calendario. 0 = arranca con el primer advance_tick del día.
@export var kickoff_offset_minutes: int = 0
