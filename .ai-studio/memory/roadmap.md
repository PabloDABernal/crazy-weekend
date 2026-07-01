# Roadmap

Solo contiene grandes hitos.

Nunca tareas.

---

## Hito — Final canónico jugable, versión MVP (6 de 8 categorías)
El juego tiene una condición de victoria real más allá de "sobrevivir el domingo": el jugador puede acumular categorías de tipos de victoria a lo largo de runs y temporadas, y completar la colección dispara el final canónico. **Decisión de alcance tomada por el Director Creativo**: el MVP lanza con 6 de las 8 categorías totales jugables (5 de mercado — Base, Medias, Goles, Tarjetas, Faltas — más el slot combinado de hito económico); Corners y Resultado Exacto quedan diferidos a post-MVP. Incluye la economía de run (dinero inicial, stake mínimo, Momento Crazy) que da forma a cómo se juega cada run, y la pantalla "Tu Expediente" donde el jugador percibe su propio progreso hacia ese final (con las 8 casillas visibles, 2 de ellas aún no alcanzables en esta versión). Ver `backlog.md` → Épicas A, B, C.

## Hito — MVP jugable de punta a punta (núcleo de run)
El juego se puede jugar de principio a fin como bucle único de fin de semana: pantalla de inicio con intro narrativa, tutorial integrado de la primera apuesta, jornada del viernes con partidos generados por una liga ficticia simple (20 equipos), simulación por ticks de 15 minutos con panel informativo y comentarios (sin visual de partido), los 6 mercados de apuesta del MVP (1X2, goles 2.5, primer goleador, ambos marcan, tarjetas, faltas) con probabilidades en rango, interfaz de apuestas tipo casa de apuestas fría con saldo y apuestas pendientes visibles, y cierre de run (domingo con dinero > 0 = victoria de run; 0$ en cualquier tick = derrota, "Ya es lunes"). Ver `backlog.md` → Épicas D (simulación de liga/partidos) y E (UI de apuestas e interacción de tick). Implementa formalmente el contrato `BettingTickService` que `_arquitectura-base.md` (sección 4) dejaba pendiente.

Este hito es paralelo/complementario al de "Final canónico jugable, versión MVP" (Épicas A/B/C): ese hito cubre la meta-progresión y la win condition de colección; este hito cubre que exista partido, mercado y pantalla donde apostar. Ambos hitos son necesarios juntos para un MVP verdaderamente jugable — ninguno sustituye al otro.

**Gap señalado deliberadamente fuera de este MVP** (no es un descuido, es alcance reducido a propósito, decisión de Coordinator sin bloquear el MVP):
- **Fase inter-run completa (lunes-jueves)**: decisiones conversacionales, eventos de lore, draft de amuletos in-run y tienda inter-run, investigación que colapsa el rango de probabilidad a un valor preciso. El MVP de este hito mockea la transición entre runs con dinero base fijo (500$ + bonus de meta-progresión ya definidos en Épica B.1) y una pantalla mínima de resumen/continuar (ver Historia E.5), sin fase inter-run jugable real.
- **Sistema de amuletos completo**: depende del draft in-run/tienda inter-run que no existe todavía; el MVP de este hito no incluye ningún amuleto activo.
- **Investigación que colapsa probabilidades**: el jugador siempre ve el rango ancho ("entre 40% y 65%"), nunca el valor refinado por investigación (ver Historia D.5).
- **Liga con historial completo de temporadas/regeneración en jornada 38**: el MVP genera y evoluciona la liga jornada a jornada (Historia D.2), pero el ciclo completo de cierre de temporada (jornada 38, regeneración, persistencia de meta-progresión entre temporadas) queda para una iteración posterior.

Próxima iteración candidata tras este hito: promover la fase inter-run completa (con draft/tienda/investigación) a épica propia — hoy es un gap identificado, no una épica activa.

## Hito — Colección extendida (contenido post-MVP)
Contenido posterior al final canónico versión MVP, en dos frentes:
- Completar el final canónico a su versión completa de 8/8 categorías, incorporando los mercados de Corners y Resultado Exacto (`backlog.md` → Épica A (post-MVP), Historias A.6 y A.7).
- Las 4 categorías "de cómo" (Hierro, Ludópata, Domingo, Fantasma) y el Anexo del Expediente, que amplían la vida del juego sin requerir sistemas nuevos (`backlog.md` → Ideas).

Hito de contenido, posterior al hito de "Final canónico jugable, versión MVP".