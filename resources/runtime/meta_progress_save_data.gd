class_name MetaProgressSaveData extends Resource
## Recurso serializable usado por MetaProgress para persistir a user://save_meta.tres vía
## ResourceSaver/ResourceLoader. No es consumido directamente fuera de MetaProgress.

@export var current_run_number: int = 1
@export var unlocked_money_bonus_ids: Array[StringName] = []
