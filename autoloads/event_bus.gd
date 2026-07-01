extends Node
## EventBus (autoload) — bus de señales globales, sin estado propio.
## Desacopla los autoloads de estado (RunState, MetaProgress, etc.) de las escenas de UI/gameplay.
## Todas las señales que cruzan el límite "autoload -> escena" o "autoload -> autoload" pasan por aquí.
## Ver .ai-studio/specs/_arquitectura-base.md sección 2.1.
##
## Otras épicas (A, C, D, E) añadirán sus propias señales a este mismo autoload sin tocar las de Épica B.

signal run_started(starting_money: int, run_number: int)
signal money_changed(new_amount: int, delta: int, reason: String)
signal bet_tick_opened(context: BetTickContext)          # el tick service anuncia que hay que apostar
signal bet_tick_resolved(tick_index: int)
signal crazy_moment_triggered(crazy_bet: CrazyBetContext)
signal crazy_moment_ended()
signal run_ended(result: RunResult)                       # victoria o derrota, incluye motivo

# --- Épica D — Simulación de liga y partidos ---
signal matchday_finished(matchday_index: int)   # emitido por MatchSimulationService al terminar los 6 ticks de todos los partidos del día
signal market_bet_resolved(result: MarketBetResult)   # emitido por la UI de apuestas (Épica E) usando MarketBetResultBuilder (Épica D)
