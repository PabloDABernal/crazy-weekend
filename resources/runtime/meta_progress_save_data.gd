class_name MetaProgressSaveData extends Resource
## Recurso serializable usado por MetaProgress para persistir a user://save_meta.tres vía
## ResourceSaver/ResourceLoader. No es consumido directamente fuera de MetaProgress.

@export var current_run_number: int = 1
@export var unlocked_money_bonus_ids: Array[StringName] = []

# --- Épica A — Tipos de victoria ---
@export var victory_category_states: Array[VictoryCategoryState] = []
@export var final_ending_triggered: bool = false
@export var final_ending_triggered_at_run_number: int = -1
