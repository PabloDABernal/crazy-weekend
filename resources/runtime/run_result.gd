class_name RunResult extends Resource
## Resultado económico de una run puntual. Usado por RunState.end_run() y EventBus.run_ended.
## Ver .ai-studio/specs/_arquitectura-base.md sección 3.1.

## "WON" = llegó a domingo con dinero > 0. No implica ninguna categoría de Épica A.
enum Outcome { WON, LOST_BANKRUPT }

@export var outcome: Outcome
@export var final_money: int
@export var peak_money: int
@export var run_number: int
