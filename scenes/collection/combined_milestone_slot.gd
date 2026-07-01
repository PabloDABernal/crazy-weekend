class_name CombinedMilestoneSlot extends Control
## Slot combinado de Familia B (hito económico) de "Tu Expediente" (Épica C).
## Gestiona 3 sub-casillas (10k/100k/1m), cada una un CategorySlot en variante SUB_MILESTONE que
## persigue su propio hito histórico de forma independiente del slot combinado como conjunto.
## Ver .ai-studio/specs/epic-c-tu-expediente.md sección 2.4 y 3.1 (nota sobre sub-hitos).

const CATEGORY_ID: StringName = &"economic_milestone_slot"

# threshold -> category_id del VictoryCategoryFlavor de esa sub-casilla (ver spec sección 1.2).
const SUB_MILESTONES: Dictionary = {
	10000: &"economic_milestone_10k",
	100000: &"economic_milestone_100k",
	1000000: &"economic_milestone_1m",
}

@onready var _combined_header_label: Label = $CombinedHeaderLabel
@onready var _sub_slot_10k: CategorySlot = $SubSlot_10k
@onready var _sub_slot_100k: CategorySlot = $SubSlot_100k
@onready var _sub_slot_1m: CategorySlot = $SubSlot_1m

# Snapshot local de qué umbrales ya se sabían alcanzados la última vez que esta escena los observó.
# Necesario porque VictoryTracker (autoload, conectado a EventBus.money_changed antes que esta escena
# exista) ya habrá marcado VictoryCategoryState.milestone_reached[threshold] = true en el mismo callback
# de money_changed que dispara este handler -- comparar contra el estado ya mutado siempre daría
# "already_reached", por eso se compara contra este snapshot propio en vez de against el estado.
var _known_reached_thresholds: Dictionary = {}


func _ready() -> void:
	EventBus.money_changed.connect(_on_money_changed)


## Refresca las 3 sub-casillas (10k/100k/1m) leyendo VictoryCategoryState.milestone_reached
## (Épica A, sección 1.2) del category_id "economic_milestone_slot", y el header/estado combinado
## general leyendo VictoryCategoryState.unlocked del mismo category_id.
func refresh() -> void:
	var state: VictoryCategoryState = MetaProgress.get_victory_category_state(CATEGORY_ID)

	_sub_slot_10k.setup_sub_milestone(&"economic_milestone_10k", 10000)
	_sub_slot_100k.setup_sub_milestone(&"economic_milestone_100k", 100000)
	_sub_slot_1m.setup_sub_milestone(&"economic_milestone_1m", 1000000)

	_known_reached_thresholds.clear()
	for threshold in SUB_MILESTONES.keys():
		_known_reached_thresholds[threshold] = state.milestone_reached.get(threshold, false)

	_update_header(state)


## Conectado directamente a EventBus.money_changed (no hay señal granular por sub-hito en Épica A —
## ver .ai-studio/specs/epic-c-tu-expediente.md sección 3.1, nota sobre sub-hitos económicos).
## Compara el estado persistido (ya actualizado por VictoryTracker en este mismo evento) contra el
## snapshot local tomado en el último refresh()/animación para detectar qué sub-hito se acaba de
## cruzar por primera vez, y anima solo esa sub-casilla.
func _on_money_changed(_new_amount: int, _delta: int, _reason: String) -> void:
	var state: VictoryCategoryState = MetaProgress.get_victory_category_state(CATEGORY_ID)
	var any_newly_reached: bool = false

	for threshold in SUB_MILESTONES.keys():
		var reached_now: bool = state.milestone_reached.get(threshold, false)
		var known_before: bool = _known_reached_thresholds.get(threshold, false)
		if reached_now and not known_before:
			_known_reached_thresholds[threshold] = true
			any_newly_reached = true
			var sub_slot: CategorySlot = _get_sub_slot_for_threshold(threshold)
			if sub_slot != null:
				sub_slot.play_unlock_animation()

	if any_newly_reached:
		_update_header(state)


func _update_header(state: VictoryCategoryState) -> void:
	_combined_header_label.text = "Hito Económico" if not state.unlocked else "Hito Económico — Completado"


func _get_sub_slot_for_threshold(threshold: int) -> CategorySlot:
	match threshold:
		10000:
			return _sub_slot_10k
		100000:
			return _sub_slot_100k
		1000000:
			return _sub_slot_1m
		_:
			return null
