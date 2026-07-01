class_name CrazyBetContext extends Resource
## Emitido por EventBus.crazy_moment_triggered para que la UI de apuestas sepa que debe forzar el
## stake y restringir mercados durante un Momento Crazy.
## Ver .ai-studio/specs/epic-b-economia-de-run.md sección B.3.

enum StakePercentage { FIFTY = 50, SEVENTY = 70, ONE_HUNDRED = 100 }

@export var stake_percentage: StakePercentage
@export var forced_stake_amount: int               # = current_money * percentage/100, redondeado hacia arriba
@export var allowed_market_ids: Array[StringName]   # 1-2 mercados, nunca incluye el excluido
@export var excluded_market_id: StringName          # el mercado identificado como "más seguro", para debug/UI
