class_name PendingBet extends Resource
## Estado runtime de una apuesta confirmada por el jugador, aún sin resolver. No persiste entre
## sesiones (vive solo durante una run activa, gestionado por PendingBetsTracker).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 4.1.

@export var match_id: StringName
@export var market_offer: MarketOffer          # la opción concreta apostada (incluye option_key, threshold_display)
@export var stake: int
@export var tick_index_placed: int              # tick en el que se confirmó, para resolverla en el tick siguiente
