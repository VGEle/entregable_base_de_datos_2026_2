# Análisis de almacenamiento, costo y optimización

## Alcance y supuestos

Este análisis utiliza la tabla `bookings` porque concentra las consultas de agenda del Sprint 2 y tiene índices para cliente, profesional, estado y fecha.

Los valores son supuestos académicos coherentes con la estimación del `README.md`:

| Parámetro | Valor | Justificación |
|---|---:|---|
| Tamaño de página o bloque `P` | 8.192 bytes | Tamaño habitual de página en PostgreSQL. |
| Tuplas actuales `T_R` | 5.000 | Reservas históricas iniciales estimadas. |
| Valores distintos de `professional_id` `V(a,R)` | 100 | Un profesional por cada 50 reservas iniciales en promedio. |
| Tamaño promedio de `status` | 12 bytes | Valor variable, incluyendo estados de reserva. |
| Tamaño promedio de `cancellation_reason` | 40 bytes | Solo aplica a una parte de las reservas. |
| Memoria disponible `M` | 20 páginas | Supuesto para comparar algoritmos de reunión. |

Las fórmulas se expresan en bytes y páginas de E/S. Los tamaños son aproximaciones para comparar alternativas, no sustituyen una medición con `pg_column_size` y `EXPLAIN (ANALYZE, BUFFERS)` en producción.

## 1. Estrategia de almacenamiento e índices

### 1.1 Longitud estimada de un registro

La tabla `bookings` contiene:

- Cuatro UUID: `id`, `customer_id`, `professional_id` y `service_id`: `4 × 16 = 64` bytes.
- Cinco marcas de tiempo: `start_time`, `end_time`, `created_at`, `updated_at` y `cancelled_at`: `5 × 8 = 40` bytes.
- Campos variables: `status` y `cancellation_reason`.
- Mapa de bits de nulabilidad y control estimado: `2` bytes.

Aplicando la fórmula de referencia:

```text
L = 4 · #campos variables
    + Σ tamaño de campos fijos
    + tamaño del mapa de bits
    + Σ tamaño estimado de campos variables
```

```text
L = 4 · 2 + 104 + 2 + 12 + 40
L = 166 bytes por registro
```

El cálculo no incluye el overhead interno específico de cada versión de PostgreSQL; se conserva como una aproximación académica uniforme.

### 1.2 Registros y páginas de la tabla

Para `F_R` registros por página:

```text
F_R = ⌊(P − 2) / (4 + L)⌋
F_R = ⌊(8.192 − 2) / (4 + 166)⌋
F_R = ⌊8.190 / 170⌋
F_R = 48 registros por página
```

Para `B_R` páginas de la relación:

```text
B_R = ⌈T_R / F_R⌉
B_R = ⌈5.000 / 48⌉
B_R = 105 páginas
```

Por tanto, el tamaño estimado de `bookings` es:

```text
105 páginas × 8.192 bytes = 860.160 bytes ≈ 840 KiB
```

### 1.3 Índice elegido

La consulta principal filtra por profesional y rango de inicio:

```sql
CREATE INDEX idx_bookings_professional_start
    ON bookings (professional_id, start_time DESC);
```

El índice compuesto se justifica porque permite localizar primero las reservas de un profesional y después recorrer únicamente el intervalo de fechas solicitado. El índice parcial `unique_booking_per_professional_time` se mantiene para la integridad contra dobles reservas confirmadas; no reemplaza al índice operativo porque su propósito principal es imponer unicidad.

Para una entrada de índice se asume:

- `professional_id`: 16 bytes.
- `start_time`: 8 bytes.
- Puntero a la tupla: 8 bytes.

```text
L_I = 16 + 8 + 8 = 32 bytes
F_I = ⌊B / L_I⌋ = ⌊8.192 / 32⌋ = 256 entradas por página
```

Con 5.000 reservas:

```text
Páginas hoja = ⌈5.000 / 256⌉ = 20 páginas
```

Usando la aproximación de la fórmula de orden del árbol:

```text
2d − 1 ≈ F_I
2d − 1 ≈ 256
d ≈ 128
```

Como existen 100 valores distintos de `professional_id`, la altura logarítmica estimada es:

```text
H ≤ log_d V(a,R)
H ≤ log_128(100) ≈ 0,95
```

En términos físicos se considera un nivel raíz y un nivel hoja, es decir, una navegación corta de aproximadamente dos páginas de índice en el peor caso, sin contar las páginas de datos.

El espacio aproximado del índice es:

```text
(20 páginas hoja + 1 página raíz) × 8.192 bytes
= 172.032 bytes ≈ 168 KiB
```

La estrategia recomendada es conservar el índice compuesto para disponibilidad y consultas por rango, junto con los índices de integridad ya definidos en `schema.sql`.

## 2. Análisis del costo de una consulta

### 2.1 Consulta seleccionada

La siguiente consulta reúne `bookings` con `app_user` y `servicios` para mostrar las reservas de un profesional:

```sql
SELECT b.id,
       u.full_name AS cliente,
       s.nombre AS servicio,
       b.start_time,
       b.end_time,
       b.status
FROM bookings b
JOIN app_user u ON u.id = b.customer_id
JOIN servicios s ON s.id = b.service_id
WHERE b.professional_id = '00000000-0000-0000-0000-000000000000'
  AND b.start_time >= CURRENT_TIMESTAMP::timestamp
  AND b.start_time < (CURRENT_TIMESTAMP + INTERVAL '30 days')::timestamp;
```

Para aislar el costo de la reunión principal se analiza `bookings ⋈ app_user`; la reunión con `servicios` agrega una búsqueda por clave primaria por cada reserva resultante.

### 2.2 Estadísticas y cardinalidad estimada

Se usan estas estadísticas:

```text
B_bookings = 105 páginas
T_bookings = 5.000 tuplas
B_app_user = 30 páginas
T_app_user = 1.000 tuplas
V(bookings.professional_id) = 100
Fracción temporal = 30 / 365 = 0,0822
```

La selección por profesional produce aproximadamente:

```text
5.000 / 100 = 50 reservas
```

Al aplicar además el rango de 30 días:

```text
50 × (30 / 365) = 4,11 ≈ 5 reservas
```

Se redondea a cinco tuplas de salida para los cálculos siguientes. Como `customer_id` es una FK a la clave primaria de `app_user`, cada reserva encuentra como máximo una cuenta.

### 2.3 Alternativa A: nested-loop join sin índice de selección

Para comparar una reunión por bloques se aplica la fórmula:

```text
Costo = B_R + B_S · ⌈B_R / (M − 2)⌉
```

Tomando `R = bookings`, `S = app_user` y `M = 20`:

```text
Costo = 105 + 30 · ⌈105 / (20 − 2)⌉
Costo = 105 + 30 · ⌈105 / 18⌉
Costo = 105 + 30 · 6
Costo = 285 páginas de E/S
```

Esta alternativa lee muchos bloques de `bookings` antes de aplicar completamente el filtro.

### 2.4 Alternativa B: indexed nested-loop join

El índice `idx_bookings_professional_start` permite leer aproximadamente las 20 páginas hoja del índice para encontrar las reservas del profesional y del rango. Después, cada una de las cinco reservas resultantes busca su cliente mediante la PK de `app_user`.

Usando la fórmula de reunión indexada:

```text
Costo = B_T + T_T · S(b,R)
```

Con `B_T = 20`, `T_T = 5` y `S(customer_id, app_user) = 1` página por búsqueda:

```text
Costo = 20 + 5 · 1
Costo = 25 páginas de E/S
```

La búsqueda del servicio agrega hasta cinco accesos por clave primaria. Por ello, el costo ampliado de la consulta completa se estima en:

```text
25 + 5 = 30 páginas de E/S
```

### 2.5 Comparación

| Estrategia | Costo estimado | Observación |
|---|---:|---|
| Nested-loop por bloques | 285 páginas | Lee repetidamente bloques de `app_user`. |
| Indexed nested-loop | 30 páginas | Usa el índice de rango y búsquedas por PK. |

Con estos supuestos, la alternativa indexada reduce el costo estimado de 285 a 30 páginas, aproximadamente un 89,5 %. La elección real debe comprobarse con `EXPLAIN (ANALYZE, BUFFERS)` después de cargar datos representativos.

## 3. Optimización algebraica

### 3.1 Consulta original

```sql
SELECT u.full_name, b.start_time, b.end_time
FROM bookings b
JOIN app_user u ON u.id = b.customer_id
WHERE b.professional_id = '00000000-0000-0000-0000-000000000000'
  AND b.start_time >= CURRENT_TIMESTAMP::timestamp
  AND b.start_time < (CURRENT_TIMESTAMP + INTERVAL '30 days')::timestamp
  AND u.enabled = TRUE;
```

### 3.2 Expresión algebraica inicial

```text
π_{u.full_name, b.start_time, b.end_time}
  (σ_{b.professional_id = p
      ∧ b.start_time ≥ d1
      ∧ b.start_time < d2
      ∧ u.enabled = TRUE}
    (bookings b ⋈_{b.customer_id = u.id} app_user u))
```

En esta forma, la reunión puede considerar hasta 5.000 reservas y 1.000 cuentas antes de aplicar todas las selecciones.

### 3.3 Primera transformación: separar la selección conjunta

Aplicando la Ley 2, selección conjunta:

```text
σ_{p1 ∧ p2 ∧ p3 ∧ p4}(E)
≡ σ_{p1}(σ_{p2}(σ_{p3}(σ_{p4}(E))))
```

La expresión queda conceptualmente como una selección sobre la reunión, pero permite identificar qué predicados pertenecen a cada tabla:

```text
σ_{b.professional_id = p
  ∧ b.start_time ≥ d1
  ∧ b.start_time < d2
  ∧ u.enabled = TRUE}
  (bookings b ⋈ app_user u)
```

### 3.4 Segunda transformación: empujar selecciones hacia las hojas

Aplicando las Leyes 4 y 5, selección sobre una reunión:

```text
σ_p(E1 ⋈ E2) ≡ σ_{p1}(E1) ⋈ σ_{p2}(E2)
```

Se obtiene:

```text
σ_{b.professional_id = p
  ∧ b.start_time ≥ d1
  ∧ b.start_time < d2}(bookings b)
  ⋈_{b.customer_id = u.id}
σ_{u.enabled = TRUE}(app_user u)
```

El filtro de `bookings` reduce sus 5.000 tuplas a aproximadamente cinco. El filtro de `app_user` elimina cuentas deshabilitadas antes de la reunión.

### 3.5 Tercera transformación: proyección temprana

Aplicando la Ley 9, proyección sobre una reunión, se conservan únicamente los atributos necesarios y las columnas de reunión:

```text
π_{u.full_name, b.start_time, b.end_time}
(
  π_{b.customer_id, b.start_time, b.end_time}
    (σ_{b.professional_id = p
        ∧ b.start_time ≥ d1
        ∧ b.start_time < d2}(bookings b))
  ⋈_{b.customer_id = u.id}
  π_{u.id, u.full_name}
    (σ_{u.enabled = TRUE}(app_user u))
)
```

La proyección reduce el ancho de las tuplas intermedias y permite que el índice de `bookings(professional_id, start_time)` participe en la selección.

### 3.6 Expresión optimizada y comparación

```text
π_{u.full_name, b.start_time, b.end_time}
(
  π_{b.customer_id, b.start_time, b.end_time}
    (σ_{b.professional_id = p ∧ d1 ≤ b.start_time < d2}(bookings b))
  ⋈_{b.customer_id = u.id}
  π_{u.id, u.full_name}(σ_{u.enabled = TRUE}(app_user u))
)
```

| Etapa | Tuplas aproximadas |
|---|---:|
| `bookings` sin selección | 5.000 |
| Después de profesional y rango de fechas | 5 |
| `app_user` habilitados | 900 |
| Resultado de la reunión | Hasta 5 |

La expresión optimizada es más barata porque aplica las selecciones y proyecciones antes de la reunión, reduce las tuplas y columnas intermedias y permite utilizar el índice compuesto de `bookings`. La equivalencia conserva el resultado porque cada predicado empujado utiliza únicamente atributos de la relación correspondiente y la FK garantiza la correspondencia de las cuentas.

## Validación recomendada

Después de cargar datos representativos en PostgreSQL, se debe comprobar el plan real con:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.full_name, b.start_time, b.end_time
FROM bookings b
JOIN app_user u ON u.id = b.customer_id
WHERE b.professional_id = '00000000-0000-0000-0000-000000000000'
  AND b.start_time >= CURRENT_TIMESTAMP::timestamp
  AND b.start_time < (CURRENT_TIMESTAMP + INTERVAL '30 days')::timestamp
  AND u.enabled = TRUE;
```

El plan observado debe compararse con las estimaciones de este documento y las diferencias deben explicarse mediante la distribución real de los datos, estadísticas del optimizador y tamaño efectivo de las páginas.
