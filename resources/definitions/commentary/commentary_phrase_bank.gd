class_name CommentaryPhraseBank extends Resource
## Recurso de contenido puro: plantillas de texto por EventKind x NarrativePhase.Phase, con
## placeholders {team}, {player}, {score}. Contenido real (los .tres con textos) es responsabilidad
## de Game Designer/narrativa — mismo patrón que VictoryCategoryFlavor en Épica C.
## CommentaryResolver es agnóstico al contenido real de estas plantillas, solo consume estos getters.
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 7.

## templates_by_event_and_phase: { EventKind (int) -> { NarrativePhase.Phase (int) -> Array[String] } }
## Cuando hay varias plantillas candidatas para el mismo EventKind/Phase, se usa la primera (contenido
## decide cuántas variantes registrar; el resolver no elige entre variantes en esta épica).
@export var templates_by_event_and_phase: Dictionary = {}

## no_event_templates: { NarrativePhase.Phase (int) -> String } — plantilla de "tramo sin eventos".
@export var no_event_templates: Dictionary = {}

## crazy_moment_templates: { NarrativePhase.Phase (int) -> String } — banco de Momento Crazy.
@export var crazy_moment_templates: Dictionary = {}


func get_template(kind: MatchTickEvent.EventKind, phase: NarrativePhase.Phase) -> String:
	if not templates_by_event_and_phase.has(kind):
		return ""
	var by_phase: Dictionary = templates_by_event_and_phase[kind]
	if not by_phase.has(phase):
		return ""
	var candidates: Array = by_phase[phase]
	if candidates.is_empty():
		return ""
	return candidates[0]


func get_no_event_template(phase: NarrativePhase.Phase) -> String:
	return no_event_templates.get(phase, "")


func get_crazy_moment_template(phase: NarrativePhase.Phase) -> String:
	return crazy_moment_templates.get(phase, "")
