USE PETCO_DATAMART;

EXPLAIN analyze

WITH margenes AS (
    SELECT
        ti.region,
        f.producto_key,

        SUM(
            CASE
                WHEN t.trimestre = 1 THEN f.margen
                ELSE 0
            END
        ) AS margen_q1,

        SUM(
            CASE
                WHEN t.trimestre = 2 THEN f.margen
                ELSE 0
            END
        ) AS margen_q2,

        SUM(
            CASE
                WHEN t.trimestre = 1 THEN 1
                ELSE 0
            END
        ) AS ventas_q1,

        SUM(
            CASE
                WHEN t.trimestre = 2 THEN 1
                ELSE 0
            END
        ) AS ventas_q2

    FROM FACT_VENTAS f

    JOIN DIM_TIEMPO t
        ON t.fecha_key = f.fecha_key

    JOIN DIM_TIENDA ti
        ON ti.tienda_key = f.tienda_surtido_key

    WHERE t.anio = 2026
      AND t.trimestre IN (1, 2)

    GROUP BY
        ti.region,
        f.producto_key
),

ranking_q2 AS (
    SELECT
        region,
        producto_key,
        margen_q1,
        margen_q2,
        ventas_q1,

        ROW_NUMBER() OVER (
            PARTITION BY region
            ORDER BY margen_q2 DESC, producto_key ASC
        ) AS posicion

    FROM margenes

    WHERE ventas_q2 > 0
)

SELECT
    r.region,
    r.posicion AS posicion_top5,
    r.producto_key,
    p.nombre AS nombre_producto,

    CASE
        WHEN r.ventas_q1 = 0 THEN NULL
        ELSE r.margen_q1
    END AS margen_q1_2026,

    r.margen_q2 AS margen_q2_2026,

    CASE
        WHEN r.ventas_q1 = 0 THEN NULL
        ELSE r.margen_q2 - r.margen_q1
    END AS variacion_absoluta,

    CASE
        WHEN r.ventas_q1 = 0
          OR r.margen_q1 = 0
        THEN NULL
        ELSE ROUND(
            (r.margen_q2 - r.margen_q1)
            / r.margen_q1 * 100,
            2
        )
    END AS variacion_porcentual,

    CASE
        WHEN r.ventas_q1 = 0 THEN 'SIN_DATOS_Q1'
        ELSE 'CON_DATOS_Q1'
    END AS indicador_q1

FROM ranking_q2 r

JOIN DIM_PRODUCTO p
    ON p.producto_key = r.producto_key

WHERE r.posicion <= 5

ORDER BY
    r.region,
    r.posicion;
