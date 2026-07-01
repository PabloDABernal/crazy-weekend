class_name VictoryCategoryFlavor extends Resource
## Contenido narrativo de una categoría de tipo de victoria (dato de diseño, nuevo en Épica C).
## Separado deliberadamente de VictoryCategoryDef (Épica A): este recurso es puro contenido/copy,
## no criterio de evaluación. Indexado por el mismo category_id que VictoryCategoryDef.
## Ver .ai-studio/specs/epic-c-tu-expediente.md sección 1.1.

@export var category_id: StringName            # debe matchear un VictoryCategoryDef.category_id existente,
												 # o un id reservado para categoría post-MVP (ver spec 2.3)
@export var display_name: String                # duplicado deliberado de VictoryCategoryDef.display_name —
												 # ver nota en la spec sección 1.1
@export var sealed_hint_text: String            # pista ambigua, SIEMPRE visible aunque la categoría esté bloqueada
@export var unlocked_flavor_text_template: String
	# plantilla con placeholders resueltos por CategorySlot al montar el estado UNLOCKED.
	# placeholders soportados: {fecha} (de VictoryCategoryState.unlocked_at_date),
	#                          {run} (de VictoryCategoryState.unlocked_at_run_number)
@export var unlocked_criteria_text: String      # descripción en lenguaje natural del criterio YA CUMPLIDO,
												 # mostrada solo en estado UNLOCKED (nunca antes)
