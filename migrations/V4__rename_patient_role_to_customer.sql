-- La HU-01 usa CUSTOMER para representar al cliente de una empresa generica.
-- Se conserva V1/V2 por inmutabilidad de Flyway y se migra tanto una base nueva
-- como una base existente que aun tenga cuentas con el rol historico PATIENT.
ALTER TABLE app_user DROP CONSTRAINT IF EXISTS ck_app_user_role;

UPDATE app_user
SET role = 'CUSTOMER'
WHERE role = 'PATIENT';

ALTER TABLE app_user
    ADD CONSTRAINT ck_app_user_role
    CHECK (role IN ('CUSTOMER', 'PROFESSIONAL', 'ADMIN'));
