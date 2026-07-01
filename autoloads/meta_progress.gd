extends Node
## MetaProgress (autoload) — fuente de verdad de todo lo que persiste entre runs y entre temporadas.
## Épica B solo consume la parte de bonus de dinero inicial y número de run; Épica A/C añadirán aquí
## el resto de campos sin tocar el contrato ya definido para Épica B.
## Ver .ai-studio/specs/_arquitectura-base.md sección 2.2 y .ai-studio/specs/epic-b-economia-de-run.md B.1.

const SAVE_PATH: String = "user://save_meta.tres"
const META_BONUS_DEFINITIONS_DIR: String = "res://resources/definitions/meta_bonus/"

var _current_run_number: int = 1
var _unlocked_money_bonus_ids: Array[StringName] = []

# --- Épica A — Tipos de victoria ---
var _victory_category_states: Dictionary = {}   # { category_id (StringName): VictoryCategoryState }
var _final_ending_triggered: bool = false
var _final_ending_triggered_at_run_number: int = -1

# --- Épica E — Tutorial de primera apuesta (E.2) ---
var _first_bet_tutorial_completed: bool = false

# --- Épica E — Bonus de monto explícito (decisión inter-run, E.6) ---
# { bonus_id (StringName): amount (int) } — bonus generados en runtime que no tienen un
# MetaMoneyBonus.tres de catálogo correspondiente. Ver epic-e-pantalla-de-apuestas.md sección 8.4.
var _explicit_money_bonuses: Dictionary = {}


func _ready() -> void:
	EventBus.run_ended.connect(_on_run_ended)


func get_current_run_number() -> int:
	return _current_run_number


## Recorre res://resources/definitions/meta_bonus/*.tres, filtra por los bonus_id desbloqueados
## y suma amount. El amount nunca se copia al save: siempre se resuelve contra la definición .tres.
## Épica E (sección 8.4): suma además todos los bonus de monto explícito ya registrados vía
## unlock_money_bonus_with_explicit_amount(), que no tienen definición .tres de catálogo.
func get_total_starting_money_bonus() -> int:
	var total: int = 0
	for bonus in _load_all_money_bonus_definitions():
		if is_money_bonus_unlocked(bonus.bonus_id):
			total += bonus.amount
	for amount in _explicit_money_bonuses.values():
		total += amount
	return total


## Idempotente: desbloquear dos veces no duplica el bonus.
func unlock_money_bonus(bonus_id: StringName) -> void:
	if not _unlocked_money_bonus_ids.has(bonus_id):
		_unlocked_money_bonus_ids.append(bonus_id)


func is_money_bonus_unlocked(bonus_id: StringName) -> bool:
	return _unlocked_money_bonus_ids.has(bonus_id)


## Épica E (sección 8.4) — variante de unlock_money_bonus() para bonus generados en runtime (ej.
## decisiones inter-run) que no tienen un MetaMoneyBonus.tres de catálogo: guarda el par
## (bonus_id, amount) directamente, en vez de resolver amount contra un .tres en tiempo de consulta.
## Igual de idempotente por bonus_id (llamar dos veces con el mismo bonus_id no duplica el monto).
func unlock_money_bonus_with_explicit_amount(bonus_id: StringName, amount: int) -> void:
	if _explicit_money_bonuses.has(bonus_id):
		return
	_explicit_money_bonuses[bonus_id] = amount


## Llamado al cerrar una run (victoria o derrota).
func advance_run_number() -> void:
	_current_run_number += 1


## Escucha EventBus.run_ended para avanzar el contador de runs, en vez de que RunState llame
## directamente a MetaProgress (los autoloads de estado no se mutan entre sí, solo se leen; ver
## _arquitectura-base.md sección 2 y diagrama Mermaid).
func _on_run_ended(_result: RunResult) -> void:
	advance_run_number()


## Épica A — devuelve el VictoryCategoryState de una categoría. Si no existe todavía (categoría nunca
## evaluada), crea uno nuevo en blanco, lo registra y lo devuelve — VictoryTracker siempre recibe una
## instancia válida, nunca null.
func get_victory_category_state(category_id: StringName) -> VictoryCategoryState:
	if not _victory_category_states.has(category_id):
		var new_state := VictoryCategoryState.new()
		new_state.category_id = category_id
		_victory_category_states[category_id] = new_state
	return _victory_category_states[category_id]


func get_all_victory_category_states() -> Array[VictoryCategoryState]:
	var states: Array[VictoryCategoryState] = []
	for state in _victory_category_states.values():
		states.append(state)
	return states


## Persiste vía el mismo save() de MetaProgress. state.category_id identifica la entrada a reemplazar.
func save_victory_category_state(state: VictoryCategoryState) -> void:
	_victory_category_states[state.category_id] = state


func is_final_ending_triggered() -> bool:
	return _final_ending_triggered


## Idempotente: marcar el final dos veces no pisa el run_number de la primera vez.
func mark_final_ending_triggered(at_run_number: int) -> void:
	if _final_ending_triggered:
		return
	_final_ending_triggered = true
	_final_ending_triggered_at_run_number = at_run_number


## Épica E (sección 6.1) — flag idempotente de tutorial de primera apuesta completado.
func has_completed_first_bet_tutorial() -> bool:
	return _first_bet_tutorial_completed


## Idempotente: marcarlo completado dos veces no tiene efecto adicional.
func mark_first_bet_tutorial_completed() -> void:
	_first_bet_tutorial_completed = true


func save() -> void:
	var save_data := MetaProgressSaveData.new()
	save_data.current_run_number = _current_run_number
	save_data.unlocked_money_bonus_ids = _unlocked_money_bonus_ids.duplicate()
	save_data.victory_category_states = get_all_victory_category_states()
	save_data.final_ending_triggered = _final_ending_triggered
	save_data.final_ending_triggered_at_run_number = _final_ending_triggered_at_run_number
	save_data.first_bet_tutorial_completed = _first_bet_tutorial_completed
	var explicit_ids: Array[StringName] = []
	var explicit_amounts: Array[int] = []
	for bonus_id in _explicit_money_bonuses.keys():
		explicit_ids.append(bonus_id)
		explicit_amounts.append(_explicit_money_bonuses[bonus_id])
	save_data.explicit_money_bonus_ids = explicit_ids
	save_data.explicit_money_bonus_amounts = explicit_amounts
	var error := ResourceSaver.save(save_data, SAVE_PATH)
	if error != OK:
		push_error("MetaProgress.save() failed with error code %d" % error)


## Llamado una vez al boot del juego.
func load_or_create() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded: Resource = ResourceLoader.load(SAVE_PATH)
		if loaded is MetaProgressSaveData:
			var save_data: MetaProgressSaveData = loaded
			_current_run_number = save_data.current_run_number
			_unlocked_money_bonus_ids = []
			for bonus_id in save_data.unlocked_money_bonus_ids:
				_unlocked_money_bonus_ids.append(StringName(bonus_id))
			_victory_category_states = {}
			for state in save_data.victory_category_states:
				_victory_category_states[state.category_id] = state
			_final_ending_triggered = save_data.final_ending_triggered
			_final_ending_triggered_at_run_number = save_data.final_ending_triggered_at_run_number
			_first_bet_tutorial_completed = save_data.first_bet_tutorial_completed
			_explicit_money_bonuses = {}
			for i in range(save_data.explicit_money_bonus_ids.size()):
				_explicit_money_bonuses[save_data.explicit_money_bonus_ids[i]] = save_data.explicit_money_bonus_amounts[i]
			return
	# No existe save previo o el recurso encontrado no es válido: estado inicial nuevo.
	_current_run_number = 1
	_unlocked_money_bonus_ids = []
	_victory_category_states = {}
	_final_ending_triggered = false
	_final_ending_triggered_at_run_number = -1
	_first_bet_tutorial_completed = false
	_explicit_money_bonuses = {}


func _load_all_money_bonus_definitions() -> Array[MetaMoneyBonus]:
	var definitions: Array[MetaMoneyBonus] = []
	var dir := DirAccess.open(META_BONUS_DEFINITIONS_DIR)
	if dir == null:
		return definitions
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource: Resource = ResourceLoader.load(META_BONUS_DEFINITIONS_DIR + file_name)
			if resource is MetaMoneyBonus:
				definitions.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()
	return definitions
