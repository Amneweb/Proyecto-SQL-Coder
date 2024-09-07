-- ----------------------------------------
-- VISTA pedidos_detallados
-- ----------------------------------------

-- Vista que muestra el listado de pedidos ordenado por pedido, incluyendo el detalle 'producto - cantidad'
-- Combina las tablas PEDIDOS, PRODUCTOS, CLIENTES y DETALLE_PEDIDOS

CREATE OR REPLACE VIEW pedidos_detallados AS
(SELECT c.id_cliente, c.razon_social, p.fecha_pedido, p.id_pedido, d.cantidad, pro.sku, pro.nombre FROM CLIENTES c INNER JOIN PEDIDOS p ON c.id_cliente = p.fk_id_cliente INNER JOIN DETALLE_PEDIDOS d ON d.fk_id_pedido = p.id_pedido INNER JOIN PRODUCTOS pro ON d.fk_id_producto=pro.id_producto ORDER BY d.fk_id_pedido);

-- Opciones de SELECT para la vista anterior
-- -------------------------------------------

-- 1) TODOS LOS CLIENTES
SELECT * FROM pedidos_detallados;

-- 2) UN CLIENTE (usando una variable)
SET @cliente = 2;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- ----------------------------------------
-- VISTA productos_con_precios
-- ----------------------------------------

-- Vista que muestra todos los productos con sus respectivos precios para las 3 listas de precio existentes
-- Involucra las tablas PRODUCTOS y PRECIOS_PRODUCTO

CREATE OR REPLACE VIEW productos_con_precios AS 
(SELECT pro.sku as 'sku', pro.nombre as 'nombre', pro.stock as 'stock', pre.precio as 'precio', pre.fk_id_lista as 'lista' FROM PRODUCTOS pro INNER JOIN PRECIOS_PRODUCTO pre ON pro.id_producto = pre.fk_id_producto ORDER BY pro.nombre);

-- Opciones de SELECT para la vista anterior
-- -------------------------------------------

-- 1) TODAS LAS LISTAS (el select sin filtro no tiene mucha aplicacion. La vista que sigue es una adaptacion de esta en la que quedan mejor presentados los datos)
SELECT * FROM productos_con_precios;
-- 2) UNA LISTA (en base a la variable id de cliente) Ese filtro se define en base al cliente, a traves de la funcion generar_variable_lista
SET @cliente = 2;
SELECT * FROM productos_con_precios WHERE lista = fn_generar_variable_lista(@cliente);

-- ----------------------------------------
-- VISTA pivot_productos_con_precios
-- ----------------------------------------

-- La siguiente vista es igual a la anterior pero cada lista de precios pasa a ser una columna y no se repiten filas.
-- NOTA: el select que sigue, que traspone la tabla, es un poco "trucho" porque si en el futuro alguien quiere agregar una nueva lista, debería modificar también este select. Hay que mejorarlo. Para hacer eso, se usa el SP sp_pivot_listas 

CREATE OR REPLACE VIEW pivot_productos_con_precios AS
(SELECT sku, nombre,
MAX(CASE WHEN lista = 1 THEN precio END) AS Lista_1,
MAX(CASE WHEN lista = 2 THEN precio END) AS Lista_2,
MAX(CASE WHEN lista = 3 THEN precio END) AS Lista_3
FROM (SELECT pro.sku as 'sku', pro.nombre as 'nombre', pro.stock as 'stock', pre.precio as 'precio', pre.fk_id_lista as 'lista' FROM PRODUCTOS pro INNER JOIN PRECIOS_PRODUCTO pre ON pro.id_producto = pre.fk_id_producto ORDER BY pro.nombre) as productos_con_precio
GROUP BY sku);

SELECT * FROM pivot_productos_con_precios;


-- ----------------------------------------
-- VISTA dimensiones
-- ----------------------------------------

-- La siguiente vista muestra las dimensiones de cada producto y los valores calculados de volumen y peso total por producto para un pedido determinado. Los datos se muestran ordenados por zona.

CREATE OR REPLACE VIEW dimensiones AS
(SELECT c.fk_zona AS 'zona', p.fecha_pedido AS 'fecha', p.id_pedido, d.cantidad AS 'qty', pro.sku AS 'SKU', pro.dimension_longitud AS 'longitud', pro.dimension_alto AS 'alto',pro.dimension_ancho AS 'ancho', pro.dimension_peso AS 'peso',fn_volumen_individual(pro.dimension_longitud,pro.dimension_alto,pro.dimension_ancho, d.cantidad) AS 'volumen',fn_peso_individual(pro.dimension_peso, d.cantidad) AS 'peso_total' FROM CLIENTES c INNER JOIN PEDIDOS p ON c.id_cliente = p.fk_id_cliente INNER JOIN DETALLE_PEDIDOS d ON d.fk_id_pedido = p.id_pedido INNER JOIN PRODUCTOS pro ON d.fk_id_producto=pro.id_producto ORDER BY c.fk_zona DESC,p.id_pedido ASC);

SELECT * FROM dimensiones;

SELECT * FROM dimensiones WHERE zona = 1;

-- ----------------------------------------
-- VISTA totales_por_fecha
-- ----------------------------------------

-- La siguiente vista muestra, para una fecha dada, los totales de volumen, cantidad y peso de cada pedido, y se agrupan por zona.

CREATE OR REPLACE VIEW totales_por_fecha AS (SELECT zona, fecha, sum(volumen) AS 'volumen total', sum(peso_total) AS 'peso total', sum(qty) AS 'cantidad total' FROM dimensiones WHERE fecha='2024-08-31' GROUP BY zona);

SELECT * FROM totales_por_fecha;

