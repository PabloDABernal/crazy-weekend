extends Node
## NarrativePhase (autoload) — deriva la fase narrativa (1-4) a partir de
## MetaProgress.get_current_run_number(). Se centraliza aquí la tabla runs->fase para que Épica B (B.4),
## Épica C (deterioro visual del Expediente) y el sistema de amuletos Absurdos consulten el mismo mapeo.
## Ver .ai-studio/specs/_arquitectura-base.md sección 2.3.

enum Phase { PHASE_1 = 1, PHASE_2 = 2, PHASE_3 = 3, PHASE_4 = 4 }

# Tabla fija de "Arco narrativo" general (game-design.md).
# PHASE_1: runs 1-5 | PHASE_2: runs 6-12 | PHASE_3: runs 13-20 | PHASE_4: runs 21+
# Nota: B.4 usa una tabla DISTINTA de cadencia de Momento Crazy (ver EconomyRules.CRAZY_MOMENT_SCHEDULE_BY_PHASE).


func get_current_phase() -> Phase:
	return get_phase_for_run(MetaProgress.get_current_run_number())


## Función pura, usable en tests sin depender del run activo.
func get_phase_for_run(run_number: int) -> Phase:
	if run_number <= 5:
		return Phase.PHASE_1
	elif run_number <= 12:
		return Phase.PHASE_2
	elif run_number <= 20:
		return Phase.PHASE_3
	else:
		return Phase.PHASE_4
