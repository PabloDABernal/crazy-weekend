extends Node
## MetaProgress (autoload) — fuente de verdad de todo lo que persiste entre runs y entre temporadas.
## Épica B solo consume la parte de bonus de dinero inicial y número de run; Épica A/C añadirán aquí
## el resto de campos sin tocar el contrato ya definido para Épica B.
## Ver .ai-studio/specs/_arquitectura-base.md sección 2.2 y .ai-studio/specs/epic-b-economia-de-run.md B.1.

const SAVE_PATH: String = "user://save_meta.tres"
const META_BONUS_DEFINITIONS_DIR: String = "res://resources/definitions/meta_bonus/"

var _current_run_number: int = 1
var _unlocked_money_bonus_ids: Array[StringName] = []


func get_current_run_number() -> int:
	return _current_run_number


## Recorre res://resources/definitions/meta_bonus/*.tres, filtra por los bonus_id desbloqueados
## y suma amount. El amount nunca se copia al save: siempre se resuelve contra la definición .tres.
func get_total_starting_money_bonus() -> int:
	var total: int = 0
	for bonus in _load_all_money_bonus_definitions():
		if is_money_bonus_unlocked(bonus.bonus_id):
			total += bonus.amount
	return total


## Idempotente: desbloquear dos veces no duplica el bonus.
func unlock_money_bonus(bonus_id: StringName) -> void:
	if not _unlocked_money_bonus_ids.has(bonus_id):
		_unlocked_money_bonus_ids.append(bonus_id)


func is_money_bonus_unlocked(bonus_id: StringName) -> bool:
	return _unlocked_money_bonus_ids.has(bonus_id)


## Llamado al cerrar una run (victoria o derrota).
func advance_run_number() -> void:
	_current_run_number += 1


func save() -> void:
	var save_data := MetaProgressSaveData.new()
	save_data.current_run_number = _current_run_number
	save_data.unlocked_money_bonus_ids = _unlocked_money_bonus_ids.duplicate()
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
			return
	# No existe save previo o el recurso encontrado no es válido: estado inicial nuevo.
	_current_run_number = 1
	_unlocked_money_bonus_ids = []


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
