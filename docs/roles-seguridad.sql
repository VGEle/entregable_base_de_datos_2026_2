-- Roles y privilegios del esquema Bookly.
-- Ejecutar una sola vez con un usuario administrador de PostgreSQL.
-- Se mantiene separado de schema.sql porque CREATE ROLE requiere privilegios
-- administrativos y depende de la configuración del servidor.

CREATE ROLE bookly_admin NOLOGIN;
CREATE ROLE bookly_app NOLOGIN;
CREATE ROLE bookly_readonly NOLOGIN;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

GRANT USAGE ON SCHEMA public
TO bookly_admin, bookly_app, bookly_readonly;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bookly_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO bookly_admin;

GRANT SELECT, INSERT, UPDATE ON
    app_user,
    platform,
    profesionales,
    horario_semanal,
    profesional_servicio,
    bookings,
    mfa_recovery_code,
    mfa_trusted_device,
    notification_delivery
TO bookly_app;

GRANT SELECT ON servicios TO bookly_app;
GRANT INSERT, SELECT ON audit_log TO bookly_app;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO bookly_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO bookly_readonly;

-- Las tablas nuevas requieren una concesión explícita a bookly_app para
-- conservar el principio de mínimo privilegio.

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
ON ALL TABLES IN SCHEMA public FROM bookly_readonly;

REVOKE UPDATE, DELETE, TRUNCATE ON audit_log FROM bookly_app;
REVOKE DELETE, TRUNCATE ON app_user, bookings, notification_delivery FROM bookly_app;
