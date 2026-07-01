class_name TeamDef extends Resource
## Equipo ficticio de la liga. Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 2.1.

@export var team_id: StringName          # ej. "real_madrileno", "fc_barceloneta"
@export var display_name: String         # "Real Madrileño"
@export var offense: float                # 0.0-1.0
@export var defense: float                # 0.0-1.0
@export var current_form: float           # 0.0-1.0, se recalcula en cada apply_matchday_results (D.2)
@export var home_advantage: float         # 0.0-1.0, factor local — constante por equipo, no cambia jornada a jornada
@export var is_star_team: bool            # true para equipos con peso hacia jerarquía reconocible (ver 2.4)
@export var squad: Array[PlayerDef]
