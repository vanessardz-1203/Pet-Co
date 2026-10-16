-- =====================================================================
-- PET&CO  |  PETCO_DATAMART  |  Actividad Unidad 3
-- 04_validaciones_top5.sql
-- Motor: MySQL 8.0 (Workbench 8.0 CE)
--
-- COMO USARLO: ejecutar TODO el archivo en una misma pestaña (Execute All).
-- El paso 0 guarda el reporte en una tabla TEMPORAL (solo vive en esta sesión,
-- no modifica el esquema). Los pasos 1 a 8 la validan.
-- Cada validación indica qué resultado se espera. Los resultados reales son
-- los que ustedes obtengan al ejecutarlo.
-- =====================================================================

USE PETCO_DATAMART;

-- ---------------------------------------------------------------------
-- 0. Guardar el reporte (MISMA consulta de 03_consulta_top5_rentabilidad.sql)
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_reporte;

CREATE TEMPORARY TABLE tmp_reporte AS
WITH margen_q2 AS (
    -- Margen acumulado por región y producto en el periodo actual (Q2 2026)
    SELECT ti.region,
           f.producto_key,
           SUM(f.margen) AS margen_q2
    FROM FACT_VENTAS f
    JOIN DIM_TIEMPO  t  ON t.fecha_key  = f.fecha_key
    JOIN DIM_TIENDA  ti ON ti.tienda_key = f.tienda_surtido_key
    WHERE t.anio = 2026
      AND t.trimestre = 2
    GROUP BY ti.region, f.producto_key
),
margen_q1 AS (
    -- Margen acumulado por región y producto en el periodo anterior (Q1 2026)
    SELECT ti.region,
           f.producto_key,
           SUM(f.margen) AS margen_q1
    FROM FACT_VENTAS f
    JOIN DIM_TIEMPO  t  ON t.fecha_key  = f.fecha_key
    JOIN DIM_TIENDA  ti ON ti.tienda_key = f.tienda_surtido_key
    WHERE t.anio = 2026
      AND t.trimestre = 1
    GROUP BY ti.region, f.producto_key
),
ranking_q2 AS (
    -- Posición de cada producto dentro de su región según el margen de Q2
    SELECT region,
           producto_key,
           margen_q2,
           ROW_NUMBER() OVER (
               PARTITION BY region
               ORDER BY margen_q2 DESC, producto_key ASC
           ) AS posicion
    FROM margen_q2
),
top5_q2 AS (
    -- Solo los cinco primeros de cada región
    SELECT region, producto_key, margen_q2, posicion
    FROM ranking_q2
    WHERE posicion <= 5
)
SELECT r.region                                   AS region,
       r.posicion                                 AS posicion_top5,
       r.producto_key                             AS producto_key,
       p.nombre                                   AS nombre_producto,
       q1.margen_q1                               AS margen_q1_2026,
       r.margen_q2                                AS margen_q2_2026,
       CASE WHEN q1.producto_key IS NULL
            THEN NULL
            ELSE r.margen_q2 - q1.margen_q1
       END                                        AS variacion_absoluta,
       CASE WHEN q1.producto_key IS NULL
              OR q1.margen_q1 = 0
            THEN NULL
            ELSE ROUND((r.margen_q2 - q1.margen_q1) / q1.margen_q1 * 100, 2)
       END                                        AS variacion_porcentual,
       CASE WHEN q1.producto_key IS NULL
            THEN 'SIN_DATOS_Q1'
            ELSE 'CON_DATOS_Q1'
       END                                        AS indicador_q1
FROM top5_q2 r
JOIN DIM_PRODUCTO p
  ON p.producto_key = r.producto_key
LEFT JOIN margen_q1 q1
  ON  q1.region       = r.region
  AND q1.producto_key = r.producto_key
ORDER BY r.region, r.posicion;

-- ---------------------------------------------------------------------
-- 1. Vista del reporte
--    ESPERADO: hasta 5 filas por región, ordenadas por posición.
-- ---------------------------------------------------------------------
SELECT * FROM tmp_reporte ORDER BY region, posicion_top5;

-- ---------------------------------------------------------------------
-- 2. El margen guardado en cada línea coincide con la fórmula
--    margen = importe_neto - cantidad * costo_unitario
--    ESPERADO: 0
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS lineas_con_margen_incorrecto
FROM FACT_VENTAS
WHERE margen <> importe_neto - cantidad * costo_unitario;

-- ---------------------------------------------------------------------
-- 3. Los márgenes del reporte coinciden con un recálculo independiente
--    (rangos de fecha_key en lugar de DIM_TIEMPO, y margen recalculado desde
--    importe_neto, cantidad y costo_unitario en lugar de la columna margen).
--    ESPERADO: 0 filas
-- ---------------------------------------------------------------------
SELECT r.region, r.producto_key,
       r.margen_q2, c.margen_q2_control,
       r.margen_q1, c.margen_q1_control
FROM tmp_reporte r
JOIN (
    SELECT ti.region, f.producto_key,
           SUM(CASE WHEN f.fecha_key BETWEEN 20260401 AND 20260630
                    THEN f.importe_neto - f.cantidad * f.costo_unitario END) AS margen_q2_control,
           SUM(CASE WHEN f.fecha_key BETWEEN 20260101 AND 20260331
                    THEN f.importe_neto - f.cantidad * f.costo_unitario END) AS margen_q1_control
    FROM FACT_VENTAS f
    JOIN DIM_TIENDA ti ON ti.tienda_key = f.tienda_surtido_key
    GROUP BY ti.region, f.producto_key
) c ON c.region = r.region AND c.producto_key = r.producto_key
WHERE r.margen_q2 <> c.margen_q2_control
   OR NOT (r.margen_q1 <=> c.margen_q1_control);

-- ---------------------------------------------------------------------
-- 4. No hay productos duplicados dentro de una misma región
--    ESPERADO: 0 filas
-- ---------------------------------------------------------------------
SELECT region, producto_key, COUNT(*) AS veces
FROM tmp_reporte
GROUP BY region, producto_key
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------
-- 5. Máximo cinco productos por región
--    ESPERADO: ninguna región con más de 5 (la columna productos debe ser <= 5)
-- ---------------------------------------------------------------------
SELECT region, COUNT(*) AS productos, MAX(posicion_top5) AS ultima_posicion
FROM tmp_reporte
GROUP BY region
ORDER BY region;

-- ---------------------------------------------------------------------
-- 6. El orden es correcto: el margen de Q2 nunca aumenta al bajar de posición
--    ESPERADO: 0 filas
-- ---------------------------------------------------------------------
SELECT region, posicion_top5, margen_q2, margen_previo
FROM (
    SELECT region, posicion_top5, margen_q2,
           LAG(margen_q2) OVER (PARTITION BY region ORDER BY posicion_top5) AS margen_previo
    FROM tmp_reporte
) x
WHERE margen_previo IS NOT NULL
  AND margen_q2 > margen_previo;

-- ---------------------------------------------------------------------
-- 6b. El Top 5 es realmente el Top 5: ranking independiente (recalculado desde
--     la tabla de hechos) contra el reporte.
--     ESPERADO: 0 filas
-- ---------------------------------------------------------------------
WITH control_q2 AS (
    SELECT ti.region, f.producto_key,
           ROW_NUMBER() OVER (
               PARTITION BY ti.region
               ORDER BY SUM(f.importe_neto - f.cantidad * f.costo_unitario) DESC, f.producto_key ASC
           ) AS pos
    FROM FACT_VENTAS f
    JOIN DIM_TIENDA ti ON ti.tienda_key = f.tienda_surtido_key
    WHERE f.fecha_key BETWEEN 20260401 AND 20260630
    GROUP BY ti.region, f.producto_key
)
SELECT c.region, c.pos, c.producto_key
FROM control_q2 c
WHERE c.pos <= 5
  AND NOT EXISTS (
      SELECT 1
      FROM tmp_reporte r
      WHERE r.region = c.region
        AND r.producto_key = c.producto_key
        AND r.posicion_top5 = c.pos
  );

-- ---------------------------------------------------------------------
-- 7. Coherencia del indicador de Q1 y de las variaciones
--    SIN_DATOS_Q1  => margen_q1, variacion_absoluta y variacion_porcentual NULL
--    CON_DATOS_Q1  => margen_q1 y variacion_absoluta con valor
--    ESPERADO: 0
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS filas_incoherentes
FROM tmp_reporte
WHERE (indicador_q1 = 'SIN_DATOS_Q1'
       AND (margen_q1 IS NOT NULL OR variacion_absoluta IS NOT NULL OR variacion_porcentual IS NOT NULL))
   OR (indicador_q1 = 'CON_DATOS_Q1'
       AND (margen_q1 IS NULL OR variacion_absoluta IS NULL));

-- ---------------------------------------------------------------------
-- 8. Cobertura: regiones presentes en el reporte
--    ESPERADO: Centro, Noreste, Occidente y Sureste (4 filas)
-- ---------------------------------------------------------------------
SELECT region, COUNT(*) AS productos_en_top5,
       SUM(indicador_q1 = 'SIN_DATOS_Q1') AS productos_sin_datos_q1
FROM tmp_reporte
GROUP BY region
ORDER BY region;

-- Limpieza
DROP TEMPORARY TABLE IF EXISTS tmp_reporte;