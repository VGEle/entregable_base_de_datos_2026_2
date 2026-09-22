-- Modelo fisico consolidado del Sprint 1 - Caso 14.
-- PostgreSQL / Supabase. Ejecutar sobre una base de datos vacia.

-- HU-01: clientes y cuentas de usuario.
CREATE TABLE IF NOT EXISTS app_user (
    id UUID NOT NULL,
    email VARCHAR(320) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    role VARCHAR(30) NOT NULL,
    enabled BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    CONSTRAINT pk_app_user PRIMARY KEY (id),
    CONSTRAINT uk_app_user_email UNIQUE (email),
    CONSTRAINT ck_app_user_role CHECK (role IN ('CUSTOMER', 'PROFESSIONAL', 'ADMIN'))
);

-- HU-20: configuracion inicial de la plataforma.
CREATE TABLE platform (
    id UUID NOT NULL,
    name VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_platform PRIMARY KEY (id),
    CONSTRAINT ck_platform_status CHECK (status IN ('ACTIVE', 'SUSPENDED'))
);

CREATE UNIQUE INDEX uk_platform_singleton ON platform ((true));

-- HU-02 y HU-06: catalogo de servicios y duracion estandar.
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

CREATE UNIQUE INDEX uk_servicios_nombre ON servicios (lower(nombre));

-- HU-22: perfil de profesionales y especialidad.
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
    CONSTRAINT fk_profesionales_app_user_rol
        FOREIGN KEY (id, rol) REFERENCES app_user (id, role)
);
