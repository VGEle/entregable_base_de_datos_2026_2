-- Validación reproducible del Sprint 3 - Caso 14.
-- PostgreSQL / Supabase. Ejecutar cada bloque de forma independiente.
-- Este archivo consulta datos de ejemplo; no reemplaza schema.sql.

-- 1. Objetos principales creados por schema.sql.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'bookings', 'bloqueo_agenda', 'recursos_fisicos',
      'servicio_recurso', 'audit_log'
  )
ORDER BY table_name;

-- 2. Función de historial de HU-13.
SELECT *
FROM get_customer_booking_history(
    '11111111-1111-1111-1111-111111111111'::uuid,
    TIMESTAMP '2026-12-01 00:00:00',
    TIMESTAMP '2026-12-31 00:00:00'
);

-- 3. Bloqueos de agenda de HU-05.
SELECT id, profesional_id, inicio, fin, motivo
FROM bloqueo_agenda
WHERE profesional_id = '44444444-4444-4444-4444-444444444444'::uuid
ORDER BY inicio;

-- 4. Reservas que ocupan agenda en un período.
SELECT id, professional_id, service_id, start_time, end_time,
       status, price_at_booking
FROM bookings
WHERE status IN ('CONFIRMADA', 'RESCHEDULED', 'COMPLETED')
  AND start_time < TIMESTAMP '2026-12-31 00:00:00'
  AND end_time > TIMESTAMP '2026-12-01 00:00:00'
ORDER BY start_time;

-- 5. Recursos requeridos por las reservas del período.
SELECT b.id AS booking_id, r.nombre AS recurso, r.cantidad_total,
       b.start_time, b.end_time
FROM bookings b
JOIN servicio_recurso sr ON sr.servicio_id = b.service_id
JOIN recursos_fisicos r ON r.id = sr.recurso_id
WHERE b.status IN ('CONFIRMADA', 'RESCHEDULED', 'COMPLETED')
  AND b.start_time < TIMESTAMP '2026-12-31 00:00:00'
  AND b.end_time > TIMESTAMP '2026-12-01 00:00:00'
ORDER BY b.start_time, r.nombre;

-- 6. Ingresos por servicio usando el precio histórico.
SELECT service_id,
       COUNT(*) AS total_reservas,
       SUM(price_at_booking) AS ingresos
FROM bookings
WHERE status IN ('CONFIRMADA', 'COMPLETED')
  AND price_at_booking IS NOT NULL
GROUP BY service_id
ORDER BY ingresos DESC;

-- 7. Validación de índices con el plan de ejecución.
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.id, b.professional_id, b.service_id, b.start_time,
       b.end_time, b.status, b.price_at_booking
FROM bookings b
WHERE b.customer_id = '11111111-1111-1111-1111-111111111111'::uuid
  AND b.start_time >= TIMESTAMP '2026-12-01 00:00:00'
  AND b.start_time < TIMESTAMP '2026-12-31 00:00:00'
ORDER BY b.start_time DESC, b.id DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT service_id, SUM(price_at_booking) AS ingresos
FROM bookings
WHERE status IN ('CONFIRMADA', 'COMPLETED')
  AND price_at_booking IS NOT NULL
  AND start_time >= TIMESTAMP '2026-12-01 00:00:00'
  AND start_time < TIMESTAMP '2027-01-01 00:00:00'
GROUP BY service_id;

-- 8. Pruebas negativas de audit_log.
-- Cada sentencia debe ejecutarse por separado y debe fallar con el mensaje
-- "audit_log is append-only; UPDATE, DELETE and TRUNCATE are not allowed".
UPDATE audit_log
SET metadata = '{"prueba": "bloqueada"}'::jsonb
WHERE id = '22222222-2222-2222-2222-222222222222'::uuid;

DELETE FROM audit_log
WHERE id = '22222222-2222-2222-2222-222222222222'::uuid;

TRUNCATE TABLE audit_log;

-- 9. Consulta del estado de RLS para documentar la decisión de seguridad.
SELECT schemaname, tablename, rowsecurity AS rls_activo
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
