class_name ExpedienteScreen extends Control
## Pantalla de colección "Tu Expediente" (Épica C, historias C.1/C.2). Accesible desde el menú
## inter-run. Agnóstica al número de categorías: itera VictoryTracker.active_requirement_set y
## reserva espacio fijo para Corners/Resultado Exacto (post-MVP, ver spec sección 2.3).
## Ver .ai-studio/specs/epic-c-tu-expediente.md secciones 2.1 y 3.1.

## Casillas de layout fijo de Familia A que aún no tienen VictoryCategoryDef real en el
## VictoryRequirementSet activo (post-MVP) — se muestran como RESERVED. La única fuente de verdad de
## qué está activo sigue siendo VictoryTracker.active_requirement_set (ver spec sección 2.3).
const RESERVED_FAMILY_A_SLOTS: Array[Dictionary] = [
	{"node_name": "CategorySlot_victory_corners", "hint": "Expediente incompleto. Este archivo no ha sido abierto."},
	{"node_name": "CategorySlot_victory_resultado_exacto", "hint": "Expediente incompleto. Este archivo no ha sido abierto."},
]

@onready var _close_button: Button = $HeaderPanel/CloseButton
@onready var _family_a_grid: GridContainer = $FamilyAGrid
@onready var _family_b_combined_slot: CombinedMilestoneSlot = $FamilyBCombinedSlot
@onready var _phantom_slot: CategorySlot = $PhantomSlot
@onready var _corruption_controller: ExpedienteCorruptionController = $CorruptionController


func _ready() -> void:
	_close_button.pressed.connect(_on_close_button_pressed)

	_setup_family_a_grid()
	_family_b_combined_slot.refresh()

	_corruption_controller.configure(_collect_category_slots(), _phantom_slot)
	_corruption_controller.apply_current_phase()

	EventBus.victory_category_unlocked.connect(_on_victory_category_unlocked)
	EventBus.final_ending_triggered.connect(_on_final_ending_triggered)


## Itera VictoryTracker.active_requirement_set.required_categories (Familia A) + categorías
## reservadas de layout fijo -> configura cada CategorySlot (setup/setup_reserved) y llama refresh().
func _setup_family_a_grid() -> void:
	var active_category_ids: Array[StringName] = []
	if VictoryTracker.active_requirement_set != null:
		for def in VictoryTracker.active_requirement_set.required_categories:
			if def.family == VictoryCategoryDef.Family.MARKET:
				active_category_ids.append(def.category_id)

	for category_id in active_category_ids:
		var node_name: String = "CategorySlot_%s" % category_id
		var slot: CategorySlot = _family_a_grid.get_node_or_null(NodePath(node_name))
		if slot != null:
			slot.setup(category_id, CategorySlot.SlotVariant.STANDARD)

	for reserved_entry in RESERVED_FAMILY_A_SLOTS:
		var slot: CategorySlot = _family_a_grid.get_node_or_null(NodePath(reserved_entry["node_name"]))
		if slot != null:
			slot.setup_reserved(reserved_entry["hint"])


func _collect_category_slots() -> Array[CategorySlot]:
	var slots: Array[CategorySlot] = []
	for child in _family_a_grid.get_children():
		if child is CategorySlot:
			slots.append(child)
	for sub_slot_path in ["SubSlot_10k", "SubSlot_100k", "SubSlot_1m"]:
		var sub_slot: CategorySlot = _family_b_combined_slot.get_node_or_null(NodePath(sub_slot_path))
		if sub_slot != null:
			slots.append(sub_slot)
	return slots


## Busca el CategorySlot cuyo category_id matchea (incluidas las 3 sub-casillas de hito económico se
## resuelven por su propia lógica de money_changed en CombinedMilestoneSlot, no por esta señal — ver
## spec sección 3.1) y llama play_unlock_animation() solo si la pantalla está en el árbol.
func _on_victory_category_unlocked(category_id: StringName, _run_number: int) -> void:
	if not is_inside_tree():
		return

	var slot: CategorySlot = _family_a_grid.get_node_or_null(NodePath("CategorySlot_%s" % category_id))
	if slot != null:
		slot.play_unlock_animation()
		return

	if category_id == CombinedMilestoneSlot.CATEGORY_ID:
		_family_b_combined_slot.refresh()


## Fuera de alcance de C.1/C.2 presentar el final canónico en sí (ver spec sección 3.1): la grilla ya
## refleja el 100% de categorías completas vía refresh()/play_unlock_animation() sin lógica adicional.
func _on_final_ending_triggered(_run_number: int) -> void:
	pass


func _on_close_button_pressed() -> void:
	queue_free()
