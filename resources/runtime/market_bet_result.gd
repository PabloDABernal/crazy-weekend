class_name MarketBetResult extends Resource
## Recurso de transporte de una apuesta ya resuelta (ganada o perdida). Análogo a MarketOffer pero
## para el resultado. Contrato fijado por Épica A (epic-a-tipos-de-victoria.md sección 2.1); creado
## aquí porque Épica D (MarketBetResultBuilder) es quien primero necesita construir instancias reales.
## Emitido vía EventBus.market_bet_resolved por la UI de apuestas (Épica E), usando
## MarketBetResultBuilder.build_result() (ver res://scripts/league/market_bet_result_builder.gd).

@export var market_id: StringName          # ver MarketCatalog para los market_id relevantes al MVP
@export var match_id: StringName
@export var matchday_id: StringName        # jornada — necesario para A.4
@export var won: bool
@export var run_number: int
@export var context_tags: Array[StringName] = []  # tags que describen condiciones del partido/apuesta
                                                    # relevantes para retos de desbloqueo, ej.:
                                                    #   "underdog_win" -> A.1
                                                    #   "dirty_match_fouls_gt_20" -> A.5
