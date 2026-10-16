Tercer prompt utilizado para optimización
Actúa como un especialista en SQL y optimización de consultas en MySQL 8.0.
Estoy trabajando con un Data Mart de ventas llamado PETCO_DATAMART para una empresa ficticia llamada Pet&Co.
Actualmente tengo una consulta que obtiene los 5 productos más rentables por región durante el segundo trimestre de 2026 (Q2), comparando su margen de ganancia con el primer trimestre (Q1).
La consulta utiliza las tablas FACT_VENTAS, DIM_TIEMPO, DIM_TIENDA y DIM_PRODUCTO. Actualmente se realiza un JOIN con DIM_TIEMPO para filtrar el año y el trimestre.
Quiero probar una alternativa de optimización que elimine el JOIN con DIM_TIEMPO y filtre directamente desde FACT_VENTAS, aprovechando que el campo fecha_key almacena fechas como números enteros en formato AAAAMMDD.
Utiliza los siguientes rangos:
•	Q1 2026: 20260101 a 20260331.
•	Q2 2026: 20260401 a 20260630.
Genera el código SQL completo, compatible con MySQL Workbench 8.0 CE, y explica brevemente qué cambio se realizó y por qué podría mejorar el rendimiento. No supongas que la optimización será más rápida sin comprobar los tiempos de ejecución.
