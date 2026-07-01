class_name LeagueSaveData extends Resource
## Recurso serializable usado por LeagueState para persistir a user://save_league.tres vía
## ResourceSaver/ResourceLoader. No es consumido directamente fuera de LeagueState.
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 2 (decisión de archivo separado de save_meta.tres).

@export var teams: Array[TeamDef] = []
@export var calendar: Array[MatchdayFixture] = []
@export var standings: Dictionary = {}                  # team_id (StringName) -> TeamStandingEntry
@export var current_matchday_index: int = 0
@export var current_season_number: int = 1
