class_name InterrunFlow extends Control
## Fase inter-run mínima (E.6): resumen de lunes + una decisión conversacional simplificada. Escena
## raíz independiente, sin relación de nodos con BettingRoot -- solo se comunican por señales de
## EventBus y por lectura/escritura de autoloads.
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 8.

const DECISION_SET_PATH: String = "res://resources/definitions/interrun/decision_set_mvp.tres"

signal interrun_finished()

@onready var _monday_summary_screen: MondaySummaryScreen = $MondaySummaryScreen
@onready var _decision_screen: DecisionScreen = $DecisionScreen

var _last_run_result: RunResult = null
var _categories_unlocked_this_run: Array = []


func _ready() -> void:
	_monday_summary_screen.continue_pressed.connect(_on_monday_summary_continue_pressed)
	_decision_screen.decision_confirmed.connect(_on_decision_confirmed)
	_decision_screen.visible = false


## Invocado por GameFlowController al instanciar esta escena, con el resultado de la run recién
## cerrada y las categorías desbloqueadas durante ella (recolectadas por BettingRoot).
func setup(result: RunResult, categories_unlocked_this_run: Array) -> void:
	_last_run_result = result
	_categories_unlocked_this_run = categories_unlocked_this_run
	_monday_summary_screen.setup(result, categories_unlocked_this_run)
	_monday_summary_screen.visible = true
	_decision_screen.visible = false


func _on_monday_summary_continue_pressed() -> void:
	_monday_summary_screen.visible = false
	_decision_screen.visible = true

	var decision_set: InterrunDecisionSet = ResourceLoader.load(DECISION_SET_PATH) if ResourceLoader.exists(DECISION_SET_PATH) else null
	var options: Array[InterrunDecisionOption] = decision_set.options if decision_set != null else []
	_decision_screen.setup(options)


## El bonus ya fue persistido por DecisionScreen antes de emitir esta señal. RunState.start_new_run()
## (B.1) ya suma MetaProgress.get_total_starting_money_bonus() automáticamente, que ahora incluye el
## bonus recién registrado -- InterrunFlow NO sobreescribe ni duplica esa suma, solo dispara la
## transición.
func _on_decision_confirmed(_bonus_amount: int) -> void:
	interrun_finished.emit()
