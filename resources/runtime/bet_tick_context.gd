class_name BetTickContext extends Resource
## Recurso de transporte emitido por el sistema de partidos (fuera de alcance de Épica B) y
## consumido por Épica B para decidir si el tick dispara Momento Crazy, y por la UI de apuestas.
## Ver .ai-studio/specs/_arquitectura-base.md sección 4.2.

@export var day: BettingDay.Day
@export var tick_index_in_day: int                 # 0-based, reinicia cada jornada
@export var available_markets: Array[MarketOffer]
