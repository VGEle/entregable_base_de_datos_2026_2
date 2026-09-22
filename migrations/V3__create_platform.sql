CREATE TABLE platform (
    id UUID NOT NULL,
    name VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_platform PRIMARY KEY (id),
    CONSTRAINT ck_platform_status CHECK (status IN ('ACTIVE', 'SUSPENDED'))
);

-- La plataforma es unica. El indice sobre una expresion constante permite exactamente una fila,
-- de modo que la invariante la sostiene la base y no solo la aplicacion: dos peticiones
-- simultaneas no pueden colarse ambas.
CREATE UNIQUE INDEX uk_platform_singleton ON platform ((true));
