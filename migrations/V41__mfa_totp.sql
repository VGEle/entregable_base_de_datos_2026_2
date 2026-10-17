-- HU-18: segundo factor TOTP para cuentas ADMIN (ADR-010).
-- El secreto se guarda cifrado con AES-GCM; los codigos de recuperacion, hasheados.
ALTER TABLE app_user
    ADD COLUMN mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN mfa_secret_encrypted VARCHAR(512);

CREATE TABLE mfa_recovery_code (
    id UUID NOT NULL,
    user_id UUID NOT NULL,
    code_hash VARCHAR(255) NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_mfa_recovery_code PRIMARY KEY (id),
    CONSTRAINT fk_mfa_recovery_code_app_user FOREIGN KEY (user_id) REFERENCES app_user (id)
);

CREATE INDEX idx_mfa_recovery_code_user ON mfa_recovery_code (user_id);
