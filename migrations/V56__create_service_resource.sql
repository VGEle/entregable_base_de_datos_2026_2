
-- HU-11: Asociación entre servicios y recursos físicos.
-- Un servicio puede requerir varios recursos.
-- Un recurso puede utilizarse en diferentes servicios.

CREATE TABLE servicio_recurso (
    servicio_id UUID NOT NULL,
    recurso_id UUID NOT NULL,

    CONSTRAINT pk_servicio_recurso
        PRIMARY KEY (servicio_id, recurso_id),

    CONSTRAINT fk_servicio_recurso_servicio
        FOREIGN KEY (servicio_id)
        REFERENCES servicios(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_servicio_recurso_recurso
        FOREIGN KEY (recurso_id)
        REFERENCES recursos_fisicos(id)
        ON DELETE RESTRICT
);

-- Facilita consultar qué servicios utilizan un recurso.
CREATE INDEX idx_servicio_recurso_recurso
    ON servicio_recurso (recurso_id);
