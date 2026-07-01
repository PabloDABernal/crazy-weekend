class_name MatchFixture extends Resource
## Un partido concreto de una jornada (par de equipos). Ver
## .ai-studio/specs/epic-d-liga-y-partidos.md sección 2.3.

@export var match_id: StringName                # único por temporada, ej. "s1_md3_m7"
@export var home_team_id: StringName
@export var away_team_id: StringName
