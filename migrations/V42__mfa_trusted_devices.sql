-- "Confiar en este dispositivo": permite saltar el segundo factor por 30 dias en el mismo
-- navegador. El token se guarda hasheado, igual que los codigos de recuperacion.
CREATE TABLE mfa_trusted_device (
    id UUID NOT NULL,
    user_id UUID NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_mfa_trusted_device PRIMARY KEY (id),
    CONSTRAINT fk_mfa_trusted_device_app_user FOREIGN KEY (user_id) REFERENCES app_user (id)
);

CREATE INDEX idx_mfa_trusted_device_user ON mfa_trusted_device (user_id);
