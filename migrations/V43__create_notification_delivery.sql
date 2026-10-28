-- HU-10: registro técnico de correos de reserva.
-- ADR-011: la entrega se procesa mediante eventos y debe ser idempotente.
-- La tabla no modifica el estado de negocio de bookings ni usa ON DELETE CASCADE.
CREATE TABLE notification_delivery (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL,
    booking_id UUID NOT NULL,
    event_type VARCHAR(40) NOT NULL,
    recipient_email VARCHAR(320) NOT NULL,
    subject VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMPTZ,
    last_attempt_at TIMESTAMPTZ,
    error_message TEXT,

    CONSTRAINT pk_notification_delivery PRIMARY KEY (id),
    CONSTRAINT uk_notification_delivery_event UNIQUE (event_id),
    CONSTRAINT fk_notification_delivery_booking
        FOREIGN KEY (booking_id) REFERENCES bookings (id),
    CONSTRAINT ck_notification_delivery_event_type CHECK (
        event_type IN ('BOOKING_CREATED', 'BOOKING_RESCHEDULED', 'BOOKING_CANCELLED')
    ),
    CONSTRAINT ck_notification_delivery_status CHECK (
        status IN ('PENDING', 'SENT', 'FAILED')
    ),
    CONSTRAINT ck_notification_delivery_attempts CHECK (attempts >= 0),
    CONSTRAINT ck_notification_delivery_sent_at CHECK (
        (status = 'SENT' AND sent_at IS NOT NULL)
        OR (status <> 'SENT' AND sent_at IS NULL)
    ),
    CONSTRAINT ck_notification_delivery_failed_error CHECK (
        status <> 'FAILED' OR error_message IS NOT NULL
    )
);

CREATE INDEX ix_notification_delivery_status_attempt
    ON notification_delivery (status, last_attempt_at);

CREATE INDEX ix_notification_delivery_booking_created
    ON notification_delivery (booking_id, created_at DESC);

CREATE INDEX ix_notification_delivery_type_created
    ON notification_delivery (event_type, created_at DESC);
