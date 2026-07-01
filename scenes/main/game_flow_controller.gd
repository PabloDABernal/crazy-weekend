class_name GameFlowController extends Node
## Orquestador de alto nivel (E.1, E.5, E.6): máquina de estados simple que decide qué sub-escena está
## activa como hija de CurrentSceneContainer en cada momento. Raíz de res://scenes/main/main.tscn,
## única escena que Godot carga como run/main_scene.
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 1.

enum FlowState { START_SCREEN, NARRATIVE_INTRO, BETTING_RUN, INTERRUN_FLOW }

const START_SCREEN_SCENE: PackedScene = preload("res://scenes/main/start_screen.tscn")
const NARRATIVE_INTRO_SCENE: PackedScene = preload("res://scenes/main/narrative_intro.tscn")
const BETTING_ROOT_SCENE: PackedScene = preload("res://scenes/betting/betting_root.tscn")
const INTERRUN_FLOW_SCENE: PackedScene = preload("res://scenes/meta/interrun_flow.tscn")

@onready var _current_scene_container: Control = $CurrentSceneContainer

var _flow_state: FlowState = FlowState.START_SCREEN
var _current_scene_node: Control = null

## Guardado al recibir EventBus.run_ended, para pasarlo a InterrunFlow tras cerrar RunEndScreen.
var _pending_run_result: RunResult = null
var _pending_categories_unlocked_this_run: Array = []


func _ready() -> void:
	MetaProgress.load_or_create()
	LeagueState.load_or_create()

	EventBus.run_ended.connect(_on_run_ended)

	_flow_state = FlowState.START_SCREEN
	_show_start_screen()


func _show_start_screen() -> void:
	var start_screen: StartScreen = _instantiate_and_show(START_SCREEN_SCENE)
	start_screen.bet_pressed.connect(_on_start_screen_bet_pressed)


func _on_start_screen_bet_pressed() -> void:
	_flow_state = FlowState.NARRATIVE_INTRO
	var narrative_intro: NarrativeIntro = _instantiate_and_show(NARRATIVE_INTRO_SCENE)
	narrative_intro.intro_finished.connect(_on_narrative_intro_finished)


func _on_narrative_intro_finished() -> void:
	_flow_state = FlowState.BETTING_RUN
	RunState.start_new_run()
	_start_betting_run()


func _start_betting_run() -> void:
	var betting_root: BettingRoot = _instantiate_and_show(BETTING_ROOT_SCENE)
	betting_root.run_closed.connect(_on_betting_root_run_closed)


func _on_run_ended(result: RunResult) -> void:
	_pending_run_result = result


## BettingRoot ya mostró RunEndScreen y esperó el click de "Continuar" antes de emitir run_closed.
## _instantiate_and_show() es quien libera la instancia de BettingRoot (queue_free()) al reemplazarla
## por InterrunFlow -- ver epic-e-pantalla-de-apuestas.md sección 7.2.
func _on_betting_root_run_closed(categories_unlocked_this_run: Array) -> void:
	_pending_categories_unlocked_this_run = categories_unlocked_this_run
	_flow_state = FlowState.INTERRUN_FLOW
	_start_interrun_flow()


func _start_interrun_flow() -> void:
	var interrun_flow: InterrunFlow = _instantiate_and_show(INTERRUN_FLOW_SCENE)
	interrun_flow.setup(_pending_run_result, _pending_categories_unlocked_this_run)
	interrun_flow.interrun_finished.connect(_on_interrun_flow_finished)


func _on_interrun_flow_finished() -> void:
	_flow_state = FlowState.BETTING_RUN
	RunState.start_new_run()
	_start_betting_run()


func _instantiate_and_show(scene: PackedScene) -> Node:
	if _current_scene_node != null:
		_current_scene_node.queue_free()
		_current_scene_node = null

	var instance: Node = scene.instantiate()
	_current_scene_container.add_child(instance)
	_current_scene_node = instance
	return instance
