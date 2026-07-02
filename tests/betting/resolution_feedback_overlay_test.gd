extends SceneTree
## Test de ResolutionFeedbackOverlay (E.8) -- feedback enérgico de resolución, encolado cuando hay
## varias resoluciones en el mismo tick, mouse_filter = IGNORE en todos los nodos (lección del Bug 1).
## Ver .ai-studio/specs/story-e8-boleto-vivo.md sección 4.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/betting/resolution_feedback_overlay_test.gd

const OVERLAY_SCENE: PackedScene = preload("res://scenes/betting/resolution_feedback_overlay.tscn")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	var overlay: ResolutionFeedbackOverlay = OVERLAY_SCENE.instantiate()
	root.add_child(overlay)
	await process_frame

	_test_hidden_by_default(overlay)
	_test_all_nodes_ignore_mouse(overlay)
	_test_show_win_displays_amount(overlay)
	_test_show_loss_displays_amount(overlay)
	_test_queues_multiple_resolutions_same_tick(overlay)

	_finish()


func _test_hidden_by_default(overlay: ResolutionFeedbackOverlay) -> void:
	if overlay.visible:
		_fail("ResolutionFeedbackOverlay debería empezar oculto")


## Lección del Bug 1 (fix §7.2): un overlay que bloquea input reintroduce el deadlock del gate de
## avance. Todos los nodos del overlay deben ignorar el mouse.
func _test_all_nodes_ignore_mouse(overlay: ResolutionFeedbackOverlay) -> void:
	_assert_ignores_mouse(overlay, overlay)
	for child in overlay.get_children():
		_assert_ignores_mouse(overlay, child)


func _assert_ignores_mouse(overlay: ResolutionFeedbackOverlay, node: Node) -> void:
	if node is Control:
		var control: Control = node
		if control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_fail("%s tiene mouse_filter=%d, esperado MOUSE_FILTER_IGNORE (2) -- riesgo de bloquear input (Bug 1)" % [control.name, control.mouse_filter])


func _test_show_win_displays_amount(overlay: ResolutionFeedbackOverlay) -> void:
	overlay.show_win(210, 110)
	if not overlay.visible:
		_fail("show_win debería mostrar el overlay")
	if not overlay._amount_label.text.contains("110"):
		_fail("show_win debería mostrar la ganancia neta atribuible ($110), texto=%s" % overlay._amount_label.text)
	if not overlay._amount_label.text.begins_with("+"):
		_fail("show_win debería mostrar el importe con signo '+', texto=%s" % overlay._amount_label.text)

	overlay._on_display_timer_timeout()  # limpia la cola para los siguientes checks


func _test_show_loss_displays_amount(overlay: ResolutionFeedbackOverlay) -> void:
	overlay.show_loss(75)
	if not overlay.visible:
		_fail("show_loss debería mostrar el overlay")
	if not overlay._amount_label.text.contains("75"):
		_fail("show_loss debería mostrar la pérdida atribuible ($75), texto=%s" % overlay._amount_label.text)
	if not overlay._amount_label.text.begins_with("-"):
		_fail("show_loss debería mostrar el importe con signo '-', texto=%s" % overlay._amount_label.text)

	overlay._on_display_timer_timeout()


## Resoluciones múltiples en un mismo tick no deben solaparse -- se encolan, cada una legible y
## atribuible a su apuesta (decisión de UX delegada a implementación, sección 4 de la spec).
func _test_queues_multiple_resolutions_same_tick(overlay: ResolutionFeedbackOverlay) -> void:
	overlay.show_win(100, 50)
	overlay.show_loss(30)

	if overlay._queue.size() != 1:
		_fail("con 2 resoluciones seguidas debería quedar 1 en cola (la primera ya se muestra), obtenido %d" % overlay._queue.size())
	if not overlay._amount_label.text.contains("50"):
		_fail("la primera resolución encolada debería mostrarse primero (+$50), texto=%s" % overlay._amount_label.text)

	overlay._on_display_timer_timeout()
	if not overlay._amount_label.text.contains("30"):
		_fail("tras la primera resolución debería mostrarse la siguiente de la cola (-$30), texto=%s" % overlay._amount_label.text)
	if not overlay._queue.is_empty():
		_fail("la cola debería quedar vacía tras mostrar la última resolución encolada")

	overlay._on_display_timer_timeout()
	if overlay.visible:
		_fail("el overlay debería ocultarse cuando la cola queda vacía")


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] resolution_feedback_overlay_test: todos los checks OK")
	else:
		push_error("[FAIL] resolution_feedback_overlay_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)
