-- HU-05: bloqueos temporales de agenda (vacaciones, imprevistos).
-- Un bloqueo es un rango [inicio, fin) en el que el profesional no atiende: la disponibilidad deja de
-- ofrecerlo y no se aceptan reservas que lo toquen. La base impide rangos invertidos y bloqueos
-- solapados del mismo profesional, con la misma tecnica que V46. El choque con reservas confirmadas
-- se valida en el servicio, que devuelve el detalle de las citas afectadas.
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE bloqueo_agenda (
    id UUID NOT NULL,
    profesional_id UUID NOT NULL,
    inicio TIMESTAMP NOT NULL,
    fin TIMESTAMP NOT NULL,
    motivo VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_bloqueo_agenda PRIMARY KEY (id),
    CONSTRAINT fk_bloqueo_agenda_profesional FOREIGN KEY (profesional_id) REFERENCES profesionales (id),
    CONSTRAINT ck_bloqueo_agenda_rango CHECK (fin > inicio),
    CONSTRAINT bloqueo_agenda_sin_solapamiento EXCLUDE USING gist (
        profesional_id WITH =,
        tsrange(inicio, fin, '[)') WITH &&
    )
);

CREATE INDEX ix_bloqueo_agenda_profesional_inicio ON bloqueo_agenda (profesional_id, inicio);
