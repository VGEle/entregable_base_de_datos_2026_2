-- HU-16: las consultas del reporte general quedan registradas como acciones de auditoría.
ALTER TABLE audit_log DROP CONSTRAINT ck_audit_log_action_type;
ALTER TABLE audit_log ADD CONSTRAINT ck_audit_log_action_type CHECK (
    action_type IN ('BOOKING_CREATED', 'BOOKING_CANCELLED', 'ROLE_CHANGED', 'REPORT_VIEWED')
);

ALTER TABLE audit_log DROP CONSTRAINT ck_audit_log_resource_type;
ALTER TABLE audit_log ADD CONSTRAINT ck_audit_log_resource_type CHECK (
    resource_type IN ('BOOKING', 'USER', 'REPORT')
);
