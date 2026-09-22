-- HU-22: registro de profesionales.
-- Un profesional es una cuenta de app_user con rol PROFESSIONAL mas un perfil con su especialidad.
-- El perfil comparte la clave primaria con la cuenta: el id del profesional es el
-- mismo UUID que el token JWT lleva en "sub", que es el valor que OwnershipGuard compara al
-- proteger los recursos propios (por ejemplo, la agenda).
--
-- La base garantiza que solo una cuenta con rol PROFESSIONAL puede tener perfil: la columna rol de
-- profesionales siempre vale PROFESSIONAL (DEFAULT + CHECK) y la FK compuesta (id, rol) apunta a
-- app_user (id, role). Por eso el codigo de la aplicacion no necesita mapear ni enviar esa columna.
ALTER TABLE app_user
    ADD CONSTRAINT uk_app_user_id_role UNIQUE (id, role);

CREATE TABLE profesionales (
    id UUID NOT NULL,
    rol VARCHAR(30) NOT NULL DEFAULT 'PROFESSIONAL',
    especialidad VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_profesionales PRIMARY KEY (id),
    CONSTRAINT ck_profesionales_rol CHECK (rol = 'PROFESSIONAL'),
    CONSTRAINT ck_profesionales_especialidad CHECK (length(btrim(especialidad)) > 0),
    -- Sin ON DELETE CASCADE: una cuenta con perfil no se elimina, se deshabilita (enabled = FALSE).
    -- Tampoco se puede cambiar el rol de una cuenta que ya tiene perfil.
    CONSTRAINT fk_profesionales_app_user_rol FOREIGN KEY (id, rol) REFERENCES app_user (id, role)
);