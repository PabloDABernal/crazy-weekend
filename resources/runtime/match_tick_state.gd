class_name MatchTickState extends Resource
## Estado acumulado de un partido tras resolver 0 o más ticks. Ver
## .ai-studio/specs/epic-d-liga-y-partidos.md sección 4.1.

@export var match_id: StringName
@export var home_team_id: StringName
@export var away_team_id: StringName
@export var current_tick_index: int = 0        # 0-5
@export var current_minute: int = 0            # 0, 15, 30, 45, 60, 75, 90 tras cada tick
@export var home_goals: int = 0
@export var away_goals: int = 0
@export var possession_home_pct: float = 50.0   # acumulado, se re-normaliza cada tick
@export var shots_on_target_home: int = 0
@export var shots_on_target_away: int = 0
@export var cards_home: int = 0
@export var cards_away: int = 0
@export var corners_home: int = 0               # solo estadística de panel, ver decisión 6 de la spec
@export var corners_away: int = 0
@export var fouls_home: int = 0
@export var fouls_away: int = 0
@export var goal_scorers: Array[StringName] = []  # player_id, en orden — para mercado first_scorer
@export var tick_events: Array[MatchTickEvent] = []  # eventos discretos SOLO del tick recién resuelto (se reemplaza cada tick, no acumula)
