
-- ==========================================================
-- PET&CO | Tercera versión
-- Optimización propuesta: filtrado directo por fecha_key

USE PETCO_DATAMART;

EXPLAIN ANALYZE

WITH margen_q2 AS (

    SELECT
        ti.region,
        f.producto_key,
        SUM(f.margen) AS margen_q2

    FROM FACT_VENTAS f

    JOIN DIM_TIENDA ti
        ON ti.tienda_key = f.tienda_surtido_key

    WHERE f.fecha_key BETWEEN 20260401 AND 20260630

    GROUP BY ti.region, f.producto_key
),

margen_q1 AS (

    SELECT
        ti.region,
        f.producto_key,
        SUM(f.margen) AS margen_q1

    FROM FACT_VENTAS f

    JOIN DIM_TIENDA ti
        ON ti.tienda_key = f.tienda_surtido_key

    WHERE f.fecha_key BETWEEN 20260101 AND 20260331

    GROUP BY ti.region, f.producto_key
),

ranking_q2 AS (

    SELECT
        region,
        producto_key,
        margen_q2,

        ROW_NUMBER() OVER (
            PARTITION BY region
            ORDER BY margen_q2 DESC, producto_key ASC
        ) AS posicion

    FROM margen_q2
),

top5_q2 AS (

    SELECT
        region,
        producto_key,
        margen_q2,
        posicion

    FROM ranking_q2

    WHERE posicion <= 5
)

SELECT
    r.region,
    r.posicion AS posicion_top5,
    r.producto_key,
    p.nombre AS nombre_producto,

    q1.margen_q1 AS margen_q1_2026,
    r.margen_q2 AS margen_q2_2026,

    CASE
        WHEN q1.producto_key IS NULL
        THEN NULL
        ELSE r.margen_q2 - q1.margen_q1
    END AS variacion_absoluta,

    CASE
        WHEN q1.producto_key IS NULL
          OR q1.margen_q1 = 0
        THEN NULL
        ELSE ROUND(
            (r.margen_q2 - q1.margen_q1)
            / q1.margen_q1 * 100,
            2
        )
    END AS variacion_porcentual,

    CASE
        WHEN q1.producto_key IS NULL
        THEN 'SIN_DATOS_Q1'
        ELSE 'CON_DATOS_Q1'
    END AS indicador_q1

FROM top5_q2 r

JOIN DIM_PRODUCTO p
    ON p.producto_key = r.producto_key

LEFT JOIN margen_q1 q1
    ON q1.region = r.region
   AND q1.producto_key = r.producto_key

ORDER BY r.region, r.posicion;
