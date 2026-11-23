-- #216: la lectura del historial de otro cliente (ruta /reservas/cliente/{id}) queda en la auditoria.
-- Va despues de V67 porque V67 rehace la misma restriccion; con un numero menor la perderia.
ALTER TABLE audit_log DROP CONSTRAINT ck_audit_log_action_type;
ALTER TABLE audit_log ADD CONSTRAINT ck_audit_log_action_type CHECK (
    action_type IN ('BOOKING_CREATED', 'BOOKING_CANCELLED', 'ROLE_CHANGED', 'REPORT_VIEWED', 'CUSTOMER_HISTORY_VIEWED')
);
