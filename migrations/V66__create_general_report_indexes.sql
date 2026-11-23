-- HU-16: índices para los filtros temporales, de estado y de relaciones de recursos.
CREATE INDEX idx_bookings_report_period_status
    ON bookings (start_time, status);

CREATE INDEX idx_bookings_service_period_status
    ON bookings (service_id, start_time, status);

CREATE INDEX idx_servicio_recurso_servicio
    ON servicio_recurso (servicio_id);
