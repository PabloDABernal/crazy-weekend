class_name StartScreen extends Control
## Pantalla de inicio (E.1): título del juego y botón "APOSTAR". Primera pantalla que ve el jugador
## en cada apertura de la aplicación.
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 1.

signal bet_pressed()

@onready var _bet_button: Button = $BetButton


func _ready() -> void:
	_bet_button.pressed.connect(_on_bet_button_pressed)


func _on_bet_button_pressed() -> void:
	bet_pressed.emit()
