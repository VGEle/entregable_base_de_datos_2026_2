-- Contador de intentos fallidos y bloqueo temporal de cuenta (HU-03).
-- Reemplaza al script docker/postgres/init/002-add-login-security.sql, que solo se ejecutaba
-- al crear el volumen por primera vez. Es idempotente para bases que ya lo hayan aplicado asi.
ALTER TABLE app_user
    ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ;

ALTER TABLE app_user DROP CONSTRAINT IF EXISTS ck_app_user_role;
ALTER TABLE app_user
    ADD CONSTRAINT ck_app_user_role
    CHECK (role IN ('PATIENT', 'PROFESSIONAL', 'ADMIN'));
