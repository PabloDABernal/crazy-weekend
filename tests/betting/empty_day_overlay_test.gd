extends SceneTree
## Test de EmptyDayOverlay (E.10) -- pantalla breve "no hay partidos hoy" para días vacíos de una
## jornada CONCENTRATED, calcada del patrón de ResolutionFeedbackOverlay (E.8): mouse_filter = IGNORE
## en todos los nodos (lección del Bug 1), cierre por temporizador automático, nunca por click.
## Ver .ai-studio/specs/story-e10-dia-vacio.md secciones 2-5.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/betting/empty_day_overlay_test.gd

const OVERLAY_SCENE: PackedScene = preload("res://scenes/betting/empty_day_overlay.tscn")

var _failures: Array[String] = []
var _skip_finished_count: int = 0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	var overlay: EmptyDayOverlay = OVERLAY_SCENE.instantiate()
	root.add_child(overlay)
	await process_frame

	_test_hidden_by_default(overlay)
	_test_all_nodes_ignore_mouse(overlay)
	_test_show_empty_day_displays_text_and_shows(overlay)
	_test_timer_closes_and_emits_skip_finished(overlay)
	_test_reentrant_show_repopulates_and_restarts_timer(overlay)

	_finish()


func _test_hidden_by_default(overlay: EmptyDayOverlay) -> void:
	if overlay.visible:
		_fail("EmptyDayOverlay debería empezar oculto")


## Lección del Bug 1 (fix §7.2), reafirmada en la spec E.10 §2: un overlay que bloquea input
## reintroduce el deadlock del gate de avance. Todos los nodos del overlay deben ignorar el mouse.
func _test_all_nodes_ignore_mouse(overlay: EmptyDayOverlay) -> void:
	_assert_ignores_mouse(overlay)
	for child in overlay.get_children():
		_assert_ignores_mouse(child)


func _assert_ignores_mouse(node: Node) -> void:
	if node is Control:
		var control: Control = node
		if control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_fail("%s tiene mouse_filter=%d, esperado MOUSE_FILTER_IGNORE (2) -- riesgo de bloquear input (Bug 1)" % [control.name, control.mouse_filter])


func _test_show_empty_day_displays_text_and_shows(overlay: EmptyDayOverlay) -> void:
	overlay.show_empty_day(BettingDay.Day.FRIDAY, BettingDay.Day.SATURDAY)

	if not overlay.visible:
		_fail("show_empty_day debería mostrar el overlay")
	if not overlay._detail_label.text.contains("sábado"):
		_fail("show_empty_day(FRIDAY, SATURDAY) debería mencionar 'sábado' en DetailLabel, texto=%s" % overlay._detail_label.text)
	if overlay._title_label.text == "":
		_fail("TitleLabel no debería quedar vacío tras show_empty_day")


func _test_timer_closes_and_emits_skip_finished(overlay: EmptyDayOverlay) -> void:
	_skip_finished_count = 0
	overlay.skip_finished.connect(_on_skip_finished)

	overlay.show_empty_day(BettingDay.Day.SATURDAY, BettingDay.Day.SUNDAY)
	if not overlay.visible:
		_fail("show_empty_day debería mostrar el overlay antes del timeout")

	# Se ejercita el cierre automático por temporizador (nunca por click, spec §5) invocando
	# directamente el handler de timeout -- mismo patrón que resolution_feedback_overlay_test.gd.
	overlay._on_display_timer_timeout()

	if overlay.visible:
		_fail("el overlay debería ocultarse cuando termina el temporizador, sin requerir click")
	if _skip_finished_count != 1:
		_fail("skip_finished debería emitirse exactamente 1 vez al cerrar, obtenido %d" % _skip_finished_count)

	overlay.skip_finished.disconnect(_on_skip_finished)


func _test_reentrant_show_repopulates_and_restarts_timer(overlay: EmptyDayOverlay) -> void:
	overlay.show_empty_day(BettingDay.Day.FRIDAY, BettingDay.Day.SATURDAY)
	if not overlay._detail_label.text.contains("sábado"):
		_fail("primera llamada de la cascada: DetailLabel debería mencionar 'sábado'")

	# Misma instancia reutilizada (sin cola, spec §3): reentrar show_empty_day debe repoblar los
	# labels y reiniciar el temporizador para el siguiente día vacío de la cascada.
	overlay.show_empty_day(BettingDay.Day.SATURDAY, BettingDay.Day.SUNDAY)
	if not overlay._detail_label.text.contains("domingo"):
		_fail("segunda llamada de la cascada: DetailLabel debería repoblarse con 'domingo', texto=%s" % overlay._detail_label.text)
	if not overlay.visible:
		_fail("el overlay debería seguir visible tras la segunda llamada en cascada")


func _on_skip_finished() -> void:
	_skip_finished_count += 1


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] empty_day_overlay_test: todos los checks OK")
	else:
		push_error("[FAIL] empty_day_overlay_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)
