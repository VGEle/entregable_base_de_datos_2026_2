-- HU-02: catalogo de servicios.
-- La estructura se gestiona con Flyway para que una base nueva y una existente
-- reciban el mismo esquema sin depender de scripts de inicializacion de Docker.
CREATE TABLE IF NOT EXISTS servicios (
    id UUID NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(500),
    categoria VARCHAR(100) NOT NULL,
    duracion_minutos INTEGER NOT NULL,
    precio NUMERIC(12, 2) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_servicios PRIMARY KEY (id),
    CONSTRAINT ck_servicios_estado CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    CONSTRAINT ck_servicios_duracion CHECK (duracion_minutos > 0 AND duracion_minutos <= 480),
    CONSTRAINT ck_servicios_precio CHECK (precio > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_servicios_nombre ON servicios (lower(nombre));
