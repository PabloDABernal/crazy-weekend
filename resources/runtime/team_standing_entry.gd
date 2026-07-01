class_name TeamStandingEntry extends Resource
## Entrada de tabla de posiciones de un equipo. Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 2.2.
##
## last_5_results se implementa como cola FIFO de tamaño máximo 5 (append + pop_front si size() > 5),
## no como ventana calculada sobre historial completo.

@export var team_id: StringName
@export var points: int = 0
@export var goals_for: int = 0
@export var goals_against: int = 0
@export var matches_played: int = 0
@export var last_5_results: Array[int] = []   # 0=derrota,1=empate,3=victoria; array de máx 5, FIFO
