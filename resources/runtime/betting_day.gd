class_name BettingDay extends RefCounted
## Namespace estático simple para identificar la jornada de una run (viernes/sábado/domingo).
## No es un Resource: no necesita serializarse, solo agrupa el enum compartido.
## Ver .ai-studio/specs/_arquitectura-base.md sección 3.2.

enum Day { FRIDAY = 0, SATURDAY = 1, SUNDAY = 2 }
