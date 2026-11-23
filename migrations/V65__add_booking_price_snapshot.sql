-- HU-16: conserva el precio del servicio en el momento de crear la reserva.
ALTER TABLE bookings ADD COLUMN price_at_booking NUMERIC(12, 2);

UPDATE bookings b
SET price_at_booking = s.precio
FROM servicios s
WHERE s.id = b.service_id
  AND b.price_at_booking IS NULL;

ALTER TABLE bookings ADD CONSTRAINT ck_bookings_price_at_booking
    CHECK (price_at_booking IS NULL OR price_at_booking > 0);
