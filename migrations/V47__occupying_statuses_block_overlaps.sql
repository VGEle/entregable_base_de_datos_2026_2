-- #220: una reserva reprogramada o completada tambien ocupa la franja (BookingStatus.OCCUPYING).
-- La restriccion de V46 solo miraba CONFIRMADA; se recrea con el mismo nombre (lo usa el servicio
-- de reservas para traducir el rechazo a SLOT_OCUPADO) y con los tres estados que ocupan agenda.
ALTER TABLE bookings DROP CONSTRAINT booking_no_overlapping_confirmed;

ALTER TABLE bookings
    ADD CONSTRAINT booking_no_overlapping_confirmed
    EXCLUDE USING gist (
        professional_id WITH =,
        tsrange(start_time, end_time, '[)') WITH &&
    )
    WHERE (status IN ('CONFIRMADA', 'RESCHEDULED', 'COMPLETED'));
