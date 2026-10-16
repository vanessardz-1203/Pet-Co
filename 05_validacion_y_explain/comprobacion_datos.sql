SELECT COUNT(*) AS total_registros FROM FACT_VENTAS;

SELECT
    t.trimestre,
    COUNT(*) AS total_registros
FROM FACT_VENTAS AS v
JOIN DIM_TIEMPO AS t
    ON v.fecha_key = t.fecha_key
WHERE t.anio = 2026
  AND t.trimestre IN (1, 2)
GROUP BY t.trimestre
ORDER BY t.trimestre;


SELECT
    t.region,
    COUNT(*) AS total_registros
FROM FACT_VENTAS AS v
JOIN DIM_TIENDA AS t
    ON v.tienda_surtido_key = t.tienda_key
GROUP BY t.region
ORDER BY t.region;

SELECT
    MIN(t.fecha) AS primera_venta,
    MAX(t.fecha) AS ultima_venta,
    COUNT(DISTINCT v.fecha_key) AS dias_con_ventas
FROM FACT_VENTAS AS v
JOIN DIM_TIEMPO AS t
    ON v.fecha_key = t.fecha_key
WHERE t.anio = 2026
  AND t.trimestre IN (1, 2);
  
SELECT
    COUNT(*) AS total_registros,
    SUM(importe_bruto IS NULL) AS bruto_nulo,
    SUM(importe_neto IS NULL) AS neto_nulo,
    SUM(margen IS NULL) AS margen_nulo,
    SUM(cantidad IS NULL) AS cantidad_nula
FROM FACT_VENTAS;

SELECT
    COUNT(*) AS registros_incorrectos
FROM FACT_VENTAS
WHERE margen IS NULL
   OR importe_neto IS NULL
   OR importe_bruto IS NULL
   OR ABS(margen - (importe_neto - cantidad*costo_unitario)) > 0.01;
   
SELECT
    SUM(t.fecha_key IS NULL) AS fechas_sin_dimension,
    SUM(p.producto_key IS NULL) AS productos_sin_dimension,
    SUM(s.tienda_key IS NULL) AS tiendas_sin_dimension
FROM FACT_VENTAS AS v
LEFT JOIN DIM_TIEMPO AS t
    ON v.fecha_key = t.fecha_key
LEFT JOIN DIM_PRODUCTO AS p
    ON v.producto_key = p.producto_key
LEFT JOIN DIM_TIENDA AS s
    ON v.tienda_surtido_key = s.tienda_key;
    
