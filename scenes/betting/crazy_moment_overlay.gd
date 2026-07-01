class_name CrazyMomentOverlay extends Control
## Presentación desacoplada del Momento Crazy (B.3): solo consume CrazyBetContext/señales, nunca
## decide lógica de restricción -- eso ya lo resolvió CrazyBetResolver (B.3).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 5.

@onready var _alert_tint_overlay: ColorRect = $AlertTintOverlay
@onready var _crazy_seal_label: Label = $CrazySealLabel
@onready var _forced_stake_label: Label = $ForcedStakeLabel


func _ready() -> void:
	visible = false


func show_crazy_moment(crazy_bet: CrazyBetContext) -> void:
	visible = true
	_forced_stake_label.text = "%d%% obligatorio ($%d)" % [crazy_bet.stake_percentage, crazy_bet.forced_stake_amount]


func hide_crazy_moment() -> void:
	visible = false
