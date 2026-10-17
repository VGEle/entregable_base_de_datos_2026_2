-- HU-10: los registros técnicos de entrega no deben impedir la limpieza de
-- una reserva eliminada por fixtures o tareas administrativas.
-- La eliminación de la reserva arrastra únicamente su historial de entrega;
-- no cambia el estado de negocio ni elimina otras entidades.
ALTER TABLE notification_delivery
    DROP CONSTRAINT fk_notification_delivery_booking;

ALTER TABLE notification_delivery
    ADD CONSTRAINT fk_notification_delivery_booking
        FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE;
