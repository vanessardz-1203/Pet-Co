USE PETCO_DATAMART;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_top5_rentabilidad_region$$

CREATE PROCEDURE sp_top5_rentabilidad_region(
    IN p_anio      INT,
    IN p_trimestre INT
)
READS SQL DATA
BEGIN
    DECLARE v_anio_anterior INT;
    DECLARE v_trim_anterior INT;

    -- 1) Validación de parámetros
    IF p_anio IS NULL OR p_trimestre IS NULL OR p_trimestre NOT BETWEEN 1 AND 4 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Parametros invalidos: p_anio no puede ser NULL y p_trimestre debe estar entre 1 y 4';
    END IF;

    -- 2) Periodo anterior (el trimestre 1 se compara con el 4 del año previo)
    IF p_trimestre = 1 THEN
        SET v_anio_anterior = p_anio - 1;
        SET v_trim_anterior = 4;
    ELSE
        SET v_anio_anterior = p_anio;
        SET v_trim_anterior = p_trimestre - 1;
    END IF;

    -- 3) Reporte
    WITH ventas_actual AS (
        -- Margen acumulado por región y producto en el periodo solicitado
        SELECT ti.region,
               f.producto_key,
               SUM(f.margen) AS margen_actual
        FROM FACT_VENTAS f
        JOIN DIM_TIEMPO  t  ON t.fecha_key   = f.fecha_key
        JOIN DIM_TIENDA  ti ON ti.tienda_key = f.tienda_surtido_key
        WHERE t.anio = p_anio
          AND t.trimestre = p_trimestre
        GROUP BY ti.region, f.producto_key
    ),
    ventas_anterior AS (
        -- Margen acumulado por región y producto en el periodo anterior
        SELECT ti.region,
               f.producto_key,
               SUM(f.margen) AS margen_anterior
        FROM FACT_VENTAS f
        JOIN DIM_TIEMPO  t  ON t.fecha_key   = f.fecha_key
        JOIN DIM_TIENDA  ti ON ti.tienda_key = f.tienda_surtido_key
        WHERE t.anio = v_anio_anterior
          AND t.trimestre = v_trim_anterior
        GROUP BY ti.region, f.producto_key
    ),
    ranking_actual AS (
        -- Posición dentro de cada región según el margen del periodo solicitado
        SELECT region,
               producto_key,
               margen_actual,
               ROW_NUMBER() OVER (
                   PARTITION BY region
                   ORDER BY margen_actual DESC, producto_key ASC
               ) AS posicion
        FROM ventas_actual
    ),
    top5_actual AS (
        SELECT region, producto_key, margen_actual, posicion
        FROM ranking_actual
        WHERE posicion <= 5
    )
    SELECT r.region                                   AS region,
           r.posicion                                 AS posicion_top5,
           r.producto_key                             AS producto_key,
           p.nombre                                   AS nombre_producto,
           a.margen_anterior                          AS margen_periodo_anterior,
           r.margen_actual                            AS margen_periodo_actual,
           CASE WHEN a.producto_key IS NULL
                THEN NULL
                ELSE r.margen_actual - a.margen_anterior
           END                                        AS variacion_absoluta,
           CASE WHEN a.producto_key IS NULL
                  OR a.margen_anterior = 0
                THEN NULL
                ELSE ROUND((r.margen_actual - a.margen_anterior) / a.margen_anterior * 100, 2)
           END                                        AS variacion_porcentual,
           CASE WHEN a.producto_key IS NULL
                THEN 'SIN_DATOS_PERIODO_ANTERIOR'
                ELSE 'CON_DATOS_PERIODO_ANTERIOR'
           END                                        AS indicador_periodo_anterior
    FROM top5_actual r
    JOIN DIM_PRODUCTO p
      ON p.producto_key = r.producto_key
    LEFT JOIN ventas_anterior a
      ON  a.region       = r.region
      AND a.producto_key = r.producto_key
    ORDER BY r.region, r.posicion;
END$$

DELIMITER ;

-- pruebas

-- Prueba principal: Q2 2026 contra Q1 2026.
-- Debe devolver el mismo contenido que en consulta
CALL sp_top5_rentabilidad_region(2026, 2);

-- Caso límite: Q1 2026. Su periodo anterior es Q4 de 2025, que no tiene ventas
-- en la base, así que todas las filas deben marcarse SIN_DATOS_PERIODO_ANTERIOR.
CALL sp_top5_rentabilidad_region(2026, 1);

-- Caso sin datos: Q3 2026 no tiene ventas cargadas; debe devolver 0 filas.
CALL sp_top5_rentabilidad_region(2026, 3);
