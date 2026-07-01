class_name InterrunDecisionOption extends Resource
## Una opción de la decisión conversacional simplificada de la fase inter-run (E.6). Dato de diseño,
## editable en editor.
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 8.3/8.4.

@export var option_id: StringName
@export var prompt_text: String            # texto de la opción tal como la ve el jugador
@export var flavor_text: String            # línea breve de sabor narrativo (opcional, puede quedar vacía)
@export var money_bonus_amount: int        # monto de dinero extra otorgado, efecto mecánico único en esta versión
