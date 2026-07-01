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
## Emitida por MatchSimulationService (Épica E, fix de integración) INMEDIATAMENTE ANTES de
## bet_tick_opened para el mismo match_id, dentro de advance_tick(). Firma extendida con match_id
## (la resolución es por partido, no solo por índice de tick global, porque hay varios partidos en
## paralelo con tick abierto el mismo momento -- ver epic-e-pantalla-de-apuestas.md sección 4).
## Propósito: separar "se resolvió el tick anterior de este partido" (PendingBetsTracker acredita
## payouts pendientes) de "se abrió el tick nuevo" (bet_tick_opened), para que RunState acredite el
## dinero de una apuesta ganadora ANTES de evaluar StakeResolver.is_run_dead() en su propio handler de
## bet_tick_opened -- evita que el orden de conexión entre autoload (RunState) y escena (BettingRoot)
## sobre la MISMA señal decida si el jugador muere antes o después de cobrar un pago que lo salvaba.
signal bet_tick_resolved(match_id: StringName, tick_index: int)
signal crazy_moment_triggered(crazy_bet: CrazyBetContext)
signal crazy_moment_ended()
signal run_ended(result: RunResult)                       # victoria o derrota, incluye motivo

# --- Épica D — Simulación de liga y partidos ---
signal matchday_finished(matchday_index: int)   # emitido por MatchSimulationService al terminar los 6 ticks de todos los partidos del día
signal market_bet_resolved(result: MarketBetResult)   # emitido por la UI de apuestas (Épica E) usando MarketBetResultBuilder (Épica D)

# --- Épica A — Tipos de victoria ---
signal victory_category_unlocked(category_id: StringName, run_number: int)  # emitido por VictoryTracker, consumido por Épica C (Expediente)
signal final_ending_triggered(run_number: int)                              # emitido por VictoryTracker al completarse VictoryTracker.active_requirement_set
