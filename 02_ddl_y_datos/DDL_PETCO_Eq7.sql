CREATE DATABASE PETCO_DATAMART;
USE PETCO_DATAMART;

-- 1. CREACIÓN DE TABLAS DE DIMENSIONES
-- Dimensión de Tiempo: Contexto temporal para análisis por año, mes, día, etc.
CREATE TABLE DIM_TIEMPO (
    fecha_key INT NOT NULL,               -- Clave primaria numérica (ej. 20260904)
    fecha DATE NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,
    nombre_mes VARCHAR(20) NOT NULL,
    trimestre INT NOT NULL,
    dia_semana VARCHAR(15) NOT NULL,
    es_fin_semana BOOLEAN NOT NULL,
    CONSTRAINT PK_DIM_TIEMPO PRIMARY KEY (fecha_key)
);

-- Dimensión de Cliente: Registra compradores (soporta anónimos con clave centinela -1)
CREATE TABLE DIM_CLIENTE (
    cliente_key INT NOT NULL,             -- Clave primaria subrogada
    cliente_id VARCHAR(50) NOT NULL,      -- ID del sistema transaccional
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    membresia VARCHAR(30) NOT NULL,
    fecha_alta DATE NULL,
    CONSTRAINT PK_DIM_CLIENTE PRIMARY KEY (cliente_key)
);

-- Dimensión de Producto: Catálogo de artículos con atributos contextuales
CREATE TABLE DIM_PRODUCTO (
    producto_key INT NOT NULL,           -- Clave primaria subrogada
    producto_id VARCHAR(50) NOT NULL,     -- ID del sistema transaccional
    nombre VARCHAR(150) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    especie_objetivo VARCHAR(50) NOT NULL,
    presentacion VARCHAR(50) NOT NULL,
    CONSTRAINT PK_DIM_PRODUCTO PRIMARY KEY (producto_key)
);

-- Dimensión de Tienda: Puntos de venta y surtido
CREATE TABLE DIM_TIENDA (
    tienda_key INT NOT NULL,             -- Clave primaria subrogada
    tienda_id VARCHAR(50) NOT NULL,       -- ID del sistema transaccional
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL,
    CONSTRAINT PK_DIM_TIENDA PRIMARY KEY (tienda_key)
);

-- Dimensión de Canal: Canal de venta (Físico, E-commerce, Click & Collect)
CREATE TABLE DIM_CANAL (
    canal_key INT NOT NULL,              -- Clave primaria subrogada
    nombre_canal VARCHAR(50) NOT NULL,
    CONSTRAINT PK_DIM_CANAL PRIMARY KEY (canal_key)
);

-- Dimensión de Promoción: Descuentos comerciales (soporta "Sin Promoción" con clave -1)
CREATE TABLE DIM_PROMOCION (
    promocion_key INT NOT NULL,          -- Clave primaria subrogada
    promocion_id VARCHAR(50) NOT NULL,   -- ID del sistema transaccional
    nombre VARCHAR(100) NOT NULL,
    tipo_dependencia VARCHAR(50) NOT NULL,
    valor_descuento DECIMAL(12, 2) NOT NULL,
    CONSTRAINT PK_DIM_PROMOCION PRIMARY KEY (promocion_key)
);

-- Dimensión de Suscripción: Compras recurrentes (soporta "No Recurrente" con clave -1)
CREATE TABLE DIM_SUSCRIPCION (
    suscripcion_key INT NOT NULL,        -- Clave primaria subrogada
    suscripcion_id VARCHAR(50) NOT NULL, -- ID del sistema transaccional
    frecuencia VARCHAR(30) NOT NULL,
    estatus VARCHAR(20) NOT NULL,
    CONSTRAINT PK_DIM_SUSCRIPCION PRIMARY KEY (suscripcion_key)
);

-- 2. CREACIÓN DE LA TABLA DE HECHOS
-- Tabla de Hechos de Ventas: Registra cada renglón de un ticket o pedido
CREATE TABLE FACT_VENTAS (
    -- Clave Primaria y Dimensión Degenerada
    detalle_id BIGINT NOT NULL,           -- Clave primaria del renglón/ítem
    venta_id VARCHAR(50) NOT NULL,        -- Dimensión degenerada (Número de ticket/orden)

    -- Claves Foráneas (FKs)
    fecha_key INT NOT NULL,
    cliente_key INT NOT NULL,
    producto_key INT NOT NULL,
    tienda_surtido_key INT NOT NULL,
    tienda_entrega_key INT NULL,          -- Opcional (solo si aplica Click & Collect)
    canal_key INT NOT NULL,
    promocion_key INT NOT NULL,
    suscripcion_key INT NOT NULL,

    -- Métricas Aditivas
    cantidad INT NOT NULL,
    descuento DECIMAL(12, 2) NOT NULL,
    importe_bruto DECIMAL(12, 2) NOT NULL,
    importe_neto DECIMAL(12, 2) NOT NULL,
    margen DECIMAL(12, 2) NOT NULL,

    -- Métricas No Aditivas
    precio_unitario DECIMAL(12, 2) NOT NULL,
    costo_unitario DECIMAL(12, 2) NOT NULL,

    -- Restricción de Clave Primaria
    CONSTRAINT PK_FACT_VENTAS PRIMARY KEY (detalle_id),

    -- Integridad Referencial
    CONSTRAINT FK_VENTAS_TIEMPO 
        FOREIGN KEY (fecha_key) REFERENCES DIM_TIEMPO(fecha_key),
    CONSTRAINT FK_VENTAS_CLIENTE 
        FOREIGN KEY (cliente_key) REFERENCES DIM_CLIENTE(cliente_key),
    CONSTRAINT FK_VENTAS_PRODUCTO 
        FOREIGN KEY (producto_key) REFERENCES DIM_PRODUCTO(producto_key),
    CONSTRAINT FK_VENTAS_TIENDA_SURTIDO 
        FOREIGN KEY (tienda_surtido_key) REFERENCES DIM_TIENDA(tienda_key),
    CONSTRAINT FK_VENTAS_TIENDA_ENTREGA 
        FOREIGN KEY (tienda_entrega_key) REFERENCES DIM_TIENDA(tienda_key),
    CONSTRAINT FK_VENTAS_CANAL 
        FOREIGN KEY (canal_key) REFERENCES DIM_CANAL(canal_key),
    CONSTRAINT FK_VENTAS_PROMOCION 
        FOREIGN KEY (promocion_key) REFERENCES DIM_PROMOCION(promocion_key),
    CONSTRAINT FK_VENTAS_SUSCRIPCION 
        FOREIGN KEY (suscripcion_key) REFERENCES DIM_SUSCRIPCION(suscripcion_key)
);

-- 3. CREACIÓN DE ÍNDICES PARA RENDIMIENTO EN CONSULTAS
-- Índices en las Claves Foráneas de la Tabla de Hechos
CREATE INDEX IDX_FACT_VENTAS_FECHA ON FACT_VENTAS(fecha_key);
CREATE INDEX IDX_FACT_VENTAS_CLIENTE ON FACT_VENTAS(cliente_key);
CREATE INDEX IDX_FACT_VENTAS_PRODUCTO ON FACT_VENTAS(producto_key);
CREATE INDEX IDX_FACT_VENTAS_TIENDA_SURTIDO ON FACT_VENTAS(tienda_surtido_key);
CREATE INDEX IDX_FACT_VENTAS_TIENDA_ENTREGA ON FACT_VENTAS(tienda_entrega_key);
CREATE INDEX IDX_FACT_VENTAS_CANAL ON FACT_VENTAS(canal_key);
CREATE INDEX IDX_FACT_VENTAS_PROMOCION ON FACT_VENTAS(promocion_key);
CREATE INDEX IDX_FACT_VENTAS_SUSCRIPCION ON FACT_VENTAS(suscripcion_key);

-- Índice en la Dimensión Degenerada (Acelera búsquedas y agrupaciones por ticket completo)
CREATE INDEX IDX_FACT_VENTAS_VENTA_ID ON FACT_VENTAS(venta_id);

-- 4. INSERT DE REGISTROS CENTINELA (VALORES POR DEFECTO PARA EL ETL)
-- Evitan el uso de NULLs en las FKs y mantienen la integridad analítica
INSERT INTO DIM_CLIENTE (cliente_key, cliente_id, nombre, ciudad, membresia, fecha_alta)
VALUES (-1, 'ANONIMO', 'Comprador Anónimo', 'Sin Ciudad', 'Sin Membresía', NULL);

INSERT INTO DIM_PROMOCION (promocion_key, promocion_id, nombre, tipo_dependencia, valor_descuento)
VALUES (-1, 'SIN_PROMO', 'Sin Promoción', 'Ninguna', 0.00);

INSERT INTO DIM_SUSCRIPCION (suscripcion_key, suscripcion_id, frecuencia, estatus)
VALUES (-1, 'NO_RECURRENTE', 'No Aplica', 'Inactiva');