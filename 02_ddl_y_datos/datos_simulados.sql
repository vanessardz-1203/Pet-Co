USE PETCO_DATAMART;
-- =====================================================================
-- PET&CO  |  PETCO_DATAMART  |  Actividad Unidad 3
-- 02_carga_datos_simulados.sql
-- Motor: MySQL 8.0 (Workbench 8.0 CE)
--
-- REQUISITOS
--   1) Haber ejecutado DDL_PETCO_Eq7.sql SIN modificarlo (solo existen los
--      registros centinela con clave -1).
--   2) Ejecutar este script completo (Query > Execute All / icono del rayo).
--
-- DATOS: 100% ficticios. Nombres de clientes generados por combinación de
-- listas genéricas. No hay datos personales reales.
--
-- REPRODUCIBLE: no se usa RAND(). La función fn_u() produce números
-- pseudoaleatorios a partir de MD5, así que cada ejecución genera
-- exactamente los mismos datos.
--
-- PARA REPETIR LA CARGA: ejecutar de nuevo DDL_PETCO_Eq7.sql sobre una base
-- vacía (DROP DATABASE PETCO_DATAMART; y volver a crearla) y luego este script.
-- =====================================================================

USE PETCO_DATAMART;

-- Las tablas auxiliares tienen hasta 4,000 filas; el límite por defecto de
-- recursión de MySQL es 1,000.
SET SESSION cte_max_recursion_depth = 10000;

-- ---------------------------------------------------------------------
-- 0. HERRAMIENTAS AUXILIARES (se eliminan al final)
-- ---------------------------------------------------------------------

-- Número pseudoaleatorio uniforme en [0,1) determinista: misma entrada,
-- misma salida. p_n = identificador de la fila, p_salt = "tema" del sorteo.
DROP FUNCTION IF EXISTS fn_u;
CREATE FUNCTION fn_u(p_n BIGINT, p_salt VARCHAR(20)) RETURNS DOUBLE
DETERMINISTIC NO SQL
RETURN CONV(LEFT(MD5(CONCAT(p_n, ':', p_salt)), 8), 16, 10) / 4294967296;

DROP TABLE IF EXISTS STG_LINEA;
DROP TABLE IF EXISTS STG_TICKET;
DROP TABLE IF EXISTS STG_PESO_REGION;
DROP TABLE IF EXISTS STG_SUSC;
DROP TABLE IF EXISTS STG_PRODUCTO_SIM;
DROP TABLE IF EXISTS STG_NUM;

-- Tabla de números 1..4000 (sustituye ciclos; MySQL no tiene generate_series)
CREATE TABLE STG_NUM (n INT NOT NULL PRIMARY KEY);
INSERT INTO STG_NUM (n)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 4000
)
SELECT n FROM seq;

-- ---------------------------------------------------------------------
-- 1. DIM_TIEMPO  (todo 2026: 365 días)
-- ---------------------------------------------------------------------
INSERT INTO DIM_TIEMPO (fecha_key, fecha, anio, mes, nombre_mes, trimestre, dia_semana, es_fin_semana)
WITH RECURSIVE cal AS (
    SELECT DATE('2026-01-01') AS f
    UNION ALL
    SELECT f + INTERVAL 1 DAY FROM cal WHERE f < DATE('2026-12-31')
)
SELECT CAST(DATE_FORMAT(f, '%Y%m%d') AS UNSIGNED),
       f,
       YEAR(f),
       MONTH(f),
       ELT(MONTH(f), 'Enero','Febrero','Marzo','Abril','Mayo','Junio',
                     'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'),
       QUARTER(f),
       ELT(WEEKDAY(f) + 1, 'Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'),
       WEEKDAY(f) >= 5
FROM cal;

-- ---------------------------------------------------------------------
-- 2. DIM_CANAL
-- ---------------------------------------------------------------------
INSERT INTO DIM_CANAL (canal_key, nombre_canal) VALUES
(1, 'Tienda Física'),
(2, 'E-commerce'),
(3, 'Click & Collect');

-- ---------------------------------------------------------------------
-- 3. DIM_TIENDA  (12 tiendas, 4 regiones)
-- ---------------------------------------------------------------------
INSERT INTO DIM_TIENDA (tienda_key, tienda_id, nombre, ciudad, region) VALUES
(1,  'T01', 'Pet&Co Monterrey Centro',   'Monterrey',        'Noreste'),
(2,  'T02', 'Pet&Co Apodaca',            'Apodaca',          'Noreste'),
(3,  'T03', 'Pet&Co Saltillo',           'Saltillo',         'Noreste'),
(4,  'T04', 'Pet&Co Guadalajara Centro', 'Guadalajara',      'Occidente'),
(5,  'T05', 'Pet&Co Zapopan',            'Zapopan',          'Occidente'),
(6,  'T06', 'Pet&Co León',               'León',             'Occidente'),
(7,  'T07', 'Pet&Co CDMX Norte',         'Ciudad de México', 'Centro'),
(8,  'T08', 'Pet&Co Querétaro',          'Querétaro',        'Centro'),
(9,  'T09', 'Pet&Co Puebla',             'Puebla',           'Centro'),
(10, 'T10', 'Pet&Co Mérida',             'Mérida',           'Sureste'),
(11, 'T11', 'Pet&Co Cancún',             'Cancún',           'Sureste'),
(12, 'T12', 'Pet&Co Villahermosa',       'Villahermosa',     'Sureste');

-- ---------------------------------------------------------------------
-- 4. DIM_PRODUCTO  (51 productos)
--    El precio, el costo y el "peso" de popularidad NO existen en
--    DIM_PRODUCTO; viven en una tabla auxiliar solo para generar los hechos.
--    Productos 49-51: lanzamiento el 2026-04-01 (sin ventas en el Q1).
-- ---------------------------------------------------------------------
CREATE TABLE STG_PRODUCTO_SIM (
    producto_key     INT           NOT NULL PRIMARY KEY,
    producto_id      VARCHAR(50)   NOT NULL,
    nombre           VARCHAR(150)  NOT NULL,
    marca            VARCHAR(50)   NOT NULL,
    categoria        VARCHAR(50)   NOT NULL,
    especie_objetivo VARCHAR(50)   NOT NULL,
    presentacion     VARCHAR(50)   NOT NULL,
    precio_base      DECIMAL(12,2) NOT NULL,
    costo_base       DECIMAL(12,2) NOT NULL,
    peso             INT           NOT NULL
);

INSERT INTO STG_PRODUCTO_SIM
(producto_key, producto_id, nombre, marca, categoria, especie_objetivo, presentacion, precio_base, costo_base, peso) VALUES
(1,  'P001', 'NutriCan Adulto Razas Medianas 15 kg',  'NutriCan',         'Alimento',                     'Perro',  'Costal 15 kg',        689.00,  455.00, 8),
(2,  'P002', 'NutriCan Adulto Razas Medianas 4 kg',   'NutriCan',         'Alimento',                     'Perro',  'Bolsa 4 kg',          229.00,  150.00, 9),
(3,  'P003', 'NutriCan Cachorro 7.5 kg',              'NutriCan',         'Alimento',                     'Perro',  'Bolsa 7.5 kg',        389.00,  255.00, 6),
(4,  'P004', 'NutriCan Senior 7.5 kg',                'NutriCan',         'Alimento',                     'Perro',  'Bolsa 7.5 kg',        410.00,  270.00, 4),
(5,  'P005', 'MasterPaw Premium Adulto 15 kg',        'MasterPaw',        'Alimento',                     'Perro',  'Costal 15 kg',       1189.00,  800.00, 5),
(6,  'P006', 'MasterPaw Premium Cachorro 3 kg',       'MasterPaw',        'Alimento',                     'Perro',  'Bolsa 3 kg',          435.00,  290.00, 4),
(7,  'P007', 'MasterPaw Razas Pequeñas 2 kg',         'MasterPaw',        'Alimento',                     'Perro',  'Bolsa 2 kg',          320.00,  210.00, 5),
(8,  'P008', 'Pet&Co Selección Adulto 20 kg',         'Pet&Co Selección', 'Alimento',                     'Perro',  'Costal 20 kg',        799.00,  540.00, 6),
(9,  'P009', 'Pet&Co Selección Lata Res 354 g',       'Pet&Co Selección', 'Alimento',                     'Perro',  'Lata 354 g',           38.00,   22.00, 10),
(10, 'P010', 'FelinoPlus Adulto Pollo 3 kg',          'FelinoPlus',       'Alimento',                     'Gato',   'Bolsa 3 kg',          345.00,  225.00, 9),
(11, 'P011', 'FelinoPlus Adulto Pollo 7.5 kg',        'FelinoPlus',       'Alimento',                     'Gato',   'Bolsa 7.5 kg',        760.00,  510.00, 6),
(12, 'P012', 'FelinoPlus Gatito 1.5 kg',              'FelinoPlus',       'Alimento',                     'Gato',   'Bolsa 1.5 kg',        215.00,  140.00, 5),
(13, 'P013', 'FelinoPlus Esterilizado 3 kg',          'FelinoPlus',       'Alimento',                     'Gato',   'Bolsa 3 kg',          399.00,  265.00, 5),
(14, 'P014', 'MasterPaw Gato Salmón 1.5 kg',          'MasterPaw',        'Alimento',                     'Gato',   'Bolsa 1.5 kg',        289.00,  190.00, 4),
(15, 'P015', 'Pet&Co Selección Gato Adulto 10 kg',    'Pet&Co Selección', 'Alimento',                     'Gato',   'Costal 10 kg',        749.00,  500.00, 5),
(16, 'P016', 'Pet&Co Selección Sobre Atún 85 g',      'Pet&Co Selección', 'Alimento',                     'Gato',   'Sobre 85 g',           14.00,    8.00, 10),
(17, 'P017', 'NutriCan Galletas Dentales 12 pzas',    'NutriCan',         'Snacks y premios',             'Perro',  'Paquete 12 pzas',     129.00,   70.00, 6),
(18, 'P018', 'MasterPaw Hueso Natural 2 pzas',        'MasterPaw',        'Snacks y premios',             'Perro',  'Paquete 2 pzas',       99.00,   55.00, 5),
(19, 'P019', 'FelinoPlus Premios Crujientes 60 g',    'FelinoPlus',       'Snacks y premios',             'Gato',   'Bolsa 60 g',           45.00,   24.00, 6),
(20, 'P020', 'Pet&Co Selección Premios de Pollo 200 g','Pet&Co Selección','Snacks y premios',             'Perro',  'Bolsa 200 g',          85.00,   46.00, 5),
(21, 'P021', 'VitaPet Shampoo Hipoalergénico 500 ml', 'VitaPet',          'Higiene y cuidado',            'Perro',  'Botella 500 ml',      159.00,   80.00, 4),
(22, 'P022', 'VitaPet Arena Aglomerante 10 kg',       'VitaPet',          'Higiene y cuidado',            'Gato',   'Bolsa 10 kg',         219.00,  120.00, 7),
(23, 'P023', 'VitaPet Arena de Sílica 3.8 L',         'VitaPet',          'Higiene y cuidado',            'Gato',   'Bolsa 3.8 L',         169.00,   95.00, 4),
(24, 'P024', 'VitaPet Kit Cepillo Dental',            'VitaPet',          'Higiene y cuidado',            'Perro',  'Kit',                  89.00,   42.00, 2),
(25, 'P025', 'VitaPet Toallitas Húmedas 80 pzas',     'VitaPet',          'Higiene y cuidado',            'Perro',  'Paquete 80 pzas',      79.00,   38.00, 3),
(26, 'P026', 'VitaPet Antipulgas Pipeta Perro 3 pzas','VitaPet',          'Salud y bienestar',            'Perro',  'Caja 3 pipetas',      349.00,  190.00, 4),
(27, 'P027', 'VitaPet Antipulgas Pipeta Gato 3 pzas', 'VitaPet',          'Salud y bienestar',            'Gato',   'Caja 3 pipetas',      329.00,  180.00, 3),
(28, 'P028', 'MasterPaw Collar Ajustable M',          'MasterPaw',        'Accesorios',                   'Perro',  'Pieza',               119.00,   55.00, 3),
(29, 'P029', 'MasterPaw Correa Retráctil 5 m',        'MasterPaw',        'Accesorios',                   'Perro',  'Pieza',               249.00,  125.00, 2),
(30, 'P030', 'MasterPaw Arnés Acolchado L',           'MasterPaw',        'Accesorios',                   'Perro',  'Pieza',               299.00,  150.00, 2),
(31, 'P031', 'FelinoPlus Rascador Torre 90 cm',       'FelinoPlus',       'Accesorios',                   'Gato',   'Pieza',               899.00,  520.00, 1),
(32, 'P032', 'FelinoPlus Cama Cueva',                 'FelinoPlus',       'Accesorios',                   'Gato',   'Pieza',               459.00,  250.00, 2),
(33, 'P033', 'MasterPaw Cama Ortopédica L',           'MasterPaw',        'Accesorios',                   'Perro',  'Pieza',               799.00,  450.00, 1),
(34, 'P034', 'Pet&Co Transportadora Mediana',         'Pet&Co Selección', 'Accesorios',                   'Perro',  'Pieza',               649.00,  370.00, 1),
(35, 'P035', 'Pet&Co Comedero de Acero Doble',        'Pet&Co Selección', 'Accesorios',                   'Perro',  'Pieza',               129.00,   60.00, 3),
(36, 'P036', 'Pet&Co Fuente de Agua 2 L',             'Pet&Co Selección', 'Accesorios',                   'Gato',   'Pieza',               499.00,  270.00, 2),
(37, 'P037', 'MasterPaw Pelota de Goma',              'MasterPaw',        'Juguetes',                     'Perro',  'Pieza',                69.00,   28.00, 5),
(38, 'P038', 'MasterPaw Cuerda Mordedera',            'MasterPaw',        'Juguetes',                     'Perro',  'Pieza',                89.00,   35.00, 4),
(39, 'P039', 'FelinoPlus Ratones de Peluche 3 pzas',  'FelinoPlus',       'Juguetes',                     'Gato',   'Paquete 3 pzas',       59.00,   22.00, 4),
(40, 'P040', 'FelinoPlus Varita con Plumas',          'FelinoPlus',       'Juguetes',                     'Gato',   'Pieza',                49.00,   18.00, 3),
(41, 'P041', 'AquaVida Alimento en Hojuelas 100 g',   'AquaVida',         'Acuarismo y especies menores', 'Pez',    'Frasco 100 g',         69.00,   35.00, 5),
(42, 'P042', 'AquaVida Kit Acuario 40 L',             'AquaVida',         'Acuarismo y especies menores', 'Pez',    'Kit',                1299.00,  760.00, 1),
(43, 'P043', 'AquaVida Filtro Interno',               'AquaVida',         'Acuarismo y especies menores', 'Pez',    'Pieza',               349.00,  190.00, 2),
(44, 'P044', 'AquaVida Acondicionador de Agua 250 ml','AquaVida',         'Acuarismo y especies menores', 'Pez',    'Botella 250 ml',       99.00,   48.00, 3),
(45, 'P045', 'PlumaFeliz Mezcla de Semillas 1 kg',    'PlumaFeliz',       'Acuarismo y especies menores', 'Ave',    'Bolsa 1 kg',           89.00,   48.00, 3),
(46, 'P046', 'PlumaFeliz Jaula Mediana',              'PlumaFeliz',       'Acuarismo y especies menores', 'Ave',    'Pieza',               899.00,  510.00, 1),
(47, 'P047', 'PlumaFeliz Mineral para Aves',          'PlumaFeliz',       'Acuarismo y especies menores', 'Ave',    'Pieza',                39.00,   16.00, 2),
(48, 'P048', 'RoedorMix Alimento para Hámster 500 g', 'RoedorMix',        'Acuarismo y especies menores', 'Roedor', 'Bolsa 500 g',          79.00,   42.00, 2),
(49, 'P049', 'NutriCan Grain Free Adulto 10 kg',      'NutriCan',         'Alimento',                     'Perro',  'Bolsa 10 kg',         849.00,  570.00, 6),
(50, 'P050', 'FelinoPlus Grain Free Adulto 3 kg',     'FelinoPlus',       'Alimento',                     'Gato',   'Bolsa 3 kg',          449.00,  295.00, 6),
(51, 'P051', 'VitaPet Suplemento Articular 60 tabletas','VitaPet',        'Salud y bienestar',            'Perro',  'Frasco 60 tabletas',  389.00,  210.00, 4);

INSERT INTO DIM_PRODUCTO (producto_key, producto_id, nombre, marca, categoria, especie_objetivo, presentacion)
SELECT producto_key, producto_id, nombre, marca, categoria, especie_objetivo, presentacion
FROM STG_PRODUCTO_SIM;

-- ---------------------------------------------------------------------
-- 5. DIM_PROMOCION  (6 promociones; la -1 ya existe como centinela)
--    valor_descuento se interpreta como PORCENTAJE (10.00 = 10 %).
-- ---------------------------------------------------------------------
INSERT INTO DIM_PROMOCION (promocion_key, promocion_id, nombre, tipo_dependencia, valor_descuento) VALUES
(1, 'PR01', 'Promo NutriCan 10%',      'Marca',      10.00),
(2, 'PR02', 'Promo MasterPaw 15%',     'Marca',      15.00),
(3, 'PR03', 'Promo FelinoPlus 12%',    'Marca',      12.00),
(4, 'PR04', 'Promo AquaVida 20%',      'Marca',      20.00),
(5, 'PR05', 'Membresía Plus 5%',       'Membresía',   5.00),
(6, 'PR06', 'Membresía Premium 10%',   'Membresía',  10.00);

-- ---------------------------------------------------------------------
-- 6. DIM_CLIENTE  (600 clientes registrados; el -1 ya existe)
--    ciudad = ciudad de su tienda "hogar" (sorteada). Alta entre 2023-01-01
--    y 2025-12-31, así todos existen antes de su primera compra.
-- ---------------------------------------------------------------------
INSERT INTO DIM_CLIENTE (cliente_key, cliente_id, nombre, ciudad, membresia, fecha_alta)
SELECT c.n,
       CONCAT('C', LPAD(c.n, 4, '0')),
       CONCAT(
         ELT(1 + MOD(c.n, 20), 'Ana','Luis','María','Jorge','Sofía','Carlos','Valeria','Miguel','Daniela','Andrés',
                               'Fernanda','Ricardo','Paola','Héctor','Mariana','Diego','Alejandra','Raúl','Camila','Iván'),
         ' ',
         ELT(1 + MOD(FLOOR(c.n / 20), 20), 'García','Martínez','López','Hernández','González','Pérez','Rodríguez','Sánchez','Ramírez','Flores',
                                           'Torres','Rivera','Gómez','Díaz','Cruz','Morales','Reyes','Ortiz','Gutiérrez','Vargas'),
         ' ',
         ELT(1 + MOD(c.n * 7 + 3, 20), 'García','Martínez','López','Hernández','González','Pérez','Rodríguez','Sánchez','Ramírez','Flores',
                                       'Torres','Rivera','Gómez','Díaz','Cruz','Morales','Reyes','Ortiz','Gutiérrez','Vargas')
       ),
       t.ciudad,
       CASE WHEN fn_u(c.n, 'mem') < 0.50 THEN 'Básica'
            WHEN fn_u(c.n, 'mem') < 0.80 THEN 'Plus'
            ELSE 'Premium' END,
       DATE_ADD(DATE('2023-01-01'), INTERVAL FLOOR(fn_u(c.n, 'alta') * 1095) DAY)
FROM STG_NUM c
JOIN DIM_TIENDA t ON t.tienda_key = 1 + FLOOR(fn_u(c.n, 'home') * 12)
WHERE c.n <= 600;

-- ---------------------------------------------------------------------
-- 7. DIM_SUSCRIPCION  (150 suscripciones; la -1 ya existe)
--    Auxiliar STG_SUSC guarda lo que DIM_SUSCRIPCION no almacena:
--    cliente dueño, producto recurrente y tienda hogar.
--    Cliente suscrito = 4 * suscripcion_key (clientes 4, 8, ..., 600).
--    Estatus: 10% Cancelada (solo compra ene-mar), 10% Pausada (compra
--    ene-may), 80% Activa.
-- ---------------------------------------------------------------------
CREATE TABLE STG_SUSC (
    suscripcion_key INT         NOT NULL PRIMARY KEY,
    cliente_key     INT         NOT NULL,
    producto_key    INT         NOT NULL,
    tienda_key      INT         NOT NULL,
    frecuencia      VARCHAR(30) NOT NULL,
    estatus         VARCHAR(20) NOT NULL
);

INSERT INTO STG_SUSC (suscripcion_key, cliente_key, producto_key, tienda_key, frecuencia, estatus)
SELECT s.n,
       c.cliente_key,
       1 + MOD(s.n * 7, 16),                 -- producto de alimento (claves 1-16)
       t.tienda_key,
       CASE WHEN fn_u(s.n, 'frec') < 0.70 THEN 'Mensual' ELSE 'Quincenal' END,
       CASE MOD(s.n, 10) WHEN 0 THEN 'Cancelada' WHEN 1 THEN 'Pausada' ELSE 'Activa' END
FROM STG_NUM s
JOIN DIM_CLIENTE c ON c.cliente_key = 4 * s.n
JOIN DIM_TIENDA  t ON t.ciudad = c.ciudad
WHERE s.n <= 150;

INSERT INTO DIM_SUSCRIPCION (suscripcion_key, suscripcion_id, frecuencia, estatus)
SELECT suscripcion_key, CONCAT('S', LPAD(suscripcion_key, 4, '0')), frecuencia, estatus
FROM STG_SUSC;

-- ---------------------------------------------------------------------
-- 8. POPULARIDAD DE PRODUCTOS POR REGIÓN (para que el Top 5 cambie por región)
--    Rango acumulado [ini, fin] por región: sirve para muestreo ponderado.
-- ---------------------------------------------------------------------
CREATE TABLE STG_PESO_REGION (
    region       VARCHAR(50) NOT NULL,
    producto_key INT         NOT NULL,
    ini          INT         NOT NULL,
    fin          INT         NOT NULL,
    total        INT         NOT NULL,
    PRIMARY KEY (region, producto_key)
);

INSERT INTO STG_PESO_REGION (region, producto_key, ini, fin, total)
WITH w AS (
    SELECT r.region,
           p.producto_key,
           GREATEST(1, ROUND(p.peso *
               CASE WHEN r.region = 'Sureste'   AND p.categoria = 'Acuarismo y especies menores' THEN 3.0
                    WHEN r.region = 'Noreste'   AND p.especie_objetivo = 'Perro'                 THEN 1.4
                    WHEN r.region = 'Occidente' AND p.especie_objetivo = 'Gato'                  THEN 1.4
                    WHEN r.region = 'Centro'    AND p.categoria = 'Accesorios'                   THEN 1.5
                    ELSE 1.0 END)) AS peso
    FROM (SELECT DISTINCT region FROM DIM_TIENDA) r
    CROSS JOIN STG_PRODUCTO_SIM p
),
acum AS (
    SELECT region, producto_key, peso,
           SUM(peso) OVER (PARTITION BY region ORDER BY producto_key) AS fin,
           SUM(peso) OVER (PARTITION BY region)                       AS total
    FROM w
)
SELECT region, producto_key, fin - peso + 1, fin, total
FROM acum;

-- ---------------------------------------------------------------------
-- 9. TICKETS (nivel venta_id): fecha, cliente, tiendas, canal, suscripción
--    Estos atributos son constantes dentro de un ticket.
--      - 3,500 tickets orgánicos: 1,600 en Q1 y 1,900 en Q2 (crecimiento).
--      - Tickets de suscripción: según frecuencia y estatus (E-commerce).
-- ---------------------------------------------------------------------
CREATE TABLE STG_TICKET (
    venta_num          INT         NOT NULL PRIMARY KEY,
    origen             CHAR(1)     NOT NULL,        -- 'O' orgánico, 'S' suscripción
    fecha              DATE        NOT NULL,
    cliente_key        INT         NOT NULL,
    tienda_surtido_key INT         NOT NULL,
    tienda_entrega_key INT         NULL,
    canal_key          INT         NOT NULL,
    suscripcion_key    INT         NOT NULL,
    n_lineas           INT         NOT NULL,
    producto_fijo      INT         NULL             -- solo tickets de suscripción
);

INSERT INTO STG_TICKET
(venta_num, origen, fecha, cliente_key, tienda_surtido_key, tienda_entrega_key, canal_key, suscripcion_key, n_lineas, producto_fijo)
WITH org_base AS (
    -- fecha y cliente (40% anónimos = -1)
    SELECT n,
           CASE WHEN n <= 1600
                THEN DATE_ADD(DATE('2026-01-01'), INTERVAL FLOOR(fn_u(n, 'dia') * 90) DAY)   -- Q1: 90 días
                ELSE DATE_ADD(DATE('2026-04-01'), INTERVAL FLOOR(fn_u(n, 'dia') * 91) DAY)   -- Q2: 91 días
           END AS fecha,
           CASE WHEN fn_u(n, 'reg') < 0.60 THEN 1 + FLOOR(fn_u(n, 'cli') * 600) ELSE -1 END AS cliente_key
    FROM STG_NUM
    WHERE n <= 3500
),
org_canal AS (
    -- canal (anónimo => solo tienda física) y tienda "hogar" del cliente
    SELECT b.n, b.fecha, b.cliente_key,
           th.tienda_key AS tienda_hogar,
           CASE WHEN b.cliente_key = -1            THEN 1
                WHEN fn_u(b.n, 'canal') < 0.40     THEN 1
                WHEN fn_u(b.n, 'canal') < 0.75     THEN 2
                ELSE 3 END AS canal_key
    FROM org_base b
    LEFT JOIN DIM_CLIENTE c  ON c.cliente_key = b.cliente_key
    LEFT JOIN DIM_TIENDA  th ON th.ciudad     = c.ciudad
),
org_tienda AS (
    -- tienda que surte: 75% la del cliente, 25% cualquiera
    SELECT o.*,
           CASE WHEN o.tienda_hogar IS NOT NULL AND fn_u(o.n, 'hogar') < 0.75
                THEN o.tienda_hogar
                ELSE 1 + FLOOR(fn_u(o.n, 'tienda') * 12) END AS tienda_surtido_key
    FROM org_canal o
),
organicos AS (
    SELECT 'O' AS origen,
           n   AS ref,
           fecha,
           cliente_key,
           tienda_surtido_key,
           -- entrega solo en Click & Collect y SIEMPRE distinta de la tienda que surte
           CASE WHEN canal_key = 3
                THEN 1 + MOD(tienda_surtido_key + FLOOR(fn_u(n, 'ent') * 11), 12) END AS tienda_entrega_key,
           canal_key,
           -1  AS suscripcion_key,
           CASE WHEN fn_u(n, 'lin') < 0.35 THEN 1
                WHEN fn_u(n, 'lin') < 0.65 THEN 2
                WHEN fn_u(n, 'lin') < 0.85 THEN 3
                WHEN fn_u(n, 'lin') < 0.95 THEN 4
                ELSE 5 END AS n_lineas,
           NULL AS producto_fijo
    FROM org_tienda
),
subs AS (
    -- Mensual: 1 ticket al mes (día 3-24). Quincenal: 2 al mes (días 2-13 y +14).
    SELECT 'S' AS origen,
           s.suscripcion_key * 100 + m.n * 10 + o.n AS ref,
           DATE_ADD(DATE_ADD(DATE('2026-01-01'), INTERVAL (m.n - 1) MONTH),
                    INTERVAL ((CASE WHEN s.frecuencia = 'Mensual'
                                    THEN 3 + MOD(s.suscripcion_key, 22)
                                    ELSE 2 + MOD(s.suscripcion_key, 12) + 14 * (o.n - 1) END) - 1) DAY) AS fecha,
           s.cliente_key,
           s.tienda_key AS tienda_surtido_key,
           NULL         AS tienda_entrega_key,
           2            AS canal_key,
           s.suscripcion_key,
           1            AS n_lineas,
           s.producto_key AS producto_fijo
    FROM STG_SUSC s
    JOIN STG_NUM m ON m.n <= 6      -- meses enero a junio
    JOIN STG_NUM o ON o.n <= 2      -- ocurrencia dentro del mes
    WHERE (o.n = 1 OR s.frecuencia = 'Quincenal')
      AND (   s.estatus = 'Activa'
           OR (s.estatus = 'Pausada'   AND m.n <= 5)
           OR (s.estatus = 'Cancelada' AND m.n <= 3))
),
todos AS (
    SELECT * FROM organicos
    UNION ALL
    SELECT * FROM subs
)
SELECT ROW_NUMBER() OVER (ORDER BY fecha, origen, ref) AS venta_num,
       origen, fecha, cliente_key, tienda_surtido_key, tienda_entrega_key,
       canal_key, suscripcion_key, n_lineas, producto_fijo
FROM todos;

-- ---------------------------------------------------------------------
-- 10. LÍNEAS BRUTAS: producto y cantidad base por línea de ticket
-- ---------------------------------------------------------------------
CREATE TABLE STG_LINEA (
    venta_num     INT NOT NULL,
    linea         INT NOT NULL,
    producto_key  INT NOT NULL,
    cantidad_base INT NOT NULL,
    PRIMARY KEY (venta_num, linea)
);

-- 10a. Tickets orgánicos: producto por muestreo ponderado según la región de la tienda
INSERT INTO STG_LINEA (venta_num, linea, producto_key, cantidad_base)
WITH lin AS (
    SELECT t.venta_num, t.fecha, j.n AS linea, ti.region
    FROM STG_TICKET t
    JOIN STG_NUM    j  ON j.n <= t.n_lineas                    -- expande 1 ticket en n líneas
    JOIN DIM_TIENDA ti ON ti.tienda_key = t.tienda_surtido_key
    WHERE t.origen = 'O'
),
sorteo AS (
    SELECT l.venta_num, l.fecha, l.linea, w.producto_key AS producto_sorteado
    FROM lin l
    JOIN STG_PESO_REGION w
      ON  w.region = l.region
      AND (1 + FLOOR(fn_u(l.venta_num * 10 + l.linea, 'prod') * w.total)) BETWEEN w.ini AND w.fin
)
SELECT s.venta_num,
       s.linea,
       -- antes del 2026-04-01 los productos nuevos (49-51) no existían: se sustituyen por su antecesor
       CASE WHEN s.fecha < DATE('2026-04-01') AND s.producto_sorteado >= 49
            THEN CASE s.producto_sorteado WHEN 49 THEN 1 WHEN 50 THEN 10 ELSE 26 END
            ELSE s.producto_sorteado END,
       CASE WHEN fn_u(s.venta_num * 10 + s.linea, 'qty') < 0.60 THEN 1
            WHEN fn_u(s.venta_num * 10 + s.linea, 'qty') < 0.85 THEN 2
            WHEN fn_u(s.venta_num * 10 + s.linea, 'qty') < 0.95 THEN 3
            ELSE 4 END
FROM sorteo s;

-- 10b. Tickets de suscripción: una línea con el producto recurrente
INSERT INTO STG_LINEA (venta_num, linea, producto_key, cantidad_base)
SELECT t.venta_num, 1, t.producto_fijo,
       CASE WHEN fn_u(t.venta_num, 'sqty') < 0.75 THEN 1 ELSE 2 END
FROM STG_TICKET t
WHERE t.origen = 'S';

-- ---------------------------------------------------------------------
-- 11. FACT_VENTAS
--     Grano: un producto vendido dentro de una venta (ticket).
--     bruto = cantidad * precio ; descuento = bruto * % promoción ;
--     neto = bruto - descuento ; margen = neto - cantidad * costo.
-- ---------------------------------------------------------------------
INSERT INTO FACT_VENTAS
(detalle_id, venta_id, fecha_key, cliente_key, producto_key, tienda_surtido_key, tienda_entrega_key,
 canal_key, promocion_key, suscripcion_key, cantidad, descuento, importe_bruto, importe_neto, margen,
 precio_unitario, costo_unitario)
WITH lineas AS (
    -- si un producto salió 2 veces en el mismo ticket, se suma en UNA fila (respeta el grano)
    SELECT venta_num, producto_key, SUM(cantidad_base) AS cantidad_base
    FROM STG_LINEA
    GROUP BY venta_num, producto_key
),
detalle AS (
    SELECT ROW_NUMBER() OVER (ORDER BY ln.venta_num, ln.producto_key) AS detalle_id,
           t.venta_num, t.fecha, t.cliente_key, t.tienda_surtido_key, t.tienda_entrega_key,
           t.canal_key, t.suscripcion_key, ln.producto_key,
           ln.cantidad_base * CASE WHEN p.precio_base < 100 THEN 2 ELSE 1 END AS cantidad,  -- artículos baratos se compran en más piezas
           p.precio_base AS precio_unitario,
           p.costo_base  AS costo_unitario,
           CASE p.marca WHEN 'NutriCan' THEN 1 WHEN 'MasterPaw' THEN 2
                        WHEN 'FelinoPlus' THEN 3 WHEN 'AquaVida' THEN 4 END AS promo_marca,
           c.membresia
    FROM lineas ln
    JOIN STG_TICKET       t ON t.venta_num    = ln.venta_num
    JOIN STG_PRODUCTO_SIM p ON p.producto_key = ln.producto_key
    JOIN DIM_CLIENTE      c ON c.cliente_key  = t.cliente_key
),
con_promo AS (
    -- una sola promoción por línea: marca (30% de las líneas elegibles) y, si no, membresía
    SELECT d.*,
           CASE WHEN d.promo_marca IS NOT NULL AND fn_u(d.detalle_id, 'promo') < 0.30 THEN d.promo_marca
                WHEN d.membresia = 'Premium' THEN 6
                WHEN d.membresia = 'Plus'    THEN 5
                ELSE -1 END AS promocion_key
    FROM detalle d
),
calculo AS (
    SELECT cp.*,
           cp.cantidad * cp.precio_unitario AS importe_bruto,
           ROUND(cp.cantidad * cp.precio_unitario * pr.valor_descuento / 100, 2) AS descuento
    FROM con_promo cp
    JOIN DIM_PROMOCION pr ON pr.promocion_key = cp.promocion_key
)
SELECT detalle_id,
       CONCAT('V', LPAD(venta_num, 6, '0')),
       CAST(DATE_FORMAT(fecha, '%Y%m%d') AS UNSIGNED),
       cliente_key, producto_key, tienda_surtido_key, tienda_entrega_key,
       canal_key, promocion_key, suscripcion_key,
       cantidad,
       descuento,
       importe_bruto,
       importe_bruto - descuento,
       importe_bruto - descuento - cantidad * costo_unitario,
       precio_unitario,
       costo_unitario
FROM calculo;

-- ---------------------------------------------------------------------
-- 12. LIMPIEZA de objetos auxiliares
--     (comentar este bloque si quieren conservar las tablas STG_* para auditar)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS STG_LINEA;
DROP TABLE IF EXISTS STG_TICKET;
DROP TABLE IF EXISTS STG_PESO_REGION;
DROP TABLE IF EXISTS STG_SUSC;
DROP TABLE IF EXISTS STG_PRODUCTO_SIM;
DROP TABLE IF EXISTS STG_NUM;
DROP FUNCTION IF EXISTS fn_u;

-- Resumen rápido
SELECT 'FACT_VENTAS' AS tabla, COUNT(*) AS filas FROM FACT_VENTAS;