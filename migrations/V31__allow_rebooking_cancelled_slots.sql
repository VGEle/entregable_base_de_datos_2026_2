
--HU-09: Cancelacion autonoma de reservas
-- Permitir reutilizar una franja luego de cancelar su reserva
-- Mantener la proteccion contra reservas confirmadas duplicadas
-- ADR-006: la restriccion debe aplicarse en PostgreSQL

ALTER TABLE bookings
DROP CONSTRAINT unique_booking_per_professional_time;

CREATE UNIQUE INDEX unique_booking_per_professional_time
 ON bookings (professional_id, start_time, end_time)
WHERE status = 'CONFIRMADA';
