class_name NarrativeIntro extends Control
## Pantalla negra de introducción narrativa (E.1). Avance manual: click/tap/tecla avanza a la
## siguiente línea, o salta todo el bloque si ya se mostró la última.
## Texto fuente: res://resources/definitions/narrative/intro_text.tres (ya cerrado en game-design.md).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 1.

const INTRO_TEXT_PATH: String = "res://resources/definitions/narrative/intro_text.tres"

signal intro_finished()

@onready var _intro_text_label: RichTextLabel = $IntroText
@onready var _continue_prompt: Label = $ContinuePrompt

var _lines: Array[String] = []
var _current_line_index: int = 0


func _ready() -> void:
	var intro_text: IntroTextDef = ResourceLoader.load(INTRO_TEXT_PATH) if ResourceLoader.exists(INTRO_TEXT_PATH) else null
	_lines = intro_text.lines if intro_text != null else []
	_current_line_index = 0
	_show_current_line()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance()
	elif event is InputEventScreenTouch and event.pressed:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_advance()


func _advance() -> void:
	_current_line_index += 1
	if _current_line_index >= _lines.size():
		intro_finished.emit()
		return
	_show_current_line()


func _show_current_line() -> void:
	if _lines.is_empty():
		intro_finished.emit()
		return
	_intro_text_label.text = _lines[_current_line_index]
