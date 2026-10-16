-- Modelo físico consolidado del Sprint 2 - Caso 14.
-- PostgreSQL / Supabase. Ejecutar sobre una base de datos vacía.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- HU-01 y HU-03: cuentas, roles, bloqueo de acceso y MFA.
CREATE TABLE app_user (
    id UUID NOT NULL,
    email VARCHAR(320) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    role VARCHAR(30) NOT NULL,
    enabled BOOLEAN NOT NULL,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    mfa_secret_encrypted VARCHAR(512),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_app_user PRIMARY KEY (id),
    CONSTRAINT uk_app_user_email UNIQUE (email),
    CONSTRAINT uk_app_user_id_role UNIQUE (id, role),
    CONSTRAINT ck_app_user_role CHECK (role IN ('CUSTOMER', 'PROFESSIONAL', 'ADMIN')),
    CONSTRAINT ck_app_user_failed_login_attempts CHECK (failed_login_attempts >= 0)
);

-- HU-20: configuración inicial de la plataforma. Solo puede existir una fila.
CREATE TABLE platform (
    id UUID NOT NULL,
    name VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_platform PRIMARY KEY (id),
    CONSTRAINT ck_platform_status CHECK (status IN ('ACTIVE', 'SUSPENDED'))
);

CREATE UNIQUE INDEX uk_platform_singleton ON platform ((true));

-- HU-02 y HU-06: catálogo de servicios y duración estándar.
CREATE TABLE servicios (
    id UUID NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(500),
    categoria VARCHAR(100) NOT NULL,
    duracion_minutos INTEGER NOT NULL,
    precio NUMERIC(12, 2) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_servicios PRIMARY KEY (id),
    CONSTRAINT ck_servicios_estado CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    CONSTRAINT ck_servicios_duracion CHECK (duracion_minutos > 0 AND duracion_minutos <= 480),
    CONSTRAINT ck_servicios_precio CHECK (precio > 0)
);

CREATE UNIQUE INDEX uk_servicios_nombre ON servicios (lower(nombre));

-- HU-22: perfil profesional 1 a 1 con la cuenta.
CREATE TABLE profesionales (
    id UUID NOT NULL,
    rol VARCHAR(30) NOT NULL DEFAULT 'PROFESSIONAL',
    especialidad VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_profesionales PRIMARY KEY (id),
    CONSTRAINT ck_profesionales_rol CHECK (rol = 'PROFESSIONAL'),
    CONSTRAINT ck_profesionales_especialidad CHECK (length(btrim(especialidad)) > 0),
    CONSTRAINT fk_profesionales_app_user_rol
        FOREIGN KEY (id, rol) REFERENCES app_user (id, role)
);

-- HU-04: franjas de atención semanales.
CREATE TABLE horario_semanal (
    id UUID NOT NULL,
    profesional_id UUID NOT NULL,
    dia_semana VARCHAR(10) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_horario_semanal PRIMARY KEY (id),
    CONSTRAINT fk_horario_semanal_profesional
        FOREIGN KEY (profesional_id) REFERENCES profesionales (id),
    CONSTRAINT ck_horario_semanal_dia CHECK (dia_semana IN
        ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')),
    CONSTRAINT ck_horario_semanal_franja CHECK (hora_fin > hora_inicio),
    CONSTRAINT uk_horario_semanal_inicio
        UNIQUE (profesional_id, dia_semana, hora_inicio)
);

CREATE INDEX ix_horario_semanal_profesional
    ON horario_semanal (profesional_id);

-- HU-07 y HU-08: servicios que puede prestar cada profesional.
CREATE TABLE profesional_servicio (
    id UUID NOT NULL,
    profesional_id UUID NOT NULL,
    servicio_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_profesional_servicio PRIMARY KEY (id),
    CONSTRAINT uk_profesional_servicio UNIQUE (profesional_id, servicio_id),
    CONSTRAINT fk_profesional_servicio_profesional
        FOREIGN KEY (profesional_id) REFERENCES profesionales (id),
    CONSTRAINT fk_profesional_servicio_servicio
        FOREIGN KEY (servicio_id) REFERENCES servicios (id)
);

CREATE INDEX ix_profesional_servicio_servicio
    ON profesional_servicio (servicio_id);

-- HU-08 y HU-09: reservas y protección contra dobles reservas.
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    professional_id UUID NOT NULL,
    service_id UUID NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'CONFIRMADA',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    CONSTRAINT fk_bookings_customer
        FOREIGN KEY (customer_id) REFERENCES app_user (id),
    CONSTRAINT fk_bookings_professional
        FOREIGN KEY (professional_id) REFERENCES profesionales (id),
    CONSTRAINT fk_bookings_service
        FOREIGN KEY (service_id) REFERENCES servicios (id),
    CONSTRAINT ck_bookings_status CHECK
        (status IN ('CONFIRMADA', 'CANCELADA', 'RESCHEDULED', 'COMPLETED')),
    CONSTRAINT ck_bookings_time_validity CHECK (start_time < end_time)
);

CREATE INDEX idx_bookings_customer ON bookings (customer_id);
CREATE INDEX idx_bookings_professional ON bookings (professional_id);
CREATE INDEX idx_bookings_professional_start
    ON bookings (professional_id, start_time DESC);
CREATE INDEX idx_bookings_status ON bookings (status);
CREATE INDEX idx_bookings_start_time ON bookings (start_time);

-- Solo las reservas confirmadas bloquean una franja.
CREATE UNIQUE INDEX unique_booking_per_professional_time
    ON bookings (professional_id, start_time, end_time)
    WHERE status = 'CONFIRMADA';

-- HU-19: bitácora inmutable de acciones críticas.
CREATE TABLE audit_log (
    id UUID NOT NULL,
    actor_user_id UUID NOT NULL,
    action_type VARCHAR(40) NOT NULL,
    resource_type VARCHAR(30) NOT NULL,
    resource_id UUID,
    occurred_at TIMESTAMPTZ NOT NULL,
    source_ip VARCHAR(45),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT pk_audit_log PRIMARY KEY (id),
    CONSTRAINT ck_audit_log_action_type CHECK (
        action_type IN ('BOOKING_CREATED', 'BOOKING_CANCELLED', 'ROLE_CHANGED')
    ),
    CONSTRAINT ck_audit_log_resource_type CHECK (
        resource_type IN ('BOOKING', 'USER')
    ),
    CONSTRAINT fk_audit_log_actor
        FOREIGN KEY (actor_user_id) REFERENCES app_user (id)
);

CREATE INDEX ix_audit_log_occurred_at_id
    ON audit_log (occurred_at DESC, id DESC);
CREATE INDEX ix_audit_log_actor_occurred_at
    ON audit_log (actor_user_id, occurred_at DESC);

CREATE FUNCTION prevent_audit_log_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION USING
        ERRCODE = '42501',
        MESSAGE = 'audit_log is append-only; UPDATE, DELETE and TRUNCATE are not allowed';
END;
$$;

CREATE TRIGGER trg_audit_log_immutable
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW
EXECUTE FUNCTION prevent_audit_log_mutation();

CREATE TRIGGER trg_audit_log_no_truncate
BEFORE TRUNCATE ON audit_log
FOR EACH STATEMENT
EXECUTE FUNCTION prevent_audit_log_mutation();

-- HU-18: códigos de recuperación y dispositivos confiables para MFA.
CREATE TABLE mfa_recovery_code (
    id UUID NOT NULL,
    user_id UUID NOT NULL,
    code_hash VARCHAR(255) NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_mfa_recovery_code PRIMARY KEY (id),
    CONSTRAINT fk_mfa_recovery_code_app_user
        FOREIGN KEY (user_id) REFERENCES app_user (id)
);

CREATE INDEX idx_mfa_recovery_code_user ON mfa_recovery_code (user_id);

CREATE TABLE mfa_trusted_device (
    id UUID NOT NULL,
    user_id UUID NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_mfa_trusted_device PRIMARY KEY (id),
    CONSTRAINT fk_mfa_trusted_device_app_user
        FOREIGN KEY (user_id) REFERENCES app_user (id)
);

CREATE INDEX idx_mfa_trusted_device_user ON mfa_trusted_device (user_id);

-- HU-10: entregas idempotentes de notificaciones asociadas a reservas.
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
        FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE,
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
