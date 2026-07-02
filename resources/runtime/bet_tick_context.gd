class_name BetTickContext extends Resource
## Recurso de transporte emitido por el sistema de partidos (fuera de alcance de Épica B) y
## consumido por Épica B para decidir si el tick dispara Momento Crazy, y por la UI de apuestas.
## Ver .ai-studio/specs/_arquitectura-base.md sección 4.2.

@export var day: BettingDay.Day
@export var tick_index_in_day: int                 # 0-based, reinicia cada jornada -- índice de tick PROPIO del partido de available_markets[0] (D.6: ya no es común a todos los partidos del día, cada uno tiene su propio reloj de kickoff)
## D.6 -- ciclo de reloj GLOBAL de la jornada (0 al abrir el día, +1 por cada MatchSimulationService.
## advance_tick() invocado), común a TODOS los BetTickContext emitidos dentro de la misma llamada a
## open_initial_tick()/advance_tick(), a diferencia de tick_index_in_day (que sí varía de partido a
## partido una vez los kickoffs se escalonan). Es la clave correcta para deduplicar "este tick global ya
## disparó su Momento Crazy" (ver RunState) -- tick_index_in_day dejó de servir para eso con D.6.
@export var clock_cycle: int = 0
@export var available_markets: Array[MarketOffer]
