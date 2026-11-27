# Retroalimentación – Bases de Datos

Calificación por sprint según la rúbrica de cada entrega. Los scripts se ejecutaron en PostgreSQL 16 vacío. Lo que venía de un sprint anterior aparece como sugerencia y no descuenta.

## Sprint 1 — 4.5 / 5.0

| Criterio | Nivel | Puntos |
|---|---|---|
| C1 Entidades y relaciones | Aceptable | 0.90 / 1.25 |
| C2 Preguntas clave | Excelente | 0.75 / 0.75 |
| C3 Modelo lógico | Excelente | 1.00 / 1.00 |
| C4 Modelo físico | Excelente | 1.25 / 1.25 |
| C5 Repositorio y documentación | Aceptable | 0.55 / 0.75 |

- C1: `platform` y `servicios` quedan sin relaciones; falta la entidad reserva, que es el núcleo del caso.
- C4: mezcla `CREATE TABLE IF NOT EXISTS` con `CREATE TABLE` simple; el `ALTER TABLE` del UNIQUE no es idempotente.
- C5: los 5 commits desde una sola cuenta, 4 el mismo día.
- C5: las capturas de `evidence/` son un buen aporte.

## Sprint 2 — 4.7 / 5.0

| Criterio | Nivel | Puntos |
|---|---|---|
| C1 MER refinado | Excelente | 0.60 / 0.60 |
| C2 Modelo físico | Excelente | 0.80 / 0.80 |
| C3 schema.sql | Excelente | 0.80 / 0.80 |
| C4 Consultas | Excelente | 0.70 / 0.70 |
| C5 Volumen | Excelente | 0.50 / 0.50 |
| C6 Roles y seguridad | Aceptable | 0.45 / 0.60 |
| C7 Almacenamiento e índices | Aceptable | 0.30 / 0.40 |
| C8 Costo de una consulta | Aceptable | 0.22 / 0.30 |
| C9 Optimización algebraica | Excelente | 0.30 / 0.30 |

- C1: 11 relaciones = 11 FK; ya está la reserva con sus relaciones.
- C6: `bookly_readonly` lee `password_hash`, `mfa_secret_encrypted` y los hashes de MFA. La matriz del README no detalla privilegios por tabla.
- C7: la altura del índice no aplica la fórmula de nodos por nivel; las hojas se calculan con TR/FR del índice. No se discute la organización de archivo.
- C8: `B_app_user = 30` sin justificar; en el indexed nested-loop se usan las 20 hojas de todo el índice en lugar del costo de la búsqueda.
- Sugerencias: `bookings` usa `TIMESTAMP` sin zona; llevar las consultas a un `.sql` con datos de prueba.

## Sprint 3 — 4.4 / 5.0

| Criterio | Nivel | Puntos |
|---|---|---|
| C1 MER refinado | Excelente | 0.70 / 0.70 |
| C2 Script refinado | Excelente | 0.80 / 0.80 |
| C3 Triggers | Aceptable | 0.80 / 1.10 |
| C4 Procedimientos | Excelente | 1.10 / 1.10 |
| C5 Consultas | Aceptable | 0.45 / 0.60 |
| C6 Roles y seguridad | Aceptable | 0.50 / 0.70 |

- C1: 14 relaciones = 14 FK.
- C3: no hay triggers nuevos ni modificados; los dos de `audit_log` ya estaban en el Sprint 2. Las reglas de bloqueos, recursos y precio quedan en restricciones o en la aplicación.
- C4: `get_customer_booking_history` bien documentada y funciona. Es la única rutina del sprint.
- C5: 6 consultas nuevas usan `:desde`, `:hasta`, `:profesional_id` sin explicar cómo definirlas; fallan en psql y en el SQL Editor de Supabase. La 14 promete porcentaje y devuelve minutos.
- C6: `bookly_app` solo tiene SELECT en `bloqueo_agenda`, `recursos_fisicos` y `servicio_recurso` (no puede crear bloqueos ni recursos). EXECUTE de la función sigue abierto a PUBLIC. Sin RLS, en Supabase las tablas quedan expuestas al Data API.
- Sugerencias: restringir `bookly_readonly` por columnas; `bloqueo_agenda` repite `TIMESTAMP` sin zona.
- Repositorio: todos los commits del sprint desde una sola cuenta.
