class_name CommentaryPanel extends Control
## Sub-panel de MatchPanel: muestra las líneas de comentario ya resueltas por CommentaryResolver
## (Épica D) para el tick vigente de un partido. No decide contenido ni prioridad -- solo presenta.
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 3.1 y 3.2.

@onready var _commentary_lines: VBoxContainer = $CommentaryLines


func refresh(lines: Array[String]) -> void:
	for child in _commentary_lines.get_children():
		child.queue_free()

	for line in lines:
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.70, 0.80, 0.92, 1.0))
		_commentary_lines.add_child(label)
