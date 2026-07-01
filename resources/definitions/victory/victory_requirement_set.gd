class_name VictoryRequirementSet extends Resource
## Lista configurable de categorías que cierran el final canónico (A.9). VictoryTracker no cuenta
## "categorías hardcodeadas por nombre": cuenta cuántas entradas de este set están unlocked. Pasar de
## la versión MVP (6 categorías) a la versión completa (8) es editar/reasignar este recurso, no tocar
## _check_final_ending().
## Ver .ai-studio/specs/epic-a-tipos-de-victoria.md sección 1.3.

@export var set_id: StringName                       # ej. "mvp_6of8" — versionado explícito, no implícito
@export var required_categories: Array[VictoryCategoryDef] = []
