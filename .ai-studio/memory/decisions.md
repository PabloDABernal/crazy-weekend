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