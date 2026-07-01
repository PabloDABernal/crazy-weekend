class_name PlayerDef extends Resource
## Jugador ficticio de una plantilla de equipo. Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 2.1.

enum Position { GOALKEEPER, DEFENDER, MIDFIELDER, FORWARD }

@export var player_id: StringName
@export var display_name: String
@export var team_id: StringName
@export var position: Position
@export var avg_goals_per_match: float    # media de goles por partido, ya diferenciada por posición al generar
@export var card_probability: float       # 0.0-1.0, probabilidad de recibir tarjeta en un partido

# Estadísticas acumuladas de temporada — actualizadas por D.2, no en la generación inicial (D.1)
@export var season_goals: int = 0
@export var season_cards: int = 0
@export var season_matches_played: int = 0
