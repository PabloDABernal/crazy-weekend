# Decisions

Este documento almacena decisiones permanentes.

Cada decisión debe explicar:

- qué se decidió

- por qué

- cuándo

Nunca eliminar decisiones antiguas.

## 2026-06-30 — Motor y lenguaje del estudio

Qué: motor Godot, lenguaje GDScript, para cualquier juego construido con este AI Studio.

Por qué: base reutilizable y portable (se puede sacar `.ai-studio/` + `.claude/agents/` + `CLAUDE.md` a otro proyecto); Godot exporta nativo a PC/consola/móvil.

Cuándo: 2026-06-30, antes de definir el primer juego concreto (vision.md sigue vacío).

## 2026-06-30 — Subagentes reales

Qué: los 7 roles (Analyst, Coordinator, Architect, Programmer, Reviewer, QA, Game Designer) se implementan como subagentes reales en `.claude/agents/`, invocados por el Director vía Agent tool. `.ai-studio/agents/` queda como fuente de verdad humana de cada rol.

Por qué: Claude Code solo descubre subagentes invocables en `.claude/agents/`, no en carpetas custom como `.ai-studio/`.

Cuándo: 2026-06-30.

## 2026-06-30 — Eliminado .ai-studio/agents/

Qué: se borró `.ai-studio/agents/` (duplicaba contenido de `.claude/agents/`). `.claude/agents/*.md` pasa a ser única fuente de verdad de roles/responsabilidades/tools.

Por qué: evitar desincronización entre dos copias del mismo rol al editar.

Cuándo: 2026-06-30.

## 2026-07-01 — Fase inter-run mínima sí entra en el MVP (Historia E.6)

Qué: el MVP jugable de punta a punta no encadena runs sueltas en bucle sin ninguna transición entre ellas. Se incorpora una fase inter-run mínima (Historia E.6 en `backlog.md`, Épica E): pantalla de resumen de lunes (real, no mockeada) más una única decisión conversacional simplificada que otorga dinero extra directo antes de la siguiente run. La versión completa (3 decisiones/día de martes/miércoles/jueves, draft de amuletos, tienda, investigación, los otros 3 tipos de beneficio) sigue diferida a post-MVP.

Por qué: el Coordinator señaló en un reporte previo que el MVP, tal como estaba planteado, mockeaba la fase inter-run con dinero base fijo y una pantalla mínima de "continuar" (nota original en Historia E.5). Consultado explícitamente sobre si eso era aceptable para esta iteración, el Director Creativo pidió un mínimo de fase inter-run real ya en esta iteración, no la versión completa.

Cuándo: 2026-07-01.

## 2026-07-02 — Asignación de modelo por agente

Qué: cada subagente en `.claude/agents/` declara su propio `model` en el frontmatter en vez de heredar el de la sesión principal. Criterio: Opus para juicio creativo/técnico de mayor riesgo (Architect, Game Designer, Reviewer), Sonnet para trabajo estructurado o de implementación directa (Coordinator, Programmer), Haiku para tareas acotadas y mecánicas (Analyst, QA).

Por qué: el Director Creativo preguntó si tenía sentido usar un único modelo para todos los roles. Diferenciar reduce costo/latencia en tareas simples y reserva más capacidad para las decisiones que son más caras de deshacer si salen mal.

Cuándo: 2026-07-02.

## 2026-07-02 — Revisión de asignación de modelo: Sonnet reemplaza a Opus salvo en Architect

Qué: se corrige la asignación inicial de modelos. `game-designer`, `reviewer` y `playtester` pasan de Opus a Sonnet. Solo `architect` se mantiene en Opus. `coordinator`/`programmer` siguen en Sonnet, `analyst`/`qa` en Haiku.

Por qué: tras varias tareas reales de Game Designer en esta sesión (procesar feedback de playtest, sembrar datos de equipos), el Director Creativo observó que Sonnet 5 resuelve ese tipo de trabajo (síntesis estructurada, redacción de documentación siguiendo reglas ya fijadas) igual de bien que Opus mientras consume menos tokens. Se mantiene Opus solo para Architect, cuyas decisiones de diseño técnico son las más caras de deshacer si están mal.

Cuándo: 2026-07-02.

## 2026-07-02 — Nuevo rol: Playtester

Qué: se añade un octavo subagente, `playtester` (`.claude/agents/playtester.md`, modelo Opus), distinto de QA: QA valida que la funcionalidad no falle, Playtester evalúa si lo que no falla se siente divertido (ritmo, tensión, claridad de feedback), simulando sesiones y contrastándolas contra `vision.md`/`game-design.md`. Registra sus sesiones en `.ai-studio/memory/playtest-log.md`.

Por qué: tras el primer playtest manual del Director Creativo (feedback extenso sobre feel/UX, no solo bugs), el Director preguntó si el estudio necesitaba un agente dedicado a jugar y hacer brainstorming de diversión en vez de que esto recaiga solo en sesiones manuales del Director. Se confirmó que sí, como rol nuevo separado de QA.

Cuándo: 2026-07-02.