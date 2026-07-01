class_name MarketCatalog extends RefCounted
## Catálogo de los 8 MarketDef .tres del MVP (6 "mercados disponibles" de game-design.md, contando por
## separado los 3 umbrales de goles). Lógica pura de carga/lookup, sin estado propio persistente.
## Corners es solo estadística de panel en el MVP: no genera ningún MarketDef aquí (ver decisión 6 de
## .ai-studio/specs/epic-d-liga-y-partidos.md).
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 3.

const MARKET_DEFINITIONS_DIR: String = "res://resources/definitions/market/"


## Recorre res://resources/definitions/market/*.tres y devuelve todas las MarketDef del catálogo MVP.
static func get_all_market_definitions() -> Array[MarketDef]:
	var definitions: Array[MarketDef] = []
	var dir := DirAccess.open(MARKET_DEFINITIONS_DIR)
	if dir == null:
		return definitions
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource: Resource = ResourceLoader.load(MARKET_DEFINITIONS_DIR + file_name)
			if resource is MarketDef:
				definitions.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()
	return definitions


static func get_market_definition(market_id: StringName) -> MarketDef:
	for market in get_all_market_definitions():
		if market.market_id == market_id:
			return market
	return null
