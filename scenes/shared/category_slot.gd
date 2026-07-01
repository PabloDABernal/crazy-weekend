class_name CategorySlot extends Control
## Componente reutilizable de la pantalla "Tu Expediente" (Épica C): representa una casilla de
## categoría de tipo de victoria, ya sea de Familia A (mercado), sub-casilla de Familia B (hito
## económico), casilla reservada (post-MVP) o casilla fantasma (fase 4, C.2).
## Ver .ai-studio/specs/epic-c-tu-expediente.md sección 2.2.
##
## Regla de seguridad de contenido: en estado SEALED este script NUNCA lee VictoryCategoryDef (Épica A).
## Solo lee VictoryCategoryFlavor (contenido) y VictoryCategoryState.unlocked (para decidir el estado).

const FLAVOR_DEFINITIONS_DIR: String = "res://resources/definitions/victory_flavor/"

## category_id del único VictoryCategoryState (Épica A) que respalda las 3 sub-casillas de hito
## económico. Las sub-casillas no tienen VictoryCategoryState propio: su "unlocked" se deriva de
## VictoryCategoryState("economic_milestone_slot").milestone_reached[threshold] — ver spec Épica C 2.4.
const ECONOMIC_MILESTONE_SLOT_CATEGORY_ID: StringName = &"economic_milestone_slot"

enum SlotState { SEALED, UNLOCKED, RESERVED }
enum SlotVariant { STANDARD, SUB_MILESTONE, PHANTOM }

signal unlock_animation_finished(category_id: StringName)

@onready var _sealed_state: Control = $SealedState
@onready var _redacted_name_label: Label = $SealedState/RedactedNameLabel
@onready var _hint_label: Label = $SealedState/HintLabel

@onready var _unlocked_state: Control = $UnlockedState
@onready var _display_name_label: Label = $UnlockedState/DisplayNameLabel
@onready var _criteria_label: Label = $UnlockedState/CriteriaLabel
@onready var _achievement_date_label: Label = $UnlockedState/AchievementDateLabel
@onready var _flavor_text_label: Label = $UnlockedState/FlavorTextLabel

@onready var _reserved_state: Control = $ReservedState
@onready var _reserved_label: Label = $ReservedState/ReservedLabel

@onready var _phantom_overlay: Control = $PhantomOverlay
@onready var _manuscript_overlay: Control = $ManuscriptOverlay
@onready var _handwritten_annotation_label: Label = $ManuscriptOverlay/HandwrittenAnnotationLabel

@onready var _unlock_animation_player: AnimationPlayer = $UnlockAnimationPlayer

var _category_id: StringName = &""
var _variant: SlotVariant = SlotVariant.STANDARD
var _state: SlotState = SlotState.SEALED
var _flavor: VictoryCategoryFlavor = null

## Solo usado en SlotVariant.SUB_MILESTONE: umbral de dinero (10000/100000/1000000) que este slot
## representa dentro de VictoryCategoryState("economic_milestone_slot").milestone_reached.
var _sub_milestone_threshold: int = 0


func _ready() -> void:
	_manuscript_overlay.visible = false
	_phantom_overlay.visible = false


## Configura el slot para una categoría real de Familia A (variant STANDARD) o para la casilla
## fantasma de fase 4 (variant PHANTOM, ver expediente_corruption_controller.gd).
## No dispara animación: usar para el estado inicial al abrir la pantalla.
func setup(category_id: StringName, variant: SlotVariant = SlotVariant.STANDARD) -> void:
	_category_id = category_id
	_variant = variant
	_flavor = _load_flavor(category_id)
	refresh()


## Configura el slot como sub-casilla de hito económico (Familia B, ver spec 2.4). A diferencia de
## setup(), el estado "unlocked" no sale de un VictoryCategoryState propio (no existe uno por
## sub-hito en Épica A): sale de VictoryCategoryState("economic_milestone_slot").milestone_reached[threshold].
## flavor_category_id identifica solo el .tres de VictoryCategoryFlavor a cargar (ej. "economic_milestone_10k").
func setup_sub_milestone(flavor_category_id: StringName, threshold: int) -> void:
	_category_id = flavor_category_id
	_variant = SlotVariant.SUB_MILESTONE
	_sub_milestone_threshold = threshold
	_flavor = _load_flavor(flavor_category_id)
	refresh()


## Configura el slot como reservado (post-MVP, sin VictoryCategoryFlavor real detrás) — ver spec 2.3.
func setup_reserved(display_hint: String) -> void:
	_category_id = &""
	_variant = SlotVariant.STANDARD
	_flavor = null
	_state = SlotState.RESERVED
	_reserved_label.text = display_hint
	_update_visible_state()


## Devuelve el category_id actualmente configurado (&"" si el slot está en modo RESERVED/sin configurar).
func get_category_id() -> StringName:
	return _category_id


## Devuelve el estado visual actual del slot (SEALED / UNLOCKED / RESERVED).
func get_slot_state() -> SlotState:
	return _state


## Refresca el contenido visible leyendo el estado actual de VictoryCategoryState (Épica A) y
## VictoryCategoryFlavor para el category_id ya configurado. Idempotente.
func refresh() -> void:
	if _category_id == &"":
		return

	if _variant == SlotVariant.SUB_MILESTONE:
		_refresh_sub_milestone()
		return

	if _variant == SlotVariant.PHANTOM:
		# PhantomSlot no tiene VictoryCategoryState ni se registra en MetaProgress/VictoryTracker
		# (spec Épica C 3.3): siempre se queda en SEALED por defecto; el destape congelado a mitad lo
		# fuerza explícitamente ExpedienteCorruptionController vía set_phantom_partial_reveal().
		_state = SlotState.SEALED
		_populate_sealed_state()
		_update_visible_state()
		return

	var category_state: VictoryCategoryState = MetaProgress.get_victory_category_state(_category_id)

	if category_state.unlocked:
		_state = SlotState.UNLOCKED
		_populate_unlocked_state(category_state)
	else:
		_state = SlotState.SEALED
		_populate_sealed_state()

	_update_visible_state()


## Variante de refresh() para sub-casillas de hito económico: "unlocked" y fecha/run salen del
## diccionario milestone_reached del VictoryCategoryState combinado, no de un estado propio (ver
## setup_sub_milestone()). VictoryCategoryState no guarda fecha/run por sub-hito individual — en su
## ausencia, si el slot combinado completo ya está unlocked se reutiliza su fecha/run como aproximación;
## si el sub-hito está reached pero el slot combinado aún no (otro sub-hito lo resolvió primero),
## unlocked_at_run_number sigue en su sentinel (-1) y _populate_unlocked_state()/_resolve_flavor_template()
## muestran un fallback ("Fecha no registrada" / "?") en vez de interpolar el sentinel crudo.
func _refresh_sub_milestone() -> void:
	var combined_state: VictoryCategoryState = MetaProgress.get_victory_category_state(ECONOMIC_MILESTONE_SLOT_CATEGORY_ID)
	var reached: bool = combined_state.milestone_reached.get(_sub_milestone_threshold, false)

	if reached:
		_state = SlotState.UNLOCKED
		_populate_unlocked_state(combined_state)
	else:
		_state = SlotState.SEALED
		_populate_sealed_state()

	_update_visible_state()


## Reproduce la animación de destape y transiciona a UNLOCKED al terminar. Emite unlock_animation_finished.
func play_unlock_animation() -> void:
	refresh()
	if _unlock_animation_player.has_animation("unlock"):
		_unlock_animation_player.play("unlock")
		await _unlock_animation_player.animation_finished
	unlock_animation_finished.emit(_category_id)


## Activa/desactiva el overlay de anotación manuscrita (fase 3+, C.2). No cambia SlotState.
func set_manuscript_overlay_visible(overlay_visible: bool, annotation_text: String = "") -> void:
	_manuscript_overlay.visible = overlay_visible
	if overlay_visible:
		_handwritten_annotation_label.text = annotation_text


## Solo válido en SlotVariant.PHANTOM. Detiene la animación de destape en un punto intermedio fijo
## (nunca 100%) y la deja congelada ahí — decisión de diseño explícita, no un bug de animación:
## "la casilla nunca se completa del todo" (game-design.md).
func set_phantom_partial_reveal() -> void:
	if _variant != SlotVariant.PHANTOM:
		return
	_phantom_overlay.visible = true
	if _unlock_animation_player.has_animation("unlock"):
		var anim: Animation = _unlock_animation_player.get_animation("unlock")
		_unlock_animation_player.play("unlock")
		_unlock_animation_player.seek(anim.length * 0.5, true)
		_unlock_animation_player.pause()


func _populate_sealed_state() -> void:
	if _flavor == null:
		return
	_redacted_name_label.text = _flavor.display_name
	_hint_label.text = _flavor.sealed_hint_text


func _populate_unlocked_state(category_state: VictoryCategoryState) -> void:
	if _flavor == null:
		return
	_display_name_label.text = _flavor.display_name
	_criteria_label.text = _flavor.unlocked_criteria_text
	# category_state.unlocked_at_run_number == -1 (sentinel, ver victory_category_state.gd) ocurre en
	# sub-casillas de hito económico (SUB_MILESTONE) cuando este sub-hito ya fue reached pero el slot
	# combinado como conjunto aún no está unlocked (otro sub-hito distinto lo resolverá primero) — no
	# hay fecha/run individual por sub-hito en Épica A. Se muestra un fallback en vez de interpolar el
	# sentinel ("Run -1 — ").
	if category_state.unlocked_at_run_number == -1:
		_achievement_date_label.text = "Fecha no registrada"
	else:
		_achievement_date_label.text = "Run %d — %s" % [category_state.unlocked_at_run_number, category_state.unlocked_at_date]
	_flavor_text_label.text = _resolve_flavor_template(_flavor.unlocked_flavor_text_template, category_state)


func _resolve_flavor_template(template: String, category_state: VictoryCategoryState) -> String:
	# Mismo caso de sentinel que _populate_unlocked_state(): sin fecha/run individual disponible,
	# no se interpola el sentinel crudo (-1 / "") en el flavor text.
	var fecha_text: String = category_state.unlocked_at_date if category_state.unlocked_at_run_number != -1 else "fecha no registrada"
	var run_text: String = str(category_state.unlocked_at_run_number) if category_state.unlocked_at_run_number != -1 else "?"
	var resolved: String = template
	resolved = resolved.replace("{fecha}", fecha_text)
	resolved = resolved.replace("{run}", run_text)
	return resolved


func _update_visible_state() -> void:
	_sealed_state.visible = _state == SlotState.SEALED
	_unlocked_state.visible = _state == SlotState.UNLOCKED
	_reserved_state.visible = _state == SlotState.RESERVED


func _load_flavor(category_id: StringName) -> VictoryCategoryFlavor:
	var path: String = FLAVOR_DEFINITIONS_DIR + String(category_id) + ".tres"
	if not ResourceLoader.exists(path):
		push_warning("CategorySlot: no se encontró VictoryCategoryFlavor para category_id '%s' en %s" % [category_id, path])
		return null
	var resource: Resource = ResourceLoader.load(path)
	if resource is VictoryCategoryFlavor:
		return resource
	push_warning("CategorySlot: el recurso en %s no es un VictoryCategoryFlavor" % path)
	return null
