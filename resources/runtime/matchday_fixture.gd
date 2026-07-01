class_name MatchdayFixture extends Resource
## Una jornada completa (~10 partidos, todos los equipos juegan exactamente una vez). Ver
## .ai-studio/specs/epic-d-liga-y-partidos.md sección 2.3.

@export var matchday_index: int                 # 0-based, 0-37
@export var matches: Array[MatchFixture]        # ~10 partidos, todos los equipos juegan exactamente una vez
