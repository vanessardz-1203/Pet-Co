-- DROP DATABASE PETCO_DATAMART;

-- Error intencional
SELECT
    ti.region,
    f.producto_key,
    SUM(f.margen) AS margen_total
FROM FACT_VENTAS AS f
JOIN DIM_TIENDA AS ti
    ON f.tienda_surtido_key = ti.tienda_key
GROUP BY ti.region;

-- Error corregido
SELECT
    ti.region,
    f.producto_key,
    SUM(f.margen) AS margen_total
FROM FACT_VENTAS AS f
JOIN DIM_TIENDA AS ti
    ON f.tienda_surtido_key = ti.tienda_key
GROUP BY
    ti.region,
    f.producto_key
ORDER BY
    ti.region,
    margen_total DESC;