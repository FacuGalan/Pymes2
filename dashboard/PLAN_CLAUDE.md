# Plan: pasar el asistente del Tablero de Groq a Claude

Estado: **plan**, no implementado. Hoy el asistente usa Groq (`llama-3.3-70b-versatile`).
Todo lo demás del tablero (validación de seguridad, solo lectura, log, pantalla) no cambia.

## Por qué

- Redacta mejor en castellano y arma SQL más confiable con prompts largos.
- **Salida estructurada garantizada** (`output_config.format` con JSON Schema): el JSON
  siempre es válido y respeta el esquema. Se eliminan `IAJsonDe` y los casos de "el modelo
  devolvió texto en vez de JSON".
- **Caché del prompt de sistema**: el prompt largo (esquema del negocio + reglas) se cobra
  a una fracción después de la primera pregunta.

## Qué se toca (todo en DASHWEB.PRG)

1. `config_ia` (bcn_config): una fila nueva con `proveedor = 'CLAUDE'`, `modelo`,
   `modelo_redaccion` y la `api_key` de Anthropic. Se activa esa fila y se desactiva la de Groq.
   Volver atrás = reactivar la fila de Groq.
2. `IAPost`: si el proveedor es CLAUDE, arma otro body y otros encabezados (abajo).
3. `IALeerRespuesta`: en Claude el texto viene en `content[]` (bloques), no en
   `choices[1].message.content`. Hay que tomar el bloque `type = "text"` y revisar `stop_reason`.
4. Nada más: el resto del circuito (validar, ejecutar en solo lectura, redactar, log) queda igual.

## Llamada HTTP (MSXML2.ServerXMLHTTP, igual que hoy)

```
POST https://api.anthropic.com/v1/messages
Content-Type: application/json
x-api-key: <api_key de config_ia>
anthropic-version: 2023-06-01
```

(Groq usa `Authorization: Bearer`; Claude usa `x-api-key`.)

### Body del planificador

```json
{
  "model": "claude-opus-5-5",
  "max_tokens": 4000,
  "output_config": {
    "effort": "low",
    "format": { "type": "json_schema", "schema": { ...ESQUEMA_PLAN... } }
  },
  "system": [
    { "type": "text", "text": "<IAPromptPlan() sin la fecha>", "cache_control": { "type": "ephemeral" } },
    { "type": "text", "text": "Hoy es jueves 2026-10-15. Este mes = desde 2026-10-01..." }
  ],
  "messages": [
    { "role": "user", "content": "¿cuánto vendí este mes?" }
  ]
}
```

- **`system` va aparte**, no como mensaje con `role: "system"` como en Groq.
- **Caché**: la marca `cache_control` va en el bloque fijo (esquema + reglas). La fecha de
  hoy va en un bloque **después** de la marca: si quedara adentro, el caché se invalidaría
  todos los días (cualquier byte que cambie antes de la marca invalida lo que sigue).
  Los ejemplos aprendidos (`IAEjemplos`) también van después de la marca, porque cambian.
- Para ver que el caché funciona: en la respuesta, `usage.cache_read_input_tokens` tiene que
  ser mayor que 0 a partir de la segunda pregunta. Si da 0 siempre, algo cambia el prefijo.
- **Effort**: arrancar en `low` para el planificador (armar un SELECT es una tarea acotada) y
  subir a `medium` solo si se ven consultas mal armadas. En Opus 5.5 el pensamiento siempre
  está activo y no se puede apagar (`thinking: disabled` da error 400); el effort es el control.
- No mandar `temperature` (en estos modelos da error 400).

### ESQUEMA_PLAN (JSON Schema)

Todos los objetos llevan `additionalProperties: false` y `required` (obligatorio en salida
estructurada; no se admiten `minLength`, `maximum`, etc.):

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["tipo", "titulo", "sql", "grafico", "columnas", "texto"],
  "properties": {
    "tipo":    { "type": "string", "enum": ["consulta", "respuesta"] },
    "titulo":  { "type": "string" },
    "sql":     { "type": "string" },
    "grafico": { "type": "string", "enum": ["barras", "lineas", "torta", "ninguno"] },
    "texto":   { "type": "string" },
    "columnas": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["nombre", "formato"],
        "properties": {
          "nombre":  { "type": "string" },
          "formato": { "type": "string", "enum": ["texto", "moneda", "numero", "cantidad", "porcentaje", "fecha"] }
        }
      }
    }
  }
}
```

(Con `tipo = "respuesta"` el modelo deja `sql` vacío y completa `texto`.)

### Body del redactor

Igual, con `system` = `IAPromptRedac()` (con caché), el contexto de los resultados como
mensaje de usuario y un esquema `{ "respuesta": string }`. El modelo y el effort los elige
`modelo_redaccion` (ver costos).

### Leer la respuesta

```json
{ "content": [ { "type": "text", "text": "{\"tipo\":\"consulta\", ...}" } ],
  "stop_reason": "end_turn",
  "usage": { "input_tokens": ..., "output_tokens": ..., "cache_read_input_tokens": ... } }
```

- Puede haber bloques `type = "thinking"` antes del texto: hay que buscar el bloque `text`,
  no tomar el primero.
- `stop_reason`:
  - `end_turn`: normal.
  - `max_tokens`: el JSON puede venir cortado; reintentar con más `max_tokens`.
  - `refusal`: el modelo declinó (filtros de seguridad); mostrar "No puedo responder eso".
- Errores HTTP: 429/5xx se pueden reintentar una vez; 400/401 no (es configuración).
- Guardar `usage` en `ia_log` (dos columnas nuevas: tokens de entrada y de salida) para medir
  el costo real por pregunta.
- Opcional: Anthropic ofrece un modelo de respaldo automático si el modelo declina
  (`fallbacks: "default"` con el encabezado `anthropic-beta: server-side-fallback-2026-07-01`).
  Lo recomiendo activado, junto con el manejo de `refusal`.

## Modelos y costos

Precios publicados por Anthropic (USD por millón de tokens, tabla al 06/10/2026; confirmar
antes de decidir):

| Modelo | Entrada | Salida | Lectura de caché |
|---|---|---|---|
| Claude Opus 5.5 (`claude-opus-5-5`) | 4,00 | 20,00 | 0,20 |
| Claude Sonnet 5.5 (`claude-sonnet-5-5`) | 2,00 | 10,00 | 0,20 |
| Claude Haiku 5.5 (`claude-haiku-5-5`) | 0,10 | 0,50 | - |

- **Recomendación inicial:** Opus 5.5 para las dos llamadas, con effort `low`. Si el costo
  pesa, pasar primero el **redactor** a Haiku 5.5 o Sonnet 5.5 (redactar 3 oraciones es la
  parte fácil) y dejar el planificador en Opus. Es decisión de negocio; se cambia solo con
  `modelo_redaccion` en `config_ia`.
- **Estimación (aproximada, a medir):** el prompt del planificador ronda 3.000-4.000 tokens
  (va a caché), la pregunta y la respuesta unos cientos. Lo que más pesa es la **salida**,
  que incluye los tokens de pensamiento. Con effort `low` debería quedar en el orden de
  centavos de dólar por pregunta. El número real sale de `usage` guardado en el log.
- El caché dura 5 minutos por defecto: una consulta tras otra lo aprovecha; si pasan más
  de 5 minutos, la siguiente vuelve a pagar la escritura (1,25x el precio de entrada).

## Datos y privacidad

Igual que con Groq: el modelo recibe la pregunta, el esquema del negocio (no los datos) y,
en el redactor, hasta 40 filas del resultado (por ejemplo, nombres de clientes con su
deuda). Conviene avisarlo a los clientes en la condición de uso del asistente.

## Pasos

1. Cuenta en console.anthropic.com, generar clave, cargar saldo y un límite de gasto mensual.
2. Fila `CLAUDE` en `config_ia` (desactivada).
3. Implementar en `IAPost` / `IALeerRespuesta` y las columnas de tokens en `ia_log`.
4. Probar con el mismo servidor de imitación local y después con la clave real en un cliente
   de prueba (comparar respuestas Groq vs. Claude sobre las mismas 20 preguntas del log).
5. Activar la fila de Claude.
