class_name TutorialOverlay extends Control
## Capa de anotaciones persistentes sobre la UI normal de apuestas ya visible y funcional (E.2). No es
## un modal bloqueante: no tapa la pantalla, solo superpone tooltips. Se activa solo si
## not MetaProgress.has_completed_first_bet_tutorial().
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 6.

## Referencias reservadas para un futuro reposicionamiento dinámico sobre el MatchPanel enfocado
## (detalle de UX no bloqueante, ver spec sección 6.2) -- en este MVP las anotaciones usan posición
## fija definida en tutorial_overlay.tscn, sin seguir al panel activo.
@onready var _annotation_probabilities: Control = $TutorialPanel/VBox/AnnotationBubble_Probabilities
@onready var _annotation_stake: Control = $TutorialPanel/VBox/AnnotationBubble_Stake
@onready var _annotation_balance: Control = $TutorialPanel/VBox/AnnotationBubble_Balance
@onready var _skip_hint_label: Label = $TutorialPanel/VBox/SkipHintLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Llamado por BettingRoot cuando PendingBetsTracker.register_bet() se dispara por primera vez en
## esta run y MetaProgress.has_completed_first_bet_tutorial() era false al momento de apostar.
func on_first_bet_confirmed() -> void:
	MetaProgress.mark_first_bet_tutorial_completed()
	queue_free()
