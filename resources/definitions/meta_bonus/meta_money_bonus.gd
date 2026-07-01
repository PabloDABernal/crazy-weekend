class_name MetaMoneyBonus extends Resource
## Definición de un desbloqueo de "+X$ al empezar", versionable en editor como .tres.
## MetaProgress guarda solo la lista de bonus_id desbloqueados; el amount se resuelve contra
## esta definición en tiempo de ejecución. Ver .ai-studio/specs/epic-b-economia-de-run.md sección B.1.

@export var bonus_id: StringName        # ej. "bonus_investigacion_1", "bonus_hito_10k"
@export var amount: int                 # cuánto dinero inicial adicional otorga, permanente
@export var unlock_source: String       # texto libre para trazabilidad
