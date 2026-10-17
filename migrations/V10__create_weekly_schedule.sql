-- HU-04: horario de atencion semanal del profesional.
-- Cada fila es una franja de un dia de la semana. Un profesional reemplaza su horario completo
-- en una sola operacion, por eso no hay identificador de franja expuesto en la API.
-- La base impide franjas con hora fin anterior o igual a la de inicio y dos franjas que empiecen
-- a la misma hora el mismo dia. El solapamiento parcial se valida en el servicio, que devuelve el
-- detalle del conflicto.
CREATE TABLE horario_semanal (
    id UUID NOT NULL,
    profesional_id UUID NOT NULL,
    dia_semana VARCHAR(10) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_horario_semanal PRIMARY KEY (id),
    CONSTRAINT fk_horario_semanal_profesional FOREIGN KEY (profesional_id) REFERENCES profesionales (id),
    CONSTRAINT ck_horario_semanal_dia CHECK (dia_semana IN
        ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')),
    CONSTRAINT ck_horario_semanal_franja CHECK (hora_fin > hora_inicio),
    CONSTRAINT uk_horario_semanal_inicio UNIQUE (profesional_id, dia_semana, hora_inicio)
);

CREATE INDEX ix_horario_semanal_profesional ON horario_semanal (profesional_id);
