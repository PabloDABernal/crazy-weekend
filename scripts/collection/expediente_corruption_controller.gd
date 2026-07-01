class_name ExpedienteCorruptionController extends Node
## Capa de presentación pura del deterioro por fase narrativa de "Tu Expediente" (Épica C, historia C.2).
## Consulta NarrativePhase.get_current_phase() una sola vez en _ready() (llamada desde
## ExpedienteScreen._ready() vía apply_current_phase()) y aplica overlays visuales sobre la grilla ya
## construida, sin conocer el contenido de ninguna categoría.
## Ver .ai-studio/specs/epic-c-tu-expediente.md sección 3.2/3.3.

## Debe matchear el category_id del .tres res://resources/definitions/victory_flavor/phantom_unnamed.tres
## (CategorySlot._load_flavor() construye el path por convención de nombre de archivo == category_id).
const PHANTOM_CATEGORY_ID: StringName = &"phantom_unnamed"

# Pool genérico de anotaciones manuscritas (fase 3+) — contenido pendiente de redacción final por
# Game Designer/narrative (ver spec sección 3.4). Placeholder simple mientras tanto.
const MANUSCRIPT_ANNOTATION_TEXT: String = "Anotación manuscrita. Texto pendiente de redacción."

## category_slots: Array[CategorySlot] ya UNLOCKED o SEALED de FamilyAGrid + sub-casillas de
## FamilyBCombinedSlot. phantom_slot: CategorySlot en variante PHANTOM, hermano de la grilla.
## Ambos son inyectados por ExpedienteScreen al construir la escena.
var _category_slots: Array[CategorySlot] = []
var _phantom_slot: CategorySlot = null


func apply_current_phase() -> void:
	var phase: NarrativePhase.Phase = NarrativePhase.get_current_phase()
	match phase:
		NarrativePhase.Phase.PHASE_1, NarrativePhase.Phase.PHASE_2:
			_apply_phase_1_2()
		NarrativePhase.Phase.PHASE_3:
			_apply_phase_3()
		NarrativePhase.Phase.PHASE_4:
			_apply_phase_4()


## Inyecta las referencias que este controller necesita para aplicar overlays, sin acoplarlo a la
## estructura de nodos exacta de ExpedienteScreen.
func configure(category_slots: Array[CategorySlot], phantom_slot: CategorySlot) -> void:
	_category_slots = category_slots
	_phantom_slot = phantom_slot


func _apply_phase_1_2() -> void:
	if _phantom_slot != null:
		_phantom_slot.visible = false
	for slot in _category_slots:
		slot.set_manuscript_overlay_visible(false)


func _apply_phase_3() -> void:
	if _phantom_slot != null:
		_phantom_slot.visible = false
	for slot in _category_slots:
		# Se consulta CategorySlot.get_slot_state() (ya resuelto vía refresh(), incluidas las
		# sub-casillas de hito económico que no tienen VictoryCategoryState propio — ver
		# category_slot.gd _refresh_sub_milestone()) en vez de re-derivar el estado desde
		# MetaProgress, para no duplicar la lógica de "de dónde sale unlocked" de cada variante.
		if slot.get_slot_state() == CategorySlot.SlotState.UNLOCKED:
			slot.set_manuscript_overlay_visible(true, MANUSCRIPT_ANNOTATION_TEXT)
		else:
			slot.set_manuscript_overlay_visible(false)


func _apply_phase_4() -> void:
	_apply_phase_3()
	if _phantom_slot == null:
		return
	_phantom_slot.visible = true
	_phantom_slot.setup(PHANTOM_CATEGORY_ID, CategorySlot.SlotVariant.PHANTOM)
	_phantom_slot.set_phantom_partial_reveal()
