class_name StakeGate extends RefCounted
## Lógica pura de E.3/E.4 — determina el monto mínimo exigido para el tick vigente de un partido
## concreto, combinando el stake normal (StakeResolver, B.2) y el stake forzoso de Momento Crazy
## (CrazyBetContext, B.3) sin reimplementar ninguno de los dos.
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 3.4.


## Determina el monto mínimo exigido para el tick vigente de UN partido concreto.
## No decide restricción de mercado -- eso ya lo resuelve CrazyBetContext.allowed_market_ids directamente.
static func compute_required_amount(current_money: int, active_crazy_bet: CrazyBetContext) -> int:
	if active_crazy_bet != null:
		return active_crazy_bet.forced_stake_amount
	return StakeResolver.compute_required_stake(current_money)
