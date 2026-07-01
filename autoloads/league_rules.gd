extends Node
## LeagueRules (autoload) — constantes y curvas de balance de la generación de liga/partidos (Épica D).
## Objeto de configuración sin estado mutable de instancia, análogo a EconomyRules pero para el dominio
## de liga/deportes (dueño de contenido distinto: Game Designer de liga, no de economía).
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md secciones 2.5 y 5.2.

# --- D.1 — Generación de liga ---
const TEAM_COUNT: int = 20
const STAR_TEAM_COUNT: int = 4
const OFFENSE_DEFENSE_RANGE_STAR: Vector2 = Vector2(0.65, 0.95)
const OFFENSE_DEFENSE_RANGE_NORMAL: Vector2 = Vector2(0.25, 0.75)
const SQUAD_SIZE_PER_TEAM: int = 18
const TOTAL_MATCHDAYS: int = 38
const TICKS_PER_MATCH: int = 6
const MATCH_MINUTES_PER_TICK: int = 15

# --- D.3 — Motor de simulación de partido ---
const BASE_FOULS_PER_TICK_RANGE: Vector2 = Vector2(0.0, 3.0)
const BASE_CARDS_PER_TICK_CHANCE: float = 0.12
const BASE_CORNERS_PER_TICK_RANGE: Vector2 = Vector2(0.0, 2.0)

# --- D.3 — Umbrales candidatos para mercados over/under de umbral variable por partido ---
const CARDS_THRESHOLDS: Array[float] = [3.5, 4.5]
const FOULS_THRESHOLDS: Array[float] = [19.5, 22.5]

# --- D.5 — Margen de casa y rango visible de probabilidades ---
const ODDS_DISPLAY_RANGE_WIDTH_BASE: float = 0.20
const ODDS_DISPLAY_RANGE_WIDTH_VARIATION: float = 0.05
const ODDS_DISPLAY_RANGE_WIDTH_MAX_POSSIBLE: float = 0.35

const HOUSE_MARGIN_BY_MARKET: Dictionary = {
	"1x2": 0.06, "goals_ou_1_5": 0.05, "goals_ou_2_5": 0.05, "goals_ou_3_5": 0.06,
	"first_scorer": 0.10, "btts": 0.05, "cards_ou": 0.07, "fouls_ou": 0.07,
}

const HOUSE_MARGIN_SUNDAY_MULTIPLIER: float = 1.3   # "restricciones de domingo: márgenes de casa aumentan"

const HOUSE_MARGIN_PHASE_INCREMENT: Dictionary = {
	NarrativePhase.Phase.PHASE_1: 0.0, NarrativePhase.Phase.PHASE_2: 0.0,
	NarrativePhase.Phase.PHASE_3: 0.02, NarrativePhase.Phase.PHASE_4: 0.05,
}
