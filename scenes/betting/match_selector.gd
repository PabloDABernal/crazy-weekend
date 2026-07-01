class_name MatchSelector extends Control
## Selector de partidos en curso el día actual (E.3): un MatchTabButton por partido con tick abierto.
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 2.1.

signal match_focus_requested(match_id: StringName)

@onready var _tabs_container: Container = $TabsContainer

var _buttons_by_match_id: Dictionary = {}   # match_id (StringName) -> Button

## Sufijo visual añadido al texto del tab cuando ese partido ya cumplió su apuesta obligatoria del
## tick vigente (ver mark_bet_requirement_satisfied()) -- limpiado en cada nuevo tick vía
## clear_bet_requirement_marks().
const SATISFIED_SUFFIX: String = " ✓"

var _base_labels_by_match_id: Dictionary = {}   # match_id (StringName) -> String (label sin sufijo)


## Asegura que exista un MatchTabButton para este match_id (lo crea si no existía). No cambia el foco.
func ensure_tab(match_id: StringName, display_label: String) -> void:
	if _buttons_by_match_id.has(match_id):
		return

	var button := Button.new()
	button.text = display_label
	button.toggle_mode = true
	button.pressed.connect(_on_tab_pressed.bind(match_id))
	_tabs_container.add_child(button)
	_buttons_by_match_id[match_id] = button
	_base_labels_by_match_id[match_id] = display_label


func set_focused(match_id: StringName) -> void:
	for id in _buttons_by_match_id.keys():
		var button: Button = _buttons_by_match_id[id]
		button.button_pressed = id == match_id


## Marca visualmente (sufijo en el label del tab) que este partido ya cumplió su apuesta obligatoria
## del tick vigente -- feedback directo de MatchPanel.tick_bet_requirement_satisfied (ver
## BettingRoot._on_match_panel_tick_bet_requirement_satisfied), útil sobre todo cuando el jugador
## tiene el foco en OTRO partido y no ve el AdvanceTickButton ya habilitado de este.
func mark_bet_requirement_satisfied(match_id: StringName) -> void:
	var button: Button = _buttons_by_match_id.get(match_id, null)
	if button == null:
		return
	var base_label: String = _base_labels_by_match_id.get(match_id, button.text)
	button.text = base_label + SATISFIED_SUFFIX


## Quita el sufijo de "listo" de todos los tabs -- llamado por BettingRoot al abrir un nuevo ciclo de
## tick (cada MatchPanel vuelve a exigir su apuesta obligatoria de ese tick).
func clear_bet_requirement_marks() -> void:
	for match_id in _buttons_by_match_id.keys():
		var button: Button = _buttons_by_match_id[match_id]
		button.text = _base_labels_by_match_id.get(match_id, button.text)


func clear_tabs() -> void:
	for button in _buttons_by_match_id.values():
		button.queue_free()
	_buttons_by_match_id.clear()
	_base_labels_by_match_id.clear()


func _on_tab_pressed(match_id: StringName) -> void:
	match_focus_requested.emit(match_id)
