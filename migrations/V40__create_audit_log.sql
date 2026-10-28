-- HU-19: bitacora inmutable de acciones criticas.
-- La base conserva la autoridad final sobre la integridad y la inmutabilidad: la aplicacion
-- solo insertara y consultara registros, mientras PostgreSQL rechazara UPDATE, DELETE y TRUNCATE.
-- No se usa ON DELETE CASCADE sobre app_user para conservar la trazabilidad del actor.
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
    CONSTRAINT fk_audit_log_actor FOREIGN KEY (actor_user_id)
        REFERENCES app_user (id)
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
