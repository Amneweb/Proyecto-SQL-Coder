-- ----------------------------------------
-- VISTA pedidos_detallados
-- ----------------------------------------

-- Vista que muestra el listado de pedidos ordenado por pedido, incluyendo el detalle 'producto - cantidad'
-- Basada en las tablas: PEDIDOS, PRODUCTOS, CLIENTES y DETALLE_PEDIDOS

CREATE OR REPLACE VIEW pedidos_detallados AS
(SELECT c.id_cliente, c.razon_social, p.fecha_pedido, p.id_pedido, d.cantidad, pro.id_producto, pro.sku, pro.nombre FROM CLIENTES c INNER JOIN PEDIDOS p ON c.id_cliente = p.fk_id_cliente INNER JOIN DETALLE_PEDIDOS d ON d.fk_id_pedido = p.id_pedido INNER JOIN PRODUCTOS pro ON d.fk_id_producto=pro.id_producto ORDER BY d.fk_id_pedido);

-- Opciones de SELECT para la vista anterior
-- -------------------------------------------

-- 1) TODOS LOS CLIENTES

-- SELECT * FROM pedidos_detallados;

-- 2) UN CLIENTE (usando una variable)

-- SET @cliente = 2;
-- SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- ----------------------------------------
-- VISTA productos_con_precios
-- ----------------------------------------

-- Vista que muestra todos los productos con sus respectivos precios para las 3 listas de precio existentes
-- Basada en las tablas: PRODUCTOS y PRECIOS_PRODUCTO

CREATE OR REPLACE VIEW productos_con_precios AS 
(SELECT pro.sku as 'sku', pro.nombre as 'nombre', pro.stock as 'stock', pre.precio as 'precio', pre.fk_id_lista as 'lista' FROM PRODUCTOS pro INNER JOIN PRECIOS_PRODUCTO pre ON pro.id_producto = pre.fk_id_producto ORDER BY pro.nombre);

-- Opciones de SELECT para la vista anterior
-- -------------------------------------------

-- 1) TODAS LAS LISTAS (este select sin filtro no tiene mucha aplicacion. Para una mejor presentación de los datos, se usa el SP sp_pivot_listas)

-- SELECT * FROM productos_con_precios;

-- 2) UNA LISTA (en base a la variable id de cliente) Ese filtro se define en base al cliente, a traves de la funcion generar_variable_lista. Esta función podría reemplazarse directamente por una subquery en WHERE, pero de esta manera queda más prolijo.

-- SET @cliente = 2;
-- SELECT * FROM productos_con_precios WHERE lista = fn_generar_variable_lista(@cliente);


-- ----------------------------------------
-- VISTA pedidos_aprobados
-- ----------------------------------------
-- Esta vista reemplaza a la tabla PEDIDOS en lo que a generación de repartos se refiere, ya que contiene sólo los pedidos aprobados.

CREATE OR REPLACE VIEW pedidos_aprobados AS 
(SELECT * FROM PEDIDOS WHERE fk_id_estado = "APR");


-- ----------------------------------------
-- VISTA dimensiones
-- ----------------------------------------

-- La siguiente vista muestra las dimensiones de cada producto y los valores calculados de volumen y peso total por producto para todos los pedidos. Los datos se muestran ordenados por zona. Eventualmente se pueden filtrar por zona y fecha. Más adelante esta vista se usa para calcular los volumenes, pesos y cantidades totales por zona para una fecha determinada.
-- Basada en las tablas: CLIENTES, PEDIDOS, DETALLE_PEDIDOS, PRODUCTOS

CREATE OR REPLACE VIEW dimensiones AS
(SELECT c.fk_zona AS 'zona', p.fecha_pedido AS 'fecha', p.id_pedido, p.fk_id_estado AS 'estado', d.cantidad AS 'qty', pro.sku AS 'SKU', pro.dimension_longitud AS 'longitud', pro.dimension_alto AS 'alto',pro.dimension_ancho AS 'ancho', pro.dimension_peso AS 'peso',fn_volumen_individual(pro.dimension_longitud,pro.dimension_alto,pro.dimension_ancho, d.cantidad) AS 'volumen',fn_peso_individual(pro.dimension_peso, d.cantidad) AS 'peso_total' FROM CLIENTES c INNER JOIN pedidos_aprobados p ON c.id_cliente = p.fk_id_cliente INNER JOIN DETALLE_PEDIDOS d ON d.fk_id_pedido = p.id_pedido INNER JOIN PRODUCTOS pro ON d.fk_id_producto=pro.id_producto ORDER BY c.fk_zona DESC,p.id_pedido ASC);

-- Opciones de SELECT para la vista anterior
-- -------------------------------------------

-- 1) TODOS LOS PEDIDOS

-- SELECT * FROM dimensiones;

-- 2) FILTRADO POR ZONA y FECHA

-- SELECT * FROM dimensiones WHERE zona = 1 AND fecha = "2024-08-31";


-- ---------------------------------------
-- VISTA pedido_cliente
-- ---------------------------------------

-- Para mostrar el pedido al cliente incluyendo los precios de cada producto y el total cantidad*precio
-- Basada en las tablas/vistas: PRECIOS_PRODUCTO, pedidos_detallados

CREATE OR REPLACE VIEW pedido_cliente AS (SELECT pd.id_cliente, pd.razon_social,pd.fecha_pedido AS "fecha", pd.sku, pd.cantidad, pre.precio AS "precio unitario", (pd.cantidad*pre.precio) AS "Total_renglon" FROM pedidos_detallados pd INNER JOIN PRECIOS_PRODUCTO pre ON pre.fk_id_producto = pd.id_producto WHERE pre.fk_id_lista = fn_generar_variable_lista(pd.id_cliente));

-- Se filtra por cliente y fecha

-- SET @cliente = 1;
-- SET @fecha_pedido = "2024-08-31";
-- SELECT * FROM pedido_cliente WHERE id_cliente = @cliente AND fecha = @fecha_pedido;

-- Ver más opciones de resultados obtenidos con esta vista en el archivo snippets


-- ------------------------------------
-- Vista totales
-- ------------------------------------
-- Se obtienen los totales de peso, volumen y cantidad agrupados por zona y por fecha para los pedidos en estado aprobado

CREATE OR REPLACE VIEW totales AS (SELECT zona, fecha, sum(volumen) AS "volumen total", sum(peso_total) AS "peso total", sum(qty) AS "cantidad total" FROM dimensiones GROUP BY fecha, zona order by fecha);


-- ------------------------------------
-- Vista totales por mes
-- ------------------------------------
-- Igual a la anterior pero con las cantidades, pesos y volúmenes agrupados por mes. 

CREATE OR REPLACE VIEW totales_por_mes AS (SELECT zona, MONTHNAME(fecha) as mes, sum(volumen) AS "volumen total", sum(peso_total) AS "peso total", sum(qty) AS "cantidad total" FROM dimensiones GROUP BY mes, zona order by mes);


-- ------------------------------------
-- Vista totales por reparto
-- ------------------------------------
-- SE agrupan los productos de cada reparto para conocer las cantidades de cada uno en un reparto determinado

CREATE OR REPLACE VIEW totales_por_reparto AS (SELECT fk_id_reparto, sku, SUM(cantidad) FROM (SELECT dr.fk_id_reparto, dr.fk_id_pedido, pd.id_cliente, pd.sku, pd.cantidad FROM DETALLE_REPARTOS dr INNER JOIN pedidos_detallados pd ON dr.fk_id_pedido = pd.id_pedido) as detalle GROUP BY fk_id_reparto,sku)


