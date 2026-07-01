class_name VictoryCategoryDef extends Resource
## Definición estática de una categoría de tipo de victoria (dato de diseño, editable en editor por
## Game Designer/Coordinator sin tocar código). Un único recurso describe qué hay que cumplir de forma
## declarativa (tipo de criterio + parámetros); VictoryTracker._evaluate_category() interpreta estos
## parámetros de forma genérica, sin código por categoría.
## Ver .ai-studio/specs/epic-a-tipos-de-victoria.md sección 1.1.

enum Family { MARKET, ECONOMIC_MILESTONE }  # Familia A / Familia B, ver glossary.md

enum CriterionType {
	MARKET_HIT_WITH_TAG,           # acierto de un mercado + el partido/contexto cumple un tag específico (A.1, A.5)
	MARKET_HIT_COUNT,              # N aciertos acumulados del mismo mercado, ámbito configurable (A.2, A.3)
	MARKET_HIT_DISTINCT_MATCHDAY,  # N aciertos del mismo mercado en partidos distintos de la misma jornada (A.4)
	MONEY_THRESHOLD_ANY,           # superar cualquiera de N umbrales de dinero dentro de una run (A.8, vía sub-hitos)
}

enum CounterScope { PERSISTENT, PER_RUN }

@export var category_id: StringName          # ej. "victory_base", "victory_medias", "victory_goles",
											   # "victory_tarjetas", "victory_faltas", "economic_milestone_slot"
@export var display_name: String              # "Victoria de Base", etc. — usado por Épica C
@export var family: Family
@export var criterion_type: CriterionType

# Parámetros del criterio — solo los relevantes al criterion_type elegido se usan; el resto quedan en default.
@export var market_id: StringName             # ej. "1x2", "goals_ou_2_5", "goals_ou" (genérico goles), "cards_ou", "fouls_ou"
@export var required_tag: StringName          # ej. "underdog_win" (A.1), "dirty_match_fouls_gt_20" (A.5)
@export var required_count: int               # ej. 3 (A.2), 5 (A.3), 3 (A.4)
@export var counter_scope: CounterScope        # ver CounterScope — PERSISTENT (A.2) vs PER_RUN (A.3, A.4)
@export var money_thresholds: Array[int] = []  # ej. [10000, 100000, 1000000] — solo A.8
