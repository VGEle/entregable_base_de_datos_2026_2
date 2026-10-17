-- Vincula que profesionales ofrecen cada servicio del catalogo. Hasta ahora no existia ninguna
-- relacion formal entre `servicios` y `profesionales` (categoria y especialidad son texto libre,
-- sin garantia de que coincidan), asi que el front no tenia forma de saber a que profesional
-- pedirle disponibilidad (HU-07) o reservarle un turno (HU-08) para un servicio dado.
CREATE TABLE profesional_servicio (
    id UUID NOT NULL,
    profesional_id UUID NOT NULL,
    servicio_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_profesional_servicio PRIMARY KEY (id),
    CONSTRAINT uk_profesional_servicio UNIQUE (profesional_id, servicio_id),
    CONSTRAINT fk_profesional_servicio_profesional FOREIGN KEY (profesional_id) REFERENCES profesionales (id),
    CONSTRAINT fk_profesional_servicio_servicio FOREIGN KEY (servicio_id) REFERENCES servicios (id)
);

CREATE INDEX ix_profesional_servicio_servicio ON profesional_servicio (servicio_id);
