-- HU-08: la consulta previa de solapamientos no es suficiente ante solicitudes
-- concurrentes. PostgreSQL debe aplicar la regla de negocio de forma atomica.

CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE bookings
    ADD CONSTRAINT booking_no_overlapping_confirmed
    EXCLUDE USING gist (
        professional_id WITH =,
        tsrange(start_time, end_time, '[)') WITH &&
    )
    WHERE (status = 'CONFIRMADA');
