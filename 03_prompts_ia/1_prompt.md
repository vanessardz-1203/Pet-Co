Primer prompt usado para la generación de datos sinteticos
Actúa como un especialista en bases de datos y generación de datos sintéticos para MySQL 8.0.
Estamos trabajando con el Data Mart de ventas de la empresa ficticia Pet&Co, desarrollado durante la Unidad 2 mediante un esquema estrella. Para la Unidad 3 necesitamos generar datos sintéticos que nos permitan realizar consultas analíticas, comprobar la calidad de los datos y responder preguntas de negocio.
La base de datos se llama PETCO_DATAMART y contiene las siguientes tablas:
•	DIM_TIEMPO: información de fechas, años, trimestres y meses.
•	DIM_CLIENTE: información de los clientes.
•	DIM_PRODUCTO: información de los productos comercializados.
•	DIM_TIENDA: información de las tiendas y sus regiones.
•	DIM_CANAL: canales de venta.
•	DIM_PROMOCION: promociones aplicables.
•	DIM_SUSCRIPCION: información de suscripciones.
•	FACT_VENTAS: tabla de hechos que registra las líneas de venta, cantidades, precios, descuentos, importes y márgenes.
El grano de FACT_VENTAS es una línea de venta correspondiente a un producto dentro de un ticket. Un mismo ticket puede contener varios productos.
Necesito que generes un script SQL compatible con MySQL Workbench 8.0 CE para poblar las tablas existentes, respetando sus relaciones, claves primarias, claves foráneas y tipos de datos. No debes modificar la estructura del esquema estrella ni inventar columnas.
Los datos sintéticos deben cumplir las siguientes condiciones:
1.	Generar al menos 1,000 registros en FACT_VENTAS, preferentemente varios miles para realizar pruebas analíticas.
2.	Incluir ventas del primer trimestre de 2026 (enero-marzo) y del segundo trimestre de 2026 (abril-junio).
3.	Incluir al menos tres regiones comerciales. Para este caso, utilizar Centro, Noreste, Occidente y Sureste.
4.	Representar los tres canales de venta: Tienda Física, E-commerce y Click & Collect.
5.	Generar diferentes productos, clientes, tiendas, promociones y suscripciones.
6.	Incluir clientes anónimos mediante cliente_key = -1, ventas sin promoción mediante promocion_key = -1 y compras sin suscripción mediante suscripcion_key = -1, respetando los registros correspondientes de las dimensiones.
7.	Permitir que tienda_entrega_key sea NULL cuando no aplique, sin confundirla con tienda_surtido_key.
8.	Incluir algunos productos que comiencen a venderse en Q2 y que no tengan registros en Q1, para probar los casos sin periodo anterior.
9.	Mantener fechas, cantidades, precios, descuentos, costos e importes coherentes.
10.	Evitar claves foráneas que hagan referencia a registros inexistentes.
11.	Generar datos de manera reproducible, de forma que el script pueda ejecutarse nuevamente siguiendo instrucciones claras.
Los cálculos monetarios deben respetar estas fórmulas:
•	importe_bruto = cantidad * precio_unitario
•	importe_neto = importe_bruto - descuento
•	margen = importe_neto - (cantidad * costo_unitario)
Considera que el margen representa la ganancia monetaria de la línea de venta después del descuento y del costo de los productos.
No agregues indicadores de devoluciones o cancelaciones, porque actualmente el modelo no dispone de campos específicos para identificarlas.
Entrega el script SQL completo, organizado por etapas: preparación, generación de dimensiones, generación de ventas, cálculo de importes e inserción en la tabla de hechos.
Explica brevemente la finalidad de cada etapa y señala cualquier supuesto necesario antes de generar los datos.
