class_name ResolutionFeedbackOverlay extends Control
## Feedback enérgico e inmediato al resolverse una apuesta (E.8). `mouse_filter = IGNORE` en todos los
## nodos (fijado en resolution_feedback_overlay.tscn) -- igual que CrazyMomentOverlay, para no
## reintroducir el patrón de bloqueo de input del Bug 1.
## Ver .ai-studio/specs/story-e8-boleto-vivo.md sección 4.
##
## Intensidad alta y consistente en cualquier fase narrativa: esta escena no consulta NarrativePhase
## ni degrada la animación/tamaño del número con el tiempo. El contenido narrativo de fases avanzadas
## ("hablarle" al jugador) queda pendiente de contenido de Game Designer (coordinación explícita de la
## spec, sección 4) -- no implementado aquí.

const DISPLAY_DURATION_SECONDS: float = 1.6

@onready var _amount_label: Label = $AmountLabel
@onready var _detail_label: Label = $DetailLabel

var _queue: Array[Dictionary] = []
var _display_timer: Timer = null


func _ready() -> void:
	visible = false
	_display_timer = Timer.new()
	_display_timer.one_shot = true
	_display_timer.wait_time = DISPLAY_DURATION_SECONDS
	add_child(_display_timer)
	_display_timer.timeout.connect(_on_display_timer_timeout)


## amount_returned = dinero acreditado a la run por esta apuesta ganada; net = amount_returned - stake.
func show_win(amount_returned: int, net: int) -> void:
	_enqueue({"won": true, "net": net, "amount_returned": amount_returned})


func show_loss(amount_lost: int) -> void:
	_enqueue({"won": false, "amount_lost": amount_lost})


## Resoluciones múltiples en un mismo tick se encolan (decisión de UX menor delegada a
## implementación, sección 4 de la spec) en vez de solaparse, para que cada una siga siendo legible y
## atribuible a su apuesta.
func _enqueue(entry: Dictionary) -> void:
	_queue.append(entry)
	if not visible:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		visible = false
		return

	var entry: Dictionary = _queue.pop_front()
	visible = true

	if entry["won"]:
		_amount_label.text = "+$%d" % entry["net"]
		_detail_label.text = "cobras $%d" % entry["amount_returned"]
	else:
		_amount_label.text = "-$%d" % entry["amount_lost"]
		_detail_label.text = ""

	_display_timer.start()


func _on_display_timer_timeout() -> void:
	_show_next()
