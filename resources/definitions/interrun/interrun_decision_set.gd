class_name InterrunDecisionSet extends Resource
## Contenedor simple de las 2-3 opciones de la decisión conversacional de E.6 (MVP). Mismo patrón que
## VictoryRequirementSet (Épica A) para no hardcodear opciones en el script.
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 8.3.

@export var options: Array[InterrunDecisionOption] = []
