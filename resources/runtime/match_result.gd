class_name MatchResult extends Resource
## Resultado final agregado de un partido ya completado (tick_index == 5 / minuto 90), consumido por
## LeagueState.apply_matchday_results() para actualizar standings y estadísticas de jugador (D.2).
## Se construye a partir del MatchTickState final de un partido — ver
## .ai-studio/specs/epic-d-liga-y-partidos.md sección 10.

@export var match_id: StringName
@export var home_team_id: StringName
@export var away_team_id: StringName
@export var home_goals: int = 0
@export var away_goals: int = 0
@export var cards_home: int = 0
@export var cards_away: int = 0
@export var goal_scorers: Array[StringName] = []   # player_id, en orden — para acumular season_goals
@export var carded_player_ids: Array[StringName] = []  # player_id de cada jugador que recibió tarjeta este partido
