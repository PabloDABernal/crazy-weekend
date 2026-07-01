class_name MarketOffer extends Resource
## Recurso mínimo para identificar un mercado ofertado en un tick de apuestas.
## Ver .ai-studio/specs/_arquitectura-base.md sección 4.4.

@export var market_id: StringName          # ej. "1x2", "goals_ou_2_5", "cards_ou", "fouls_ou"
@export var match_id: StringName
@export var displayed_probability_min: float
@export var displayed_probability_max: float
@export var confidence: float               # 0.0-1.0, qué tan "informado" está el jugador de este mercado
