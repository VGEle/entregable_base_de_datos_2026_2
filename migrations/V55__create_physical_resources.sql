
-- HU-11: Registro de recursos físicos limitados.
-- El inventario total debe ser un entero mayor que cero.

CREATE TABLE recursos_fisicos (
    id UUID NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    cantidad_total INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT pk_recursos_fisicos PRIMARY KEY (id),
    CONSTRAINT ck_recursos_fisicos_cantidad
        CHECK (cantidad_total > 0)
);

CREATE UNIQUE INDEX uk_recursos_fisicos_nombre
    ON recursos_fisicos (lower(nombre));
