--HU08
--Constraint UNIQUE(professional_id, start_time, end_time) para evitar dobles reservas
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    professional_id UUID NOT NULL,
    service_id UUID NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'CONFIRMADA' CHECK (status IN ('CONFIRMADA', 'CANCELADA', 'RESCHEDULED', 'COMPLETED')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    CONSTRAINT fk_bookings_customer FOREIGN KEY (customer_id) REFERENCES app_user(id),
    CONSTRAINT fk_bookings_professional FOREIGN KEY (professional_id) REFERENCES profesionales(id),
    CONSTRAINT fk_bookings_service FOREIGN KEY (service_id) REFERENCES servicios(id),
    --Unique constraint: un profesional no puede tener dos reservas en el mismo horario
    CONSTRAINT unique_booking_per_professional_time UNIQUE(professional_id, start_time, end_time),
    --Check: la hora de inicio debe ser antes que la hora de fin
    CONSTRAINT booking_time_validity CHECK (start_time < end_time)
);

CREATE INDEX idx_bookings_customer ON bookings(customer_id);
CREATE INDEX idx_bookings_professional ON bookings(professional_id);
CREATE INDEX idx_bookings_professional_start ON bookings(professional_id, start_time DESC);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_start_time ON bookings(start_time);
