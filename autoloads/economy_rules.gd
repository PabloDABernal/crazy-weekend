extends Node
## EconomyRules (autoload) — constantes y curvas de balance de la economía de run (Épica B).
## Objeto de configuración sin estado mutable de instancia; toda la lógica de cálculo pura vive en
## res://scripts/economy/ (StakeResolver, CrazyBetResolver, CrazyMomentScheduler), que consumen estas
## constantes por parámetro o acceso directo a este autoload.
## Ver .ai-studio/specs/_arquitectura-base.md sección 2.5 y .ai-studio/specs/epic-b-economia-de-run.md.

# --- B.1 — Dinero inicial ---
const BASE_STARTING_MONEY: int = 500

# --- B.2 — Stake mínimo / all-in / muerte de run ---
const MINIMUM_STAKE: int = 50

# --- B.3 — Momento Crazy: pesos de stake_percentage por fase narrativa ---
# Pesos relativos (no necesitan sumar 100, se normalizan al usarlos).
const CRAZY_BET_WEIGHTS_BY_PHASE: Dictionary = {
	NarrativePhase.Phase.PHASE_1: {50: 60, 70: 30, 100: 10},
	NarrativePhase.Phase.PHASE_2: {50: 60, 70: 30, 100: 10},
	NarrativePhase.Phase.PHASE_3: {50: 45, 70: 35, 100: 20},
	NarrativePhase.Phase.PHASE_4: {50: 35, 70: 30, 100: 35},
}

const CRAZY_BET_MAX_ALLOWED_MARKETS: int = 2
const CRAZY_BET_MIN_ALLOWED_MARKETS: int = 1

# --- B.4 — Cadencia de Momento Crazy por fase narrativa ---
# Claves distintas de las 4 fases granulares de NarrativePhase a propósito (ver nota en
# _arquitectura-base.md sección 2.3): "phase_1_2" combina PHASE_1 y PHASE_2.
const CRAZY_MOMENT_SCHEDULE_BY_PHASE: Dictionary = {
	# runs 1-12 (Fase 1 y 2 combinadas a efectos de cadencia de Momento Crazy)
	"phase_1_2": {"count": 1, "allowed_days": [BettingDay.Day.SATURDAY]},
	# runs 13-20 (Fase 3)
	"phase_3": {"count": 2, "allowed_days": [BettingDay.Day.SATURDAY, BettingDay.Day.SUNDAY]},
	# runs 21+ (Fase 4)
	"phase_4": {"count_min": 2, "count_max": 3, "allowed_days": [BettingDay.Day.FRIDAY, BettingDay.Day.SATURDAY, BettingDay.Day.SUNDAY]},
}

const CRAZY_MOMENT_MIN_TICK_INDEX: int = 1   # 0-based; índice 0 (primer tick del día) queda excluido siempre
const TICKS_PER_DAY: int = 6                 # 90 min / 15 min, ver game-design.md
