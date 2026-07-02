class_name ArrayUtils extends RefCounted
## Utilidades genéricas de Array compartidas entre dominios (sin estado, sin dependencias de
## contenido). Hoy solo aloja el Fisher-Yates usado por LeagueGenerator (D.1) y MatchdayScheduler
## (D.6), que antes estaba duplicado en ambos.


## Baraja `array` in place con Fisher-Yates, usando `rng` para el determinismo (mismo seed -> mismo
## resultado).
static func shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
