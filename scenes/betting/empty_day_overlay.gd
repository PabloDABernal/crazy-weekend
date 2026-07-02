class_name EmptyDayOverlay extends Control
## Pantalla breve "no hay partidos hoy" (E.10) para días sin partidos en una jornada CONCENTRATED
## (D.6 sección 11.2). Calcada del patrón de ResolutionFeedbackOverlay (E.8): overlay atmosférico con
## temporizador que nunca captura input (mouse_filter = IGNORE en todos los nodos, fijado en
## empty_day_overlay.tscn) -- no reintroduce el patrón de bloqueo de input del Bug 1. El cierre es
## siempre por temporizador automático, nunca por click (spec sección 5).
## Ver .ai-studio/specs/story-e10-dia-vacio.md secciones 2-5.
##
## Texto (Game Designer, backlog.md Historia E.10, versión fase 1-2 -- único texto fijo implementado
## en esta historia; la variante fase 3-4 es mejora opcional no bloqueante, no implementada aquí): la
## frase "Hoy no hay partidos. La jornada se concentra en [día]." se reparte entre los dos labels que
## fija la spec técnica (sección 2): TitleLabel = "Hoy no hay partidos.", DetailLabel = "La jornada se
## concentra en [día]." con [día] = nombre del día siguiente (next_day).

## Emitida cuando termina el temporizador y el overlay se oculta. BettingRoot la usa para reanudar el
## avance de día (llamar a _on_matchday_finished(-1)).
signal skip_finished

const DISPLAY_DURATION_SECONDS: float = 1.8

@onready var _title_label: Label = $TitleLabel
@onready var _detail_label: Label = $DetailLabel

var _display_timer: Timer = null


func _ready() -> void:
	visible = false
	_display_timer = Timer.new()
	_display_timer.one_shot = true
	_display_timer.wait_time = DISPLAY_DURATION_SECONDS
	add_child(_display_timer)
	_display_timer.timeout.connect(_on_display_timer_timeout)


## Muestra la pantalla breve para un día sin partidos y arranca el temporizador de auto-cierre.
## empty_day = día que quedó sin partidos (no se usa hoy en el texto, se recibe para que la interfaz
## quede completa según la spec técnica sección 3, por si un futuro copy lo necesita).
## next_day  = día inmediatamente siguiente al que avanzará la run (para DetailLabel).
func show_empty_day(_empty_day: BettingDay.Day, next_day: BettingDay.Day) -> void:
	_title_label.text = "Hoy no hay partidos."
	_detail_label.text = "La jornada se concentra en %s." % _format_day_label(next_day)

	visible = true
	_display_timer.start()


func _format_day_label(day: BettingDay.Day) -> String:
	match day:
		BettingDay.Day.FRIDAY:
			return "viernes"
		BettingDay.Day.SATURDAY:
			return "sábado"
		BettingDay.Day.SUNDAY:
			return "domingo"
		_:
			return ""


func _on_display_timer_timeout() -> void:
	visible = false
	skip_finished.emit()
