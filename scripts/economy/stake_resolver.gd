class_name StakeResolver extends RefCounted
## Lógica pura de B.2 — stake mínimo obligatorio, all-in forzoso y detección de muerte de run.
## Sin dependencia de nodos, testeable de forma aislada. No aplica cuando hay un Momento Crazy activo
## (en ese caso el monto exigido lo calcula CrazyBetResolver, ver B.3).
## Ver .ai-studio/specs/epic-b-economia-de-run.md sección B.2.


## Devuelve el stake mínimo exigido al jugador en el tick actual, dado su dinero disponible.
## No decide el mercado ni ejecuta la apuesta — solo calcula el monto obligatorio.
static func compute_required_stake(current_money: int) -> int:
	if current_money >= EconomyRules.MINIMUM_STAKE:
		return EconomyRules.MINIMUM_STAKE
	# 0 < current_money < MINIMUM_STAKE -> all-in forzoso.
	# current_money == 0 -> caso de muerte de run (ver is_run_dead()); no debería llegar a pedir stake.
	return current_money


## Defensa en profundidad (fix QA Épica E): compara <= 0, no == 0. El flujo normal nunca debería dejar
## current_money negativo (la UI de apuestas ya valida stake <= RunState.get_money() antes de
## confirmar), pero si algún camino futuro dejara pasar un valor negativo, la detección de muerte de
## run sigue siendo correcta en vez de quedar en un estado no contemplado por ninguna spec.
static func is_run_dead(current_money: int) -> bool:
	return current_money <= 0
