-- **************************************************
-- PROCESOS PARA UN CLIENTE
-- **************************************************

-- ------------------------------------------------------------
-- Ver productos con precios 
-- ------------------------------------------------------------
-- (a cada cliente le muestra los precios según su lista)

SET @cliente = 2;
SELECT * FROM productos_con_precios WHERE lista = fn_generar_variable_lista(@cliente);

-- ------------------------------------------------------------
-- Hacer un pedido
-- ------------------------------------------------------------

-- 1) Vemos la tabla detalle de pedidos para después comparar

SELECT * FROM DETALLE_PEDIDOS;

-- 2) Hacemos correr el procedure
-- Argumentos (IDcliente, JSON con pedido {IDproducto, cantidad})

CALL sp_generar_pedidos (3,'[{"producto":8,"cantidad":2},{"producto":5,"cantidad":10},{"producto":4,"cantidad":3}]');

-- 3) Ver el pedido recien creado 

SET @cliente = 3;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- 4) Volvemos a ver la tabla detalle de pedidos, ahora actualizada con el pedido nuevo
SELECT * FROM DETALLE_PEDIDOS;

-- 5) Para probar diferentes causas de error

-- 5.a Json vacío
CALL sp_generar_pedidos (7, '[]');
-- 5.b Json con objetos vacíos
CALL sp_generar_pedidos (7, '[{},{}]');
-- 5.c Varios productos, uno de los cuales tiene cantidad 0
CALL sp_generar_pedidos (9, '[{"producto":7,"cantidad":0},{"producto":8,"cantidad":3},{"producto":4,"cantidad":20},{"producto":3,"cantidad":5}]');

-- 5.d Todos los objetos tienen errores: el primero tiene un producto que no existe, el segundo tiene cantidad 0 y el tercero es un producto con stock 0
CALL sp_generar_pedidos (9, '[{"producto":25,"cantidad":1},{"producto":6,"cantidad":0},{"producto":1,"cantidad":9}]');

-- ---------------------------------------------------------------------------------
-- Hacer un pedido en que la cantidad de uno de los productos es mayor que el stock
-- ---------------------------------------------------------------------------------
-- 1) Vemos el stock de los productos

SELECT id_producto, nombre, stock FROM PRODUCTOS WHERE id_producto = 5;

-- 2) Hacemos correr el procedure de generar pedidos
-- Argumentos (IDcliente, JSONpedido)

CALL sp_generar_pedidos (2,'[{"producto":5,"cantidad":100}]');

-- Ver el pedido recien generado. El pedido del producto 5 debería tener como máximo la cantidad de productos en stock

SET @cliente = 2;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- Volvemos a ver el stock de los productos, que aun no cambió a pesar de los pedidos, porque recién se modifica cuando el pedido pasa a estado aprobado. (Ver más abajo el código correspondiente a este proceso - linea 144) 

SELECT id_producto, nombre, stock FROM PRODUCTOS;


-- ------------------------------------------------------------
-- Modificar un pedido
-- ------------------------------------------------------------
-- 1) Generamos un pedido nuevo

CALL sp_generar_pedidos (11,'[{"producto":5,"cantidad":1}]');

-- 2) Vemos el detalle del pedido recién generado (si el cliente tiene más de un pedido, el generado recién es el de mayor id)

SET @cliente = 11;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- 3) Hacemos correr el procedure (el id del pedido debe verse en el resultado del select anterior)
-- Argumentos (IDcliente, IDpedido, qty,IDproducto, tipo_modificacion)

CALL sp_modificar_pedido (11,14,3,5,"UPDATE");

-- 4) Ver cambios en detalle de pedido

SET @cliente = 11;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- ------------------------------------------------------------
-- Modificar pedido anterior, agregando un producto nuevo
-- ------------------------------------------------------------

-- 1) Hacemos correr el procedure

-- 1.a) Probamos con un producto que ya existe en el pedido
-- Argumentos (IDcliente, IDpedido, qty,IDproducto, tipo_modificacion)

CALL sp_modificar_pedido (11,14,3,5,"ADD");

-- 1.b) Ahora agregamos un producto que no estaba en el pedido
-- Argumentos (IDcliente, IDpedido, qty,IDproducto, tipo_modificacion)

CALL sp_modificar_pedido (11,14,1,3,"ADD");

-- 2) Vemos nuevamente el detalle del pedido

SET @cliente = 11;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- 3) Tratamos de modificar un pedido que ya estaba aprobado
-- Argumentos (IDcliente, IDpedido, qty,IDproducto, tipo_modificacion)

CALL sp_modificar_pedido (5,2,3,5,"UPDATE");

-- 4) Tratamos de modificar un pedido enviando datos incorrectos
-- 4.a) código de modificación incorrecto
-- Argumentos (IDcliente, IDpedido, qty,IDproducto, tipo_modificacion)

CALL sp_modificar_pedido (11,14,3,5,"MODIFICAR");

-- 4.b) algún valor = 0
-- Argumentos (IDcliente, IDpedido, qty,IDproducto, tipo_modificacion)

CALL sp_modificar_pedido (11,14,0,5,"UPDATE");

-- ------------------------------------------------------------
-- Borrar pedido anterior completo
-- ------------------------------------------------------------
-- Argumentos (IDcliente, IDpedido)

CALL sp_borrar_pedido (11,14);

-- Verificamos que no existe el pedido en la tabla PEDIDOS ni en la tabla DETALLE_PEDIDOS
SELECT * FROM PEDIDOS;
SELECT * FROM DETALLE_PEDIDOS;


-- -----------------------------------------------------------
-- Ver pedido con precios para un cliente determinado
-- -----------------------------------------------------------

SET @cliente = 7;
SET @fecha_pedido = "2024-08-31";
SELECT * FROM pedido_cliente WHERE id_cliente = @cliente AND fecha = @fecha_pedido;

-- Total del pedido

SELECT razon_social,SUM(Total_renglon) AS "Total pedido", SUM(cantidad) AS "Total cantidades" FROM pedido_cliente WHERE id_cliente = @cliente AND fecha = @fecha_pedido GROUP BY id_cliente;


-- **************************************************
-- PROCESOS PARA EL ADMIN DE LA EMPRESA
-- **************************************************

-- ---------------------------------------------------------------------------------
-- Aprobar un pedido (y dar de baja del stock los productos involucrados). 
-- ---------------------------------------------------------------------------------

-- 1) Vemos el detalle del pedido 1, y las cantidades en stock, para comparar después

SELECT dp.*, p.stock FROM DETALLE_PEDIDOS dp INNER JOIN PRODUCTOS p ON dp.fk_id_producto = p.id_producto WHERE dp.fk_id_pedido = 1;

-- 2) Corremos el proceso para aprobar el pedido 1
-- Argumentos (IDpedido, IDempleado)

CALL sp_aprobar_pedido (1,2);

-- 3) Volvemos a ver el stock de los productos

SELECT dp.*, p.stock FROM DETALLE_PEDIDOS dp INNER JOIN PRODUCTOS p ON dp.fk_id_producto = p.id_producto WHERE dp.fk_id_pedido = 1;

-- -----------------------------------------------------------------------
-- Ver pedidos con el detalle de la orden de compra de todos los clientes
-- -----------------------------------------------------------------------

SELECT * FROM pedidos_detallados;

-- -----------------------------------------------------------------------
-- Total de cada cliente para una determinada fecha
-- -----------------------------------------------------------------------

SELECT id_cliente,razon_social, SUM(Total_renglon) AS "Total pedido", SUM(cantidad) AS "Total cantidades" FROM pedido_cliente WHERE fecha = @fecha_pedido GROUP BY id_cliente;


-- ------------------------------------------------------------
-- Ver productos con los precios para cada lista de precios
-- ------------------------------------------------------------
-- En esta vista (que se obtiene desde un SP, las listas de precios aparecen como columnas)

CALL sp_pivot_listas();

-- Comparar con la vista original

SELECT * FROM productos_con_precios;

-- ----------------------------------------------------------------
-- Agregar nueva lista de precios (y precios para algunos productos)
-- ----------------------------------------------------------------

INSERT INTO LISTAS (moneda, nombre, descripcion) VALUES ("ARS","100%","Lista sin descuentos");

INSERT INTO PRECIOS_PRODUCTO (fk_id_producto,fk_id_lista,precio) VALUES 
(1,4,15000),(2,4,20000),(3,4,12000);

-- Volver a llamar al sp de listas de precio para verificar que se agregó la columna

CALL sp_pivot_listas();


-- -----------------------------------------------------------------------------------------
-- Totales de volumen, peso y cantidad de los pedidos aprobados, agrupados por zona y fecha
-- -----------------------------------------------------------------------------------------

SELECT * FROM totales;

-- -----------------------------------------------------------------------------------------
-- Ver cómo se fueron dando las modificaciones de estado de los pedidos 
-- -----------------------------------------------------------------------------------------

SELECT * FROM MODIFICACION_ESTADOS;

-- -----------------------------------------------------------------------------------------
-- Generación del reparto para una determinada zona (enviada al sp como parámetro)
-- -----------------------------------------------------------------------------------------

CALL sp_generar_reparto(2, "2024-08-31");

-- Ver reparto generado
SELECT * FROM REPARTOS;

-- Ver detalle del reparto generado (con el id de los pedidos involucrados)
SELECT * FROM DETALLE_REPARTOS;

-- Generar repartos para otras zonas
CALL sp_generar_reparto(1, "2024-08-31");
CALL sp_generar_reparto(3, "2024-08-31");

-- Ver todos los repartos generados
SELECT * FROM REPARTOS;

-- Ver detalle de todos los repartos
SELECT * FROM DETALLE_REPARTOS;

-- -----------------------------------------------------------------------------------------
-- Insersión del kilometraje inicial o final de un reparto determinado
-- -----------------------------------------------------------------------------------------
-- Los parámetros son: id_reparto, id_chofer, momento del reparto (antes o después), kilometraje que marca el odómetro del vehículo en el momento indicado

CALL sp_cargar_km(4,1, "INI", 200);
CALL sp_cargar_km(4,1, "FIN", 250);

-- Se pueden probar datos erróneos
-- 1) Se trata de insertar un km final menor al inicial

CALL sp_cargar_km(4,1,"FIN",190);

-- 2) Se trata de insertar el km de un reparto con el id del chofer que no hizo el reparto

CALL sp_cargar_km(4,2,"FIN",230);
