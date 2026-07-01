class_name MarketOffer extends Resource
## Recurso mínimo para identificar un mercado ofertado en un tick de apuestas.
## Ver .ai-studio/specs/_arquitectura-base.md sección 4.4.
## Extendido por Épica D (option_key, threshold_display) — ver
## .ai-studio/specs/epic-d-liga-y-partidos.md sección 6. Un MarketOffer = una opción apostable
## (ej. 3 instancias con market_id="1x2", una por option_key en {"home","draw","away"}).

@export var market_id: StringName          # ej. "1x2", "goals_ou_2_5", "cards_ou", "fouls_ou"
@export var match_id: StringName
@export var displayed_probability_min: float
@export var displayed_probability_max: float
@export var confidence: float               # 0.0-1.0, qué tan "informado" está el jugador de este mercado

@export var option_key: StringName          # ej. "home"/"draw"/"away", "over"/"under"
@export var threshold_display: float = -1.0 # umbral de over/under a mostrar; -1.0 (sentinel) si no aplica
