class_name VictoryCategoryState extends Resource
## Estado runtime de una categoría de tipo de victoria (una instancia por categoría), gestionado por
## VictoryTracker y persistido como parte del save de MetaProgress (user://save_meta.tres).
## Ver .ai-studio/specs/epic-a-tipos-de-victoria.md sección 1.2.

@export var category_id: StringName
@export var unlocked: bool = false
@export var unlocked_at_run_number: int = -1     # -1 si no desbloqueada
@export var unlocked_at_date: String = ""        # ISO8601, para flavor text del Expediente (Épica C)

# Contadores — MARKET_HIT_COUNT / MARKET_HIT_DISTINCT_MATCHDAY
@export var persistent_hit_count: int = 0        # usado si counter_scope == PERSISTENT (A.2)
@export var per_run_hit_count: int = 0           # usado si counter_scope == PER_RUN (A.3); se resetea en cada run_started
@export var matchday_hits: Dictionary = {}       # { matchday_id: Array[match_id] } — para MARKET_HIT_DISTINCT_MATCHDAY (A.4)

# Sub-hitos — solo economic_milestone_slot (A.8)
@export var milestone_reached: Dictionary = {}   # { 10000: bool, 100000: bool, 1000000: bool } — persistente, para completismo del Expediente
