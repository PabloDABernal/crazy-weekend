class_name CommentaryResolver extends RefCounted
## Contrato de selección de comentarios de tick (D.4) — lógica de selección/prioridad y sustitución
## de placeholders. El banco de frases (contenido real) es responsabilidad de Game Designer/narrativa.
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 7.

## La spec (sección 7) habla de "2-3 líneas de 2-3 candidatas" como expectativa de contenido típica,
## no como mínimo forzado matemáticamente: si un tick solo produce un evento relevante con template
## disponible, se devuelve esa única línea en vez de rellenar con contenido no especificado por la
## spec. MAX_LINES sí se respeta como tope estricto.
const MAX_LINES: int = 3


## Devuelve 2-3 líneas de texto ya resueltas (placeholders sustituidos), priorizando eventos de mayor
## relevancia narrativa (GOAL > CARD > SHOT_ON_TARGET > resto) y respetando el tono de context.phase.
## Si context.is_crazy_moment == true, ignora los eventos del partido y devuelve la línea dirigida
## directamente al jugador (banco de frases de Momento Crazy).
##
## Nota de implementación: TickCommentaryContext (contrato fijado por la spec, sección 7) solo lleva
## home_team_display_name/away_team_display_name, no home_team_id/away_team_id — no alcanza para
## mapear MatchTickEvent.team_id (StringName de equipo) a un display name de forma genérica dentro del
## propio recurso. Se reciben home_team_id/away_team_id como parámetros adicionales del método (quien
## arma TickCommentaryContext, MatchSimulationService, ya conoce ambos IDs vía MatchTickState) en vez
## de asumir un mapeo implícito no declarado en el contrato de datos.
static func resolve_commentary_lines(context: TickCommentaryContext, phrase_bank: CommentaryPhraseBank, home_team_id: StringName, away_team_id: StringName) -> Array[String]:
	if context.is_crazy_moment:
		return _resolve_crazy_moment_lines(context, phrase_bank)

	var prioritized_events: Array[MatchTickEvent] = _prioritize_events(context.events)

	if prioritized_events.is_empty():
		return _resolve_no_event_lines(context, phrase_bank)

	var lines: Array[String] = []
	for event in prioritized_events:
		if lines.size() >= MAX_LINES:
			break
		var template: String = phrase_bank.get_template(event.kind, context.phase)
		if template.is_empty():
			continue
		lines.append(_apply_placeholders(template, context, event, home_team_id, away_team_id))

	return lines


## Orden de prioridad: GOAL > CARD > SHOT_ON_TARGET > resto (SHOT_OFF_TARGET, CORNER, FOUL, NO_EVENT).
## NO_EVENT nunca se incluye en el resultado (se trata como "sin eventos relevantes").
static func _prioritize_events(events: Array[MatchTickEvent]) -> Array[MatchTickEvent]:
	var relevant: Array[MatchTickEvent] = []
	for event in events:
		if event.kind != MatchTickEvent.EventKind.NO_EVENT:
			relevant.append(event)

	relevant.sort_custom(func(a: MatchTickEvent, b: MatchTickEvent) -> bool:
		return _priority_rank(a.kind) < _priority_rank(b.kind)
	)
	return relevant


static func _priority_rank(kind: MatchTickEvent.EventKind) -> int:
	match kind:
		MatchTickEvent.EventKind.GOAL:
			return 0
		MatchTickEvent.EventKind.CARD:
			return 1
		MatchTickEvent.EventKind.SHOT_ON_TARGET:
			return 2
		_:
			return 3


## Tramo sin eventos relevantes (tick_events solo contiene NO_EVENT/tiros fallidos u otros de baja
## relevancia que igual quedaron filtrados): se usa la plantilla de "tramo sin eventos" por fase.
static func _resolve_no_event_lines(context: TickCommentaryContext, phrase_bank: CommentaryPhraseBank) -> Array[String]:
	var template: String = phrase_bank.get_no_event_template(context.phase)
	if template.is_empty():
		return []
	return [_apply_placeholders(template, context, null, &"", &"")]


static func _resolve_crazy_moment_lines(context: TickCommentaryContext, phrase_bank: CommentaryPhraseBank) -> Array[String]:
	var template: String = phrase_bank.get_crazy_moment_template(context.phase)
	if template.is_empty():
		return []
	return [_apply_placeholders(template, context, null, &"", &"")]


## Sustituye placeholders {team}, {player}, {score} del template. {team}/{player} se resuelven desde
## el evento si está presente; {score} siempre desde el contexto (marcador actual).
static func _apply_placeholders(template: String, context: TickCommentaryContext, event: MatchTickEvent, _home_team_id: StringName, away_team_id: StringName) -> String:
	var text: String = template
	text = text.replace("{score}", "%d-%d" % [context.score_home, context.score_away])

	if event != null:
		var team_display_name: String = context.away_team_display_name if event.team_id == away_team_id else context.home_team_display_name
		text = text.replace("{team}", team_display_name)
		text = text.replace("{player}", String(event.player_id))
	else:
		text = text.replace("{team}", "")
		text = text.replace("{player}", "")

	return text
