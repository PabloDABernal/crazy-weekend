# Plan de pruebas manuales — MVP jugable (Crazy Weekend)

Diseñado por QA tras la implementación y revisión de las 5 épicas del MVP (base + B economía,
D liga/partidos, A tipos de victoria, C Expediente, E pantalla de apuestas). No hay entorno con Godot
instalado durante el desarrollo, así que nada de esto se ejecutó todavía — es la primera vez que se prueba.

## 0. Cómo abrir el proyecto

1. Instalá **Godot 4.3** (o compatible con 4.x) si no lo tenés: https://godotengine.org/download
2. Abrí Godot, "Import", seleccioná la carpeta del repo (`project.godot` está en la raíz).
3. F5 (o botón Play) para correr. La escena principal (`scenes/main/main.tscn`) ya está configurada como main scene.
4. Mirá la consola de salida (pestaña "Output" abajo) mientras jugás — cualquier error/warning de GDScript va a aparecer ahí. Si algo no carga o crashea, copiame el error de consola tal cual.

## Prioridad de ejecución recomendada

0. **Bug 1 — Momento Crazy bloqueante** (sección 5, nueva) — es el fix más reciente y el único que motivó una sesión de playtest interrumpida. Probalo primero.
1. **Cerrar y reabrir el juego después de jugar una run** (sección 3.1) — valida el fix de persistencia que se corrigió durante el desarrollo (antes no se guardaba nada).
2. **Intentar apostar más dinero del que tenés** (sección 3.2) — valida el fix de validación de stake.
3. Después, el resto en orden: golden path → casos extremos → errores.

---

## 1. Golden path (casos normales)

1. **Arranque**: F5 → pantalla "APOSTAR" → intro narrativa (avanza con click) → aterriza en la pantalla de apuestas 15 min antes del primer partido del viernes. Saldo inicial debe ser **500$** exactos en la primera partida.
2. **Cuenta regresiva**: el reloj baja hasta 0 y abre el primer tick automáticamente. El tutorial debe aparecer superpuesto (no bloqueante) señalando dónde apostar.
3. **Tutorial**: apostá el mínimo (50$) en cualquier mercado del primer partido — el tutorial se cierra solo. Si hay más de un partido en paralelo, todos deben recibir apuesta antes de poder avanzar el tick.
4. **Avanzar días**: completá los 6 ticks del viernes → pasa a sábado automáticamente → completá sábado → pasa a domingo.
5. **Victoria de run**: llegar al cierre del domingo con dinero > 0 → pantalla de cierre ("Fin de semana cerrado") → resumen de lunes → elegir una de las 3 decisiones de dinero extra (no hay opción de saltar) → arranca la run siguiente con el bonus ya sumado.
6. **Derrota de run**: si el dinero llega a 0$ en algún punto, la run **no** termina en el instante — termina recién en el siguiente tick obligatorio ("Ya es lunes"), sin mostrar ninguna apuesta de ese tick.

## 2. Casos extremos

- **All-in forzoso**: con saldo entre 1$ y 49$, el próximo tick debe exigir apostar el 100% de lo que queda (no 50$).
- **Momento Crazy**: eventualmente (siempre en sábado en las primeras runs, tick aleatorio pero nunca el primero) va a aparecer un sello "CRAZY" forzando apostar el 50%, 70% o 100% del dinero actual y restringiendo a 1-2 mercados. Si hay varios partidos en paralelo, resolverlo en cualquiera de ellos debe liberar a los demás (no debe quedar "pegado" pidiendo el monto forzoso en un segundo partido).
- **Desbloqueo de categoría de victoria**: jugando varias runs, revisá el Expediente (menú inter-run) — las categorías bloqueadas muestran solo nombre + pista ambigua, nunca el criterio exacto; al desbloquear, aparece la fecha/run y un texto (todavía placeholder, contenido narrativo pendiente).
- **Hito económico**: si en algún momento de una run el dinero supera 10.000$, el slot combinado del Expediente debe reflejarlo (incluida la sub-casilla de "10K" individual).
- **Expediente vacío**: al empezar, deben verse siempre 7 casillas de mercado + 1 combinada (2 de esas 7 son "reservadas" para contenido post-MVP — Corners y Resultado Exacto — y deben verse visualmente distintas de las bloqueadas normales, sin pista ni nombre real).

## 3. Casos que validan bugs corregidos durante el desarrollo (los más importantes de probar)

### 3.1 Persistencia entre sesiones
Jugá 1-2 runs, desbloqueá algo (una categoría o un bonus), **cerrá el juego del todo** y volvé a abrirlo. El número de run, los bonus acumulados y las categorías desbloqueadas deben seguir ahí. (Esto estaba roto — nunca se guardaba nada — y se corrigió durante el desarrollo; es el caso más importante de confirmar.)

### 3.2 No se puede apostar más dinero del que tenés
Con cualquier saldo, intentá escribir en el campo de apuesta un número mayor a tu saldo actual y confirmar. Debe rechazarse (no debería poder confirmarse esa apuesta). El caso límite —apostar exactamente todo el saldo (all-in voluntario)— sí debe permitirse.

### 3.3 Pago acreditado antes de evaluar bancarrota
Si tenés una apuesta pendiente que se resuelve favorablemente justo en el mismo tick en que tu saldo llegaría a 0 sin ese pago, el juego no debería declararte en bancarrota — el pago se acredita antes de esa evaluación. Es difícil de forzar a propósito; si en algún momento te "salva" un pago en el último segundo, es la señal de que funciona. Si en cambio ves que perdés la run a pesar de tener un pago pendiente que debería haberte salvado, es un bug a reportar.

## 4. Escenarios de error a probar deliberadamente

- Con 2+ partidos en paralelo, apostar en uno solo e intentar avanzar el tick — no debería avanzar hasta apostar en todos.
- Cambiar de foco entre partidos en medio de un Momento Crazy — la restricción debe aplicar a todos los partidos, no solo al que tenías enfocado originalmente.
- Cerrar el juego a mitad de una jornada (no en el cierre de un día) y reabrir — no debería haber crash ni estado roto; lo esperable es que arranque de nuevo desde el principio (no hay guardado a mitad de run, es una limitación conocida del MVP, no un bug).

## 5. Bug 1 — Momento Crazy bloqueante (verificación del fix)

El fix ya está commiteado (código + tests automatizados), pero los tests no se pudieron ejecutar en el entorno de desarrollo (sin Godot instalado) — esto es lo primero que deberías probar en tu máquina.

1. **Disparo único por tick**: llegá a un Momento Crazy con 2+ partidos vivos a la vez (overlay rojo/vino, sello "CRAZY"). Anotá el % forzoso y el importe exacto mostrado. Dejá pasar varios ticks de esos partidos sin apostar todavía — el overlay **no debe cambiar** (mismo %, mismo importe, mismos mercados permitidos). Antes del fix, cambiaba con cada partido que resolvía.
2. **"Continuar" se habilita**: apostá el importe forzoso en un mercado permitido y confirmá. El botón "Continuar →" debe habilitarse de inmediato. Este es el bloqueo exacto que interrumpió tu sesión de playtest.
3. **Mercado único no se bloquea**: si en algún Momento Crazy solo ves 1 mercado permitido, ese mercado nunca debe aparecer como restringido — siempre tiene que quedar al menos una opción para poder apostar.
4. **Dos Crazy en la misma run**: si te toca un Momento Crazy en viernes y otro en sábado, el segundo debe dispararse con normalidad (no debe quedar "inhibido" por haberse disparado ya uno antes).

Si alguno de estos falla, copiame qué viste paso a paso — probablemente hace falta otra vuelta de Programmer.

## 6. Fuera de alcance de esta primera ronda de pruebas

- Fases narrativas 3 y 4 del deterioro (requieren 13+ y 21+ runs jugadas — poco práctico en una sesión corta).
- Contenido narrativo real: todo el texto de comentarios, Expediente e intro está en placeholders "pendiente de redacción" — no es un bug, falta escribirlo.
- Arte/estética: todo usa controles básicos de Godot sin estilizar.

---

**Si encontrás algo que no coincide con lo descrito acá**, copiame: qué hiciste paso a paso, qué esperabas, qué pasó, y cualquier error de la consola de Godot — con eso lo mando de vuelta al estudio para que lo investiguen.
