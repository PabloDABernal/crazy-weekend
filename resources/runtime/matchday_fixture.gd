class_name MatchdayFixture extends Resource
## Una jornada completa (~10 partidos, todos los equipos juegan exactamente una vez). Ver
## .ai-studio/specs/epic-d-liga-y-partidos.md sección 2.3.

@export var matchday_index: int                 # 0-based, 0-37
@export var matches: Array[MatchFixture]        # ~10 partidos, todos los equipos juegan exactamente una vez

## D.6 -- STAGGERED (por defecto): horarios de kickoff escalonados dentro de la ventana del día.
## CONCENTRATED: jornada especial ("Super Sunday"): varios/todos los partidos comparten kickoff, y
## BettingRoot los concentra en un único día en vez del reparto en tercios habitual. Asignado por
## MatchdayScheduler al generar el calendario.
enum ScheduleKind { STAGGERED, CONCENTRATED }
@export var schedule_kind: ScheduleKind = ScheduleKind.STAGGERED
