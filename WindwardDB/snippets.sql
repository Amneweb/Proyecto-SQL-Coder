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

CALL sp_generar_pedidos (3,'[{"producto":1,"cantidad":2},{"producto":2,"cantidad":10},{"producto":4,"cantidad":3}]');

-- 3) Ver el pedido recien creado 

SET @cliente = 3;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- 4) Volvemos a ver la tabla detalle de pedidos, ahora actualizada con el pedido nuevo
SELECT * FROM DETALLE_PEDIDOS;

-- ---------------------------------------------------------------------------------
-- Hacer un pedido en que la cantidad de uno de los productos es mayor que el stock
-- ---------------------------------------------------------------------------------
-- 1) Vemos el stock de los productos

SELECT id_producto, nombre, stock FROM PRODUCTOS;

-- 2) Hacemos correr el procedure de generar pedidos
-- Argumentos (IDcliente, JSONpedido)

CALL sp_generar_pedidos (2,'[{"producto":5,"cantidad":100}]');

-- Ver el pedido recien generado. El pedido del producto 5 debería tener como máximo la cantidad de productos en stock

SET @cliente = 2;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- Volvemos a ver el stock de los productos, que aun no cambió a pesar de los pedidos, porque recién se modifica cuando el pedido pasa a estado aprobado. (Ver más abajo el código correspondiente a este proceso - linea 94) 

SELECT id_producto, nombre, stock FROM PRODUCTOS;

-- ------------------------------------------------------------
-- Modificar pedido 4, cambiando la cantidad del producto 2.
-- ------------------------------------------------------------
-- 1) Vemos el detalle del pedido actual

SET @cliente = 8;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- 2) Hacemos correr el procedure.
-- Argumentos (IDcliente, IDpedido, qty,IDproducto, tipo_modificacion)

CALL sp_modificar_pedido (8,4,3,2,"UPDATE");

-- 3) Ver cambios en detalle de pedido

SET @cliente = 8;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- ------------------------------------------------------------
-- Modificar pedido 4, agregando un producto nuevo
-- ------------------------------------------------------------

-- 1) Hacemos correr el procedure
-- Argumentos (IDcliente, IDpedido, qty,IDproducto, tipo_modificacion)
-- 1.a) Probamos con un producto que ya existe en el pedido

CALL sp_modificar_pedido (8,4,1,2,"ADD");

-- 1.b) Ahora agregamos un producto que no estaba en el pedido

CALL sp_modificar_pedido (8,4,1,3,"ADD");

-- 2) Vemos nuevamente el detalle del pedido

SET @cliente = 8;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- 3) Tratamos de modificar un pedido que ya estaba aprobado

CALL sp_modificar_pedido (1,1,3,5,"UPDATE");


-- ------------------------------------------------------------
-- Borrar pedido 4 completo
-- ------------------------------------------------------------
-- Argumentos (IDcliente, IDpedido)

CALL sp_borrar_pedido (8,4);

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

SELECT razon_social,SUM(Total_renglon) AS "Total pedido" FROM pedido_cliente WHERE id_cliente = @cliente AND fecha = @fecha_pedido GROUP BY id_cliente;


-- **************************************************
-- PROCESOS PARA EL ADMIN DE LA EMPRESA
-- **************************************************

-- ---------------------------------------------------------------------------------
-- Aprobar el pedido con id 5 (y dar de baja del stock los productos involucrados). 
-- ---------------------------------------------------------------------------------
-- 1) Vemos el detalle del pedido 5, y las cantidades en stock, para comparar

SELECT dp.*, p.stock FROM DETALLE_PEDIDOS dp INNER JOIN PRODUCTOS p ON dp.fk_id_producto = p.id_producto WHERE dp.fk_id_pedido = 5;

-- 2) Corremos el proceso para aprobar el pedido 5
-- Argumentos (IDpedido, IDempleado)

CALL sp_aprobar_pedido (5,2);

-- 3) Volvemos a ver el stock de los productos

SELECT dp.*, p.stock FROM DETALLE_PEDIDOS dp INNER JOIN PRODUCTOS p ON dp.fk_id_producto = p.id_producto WHERE dp.fk_id_pedido = 5;

-- -----------------------------------------------------------------------
-- Ver pedidos con el detalle de la orden de compra de todos los clientes
-- -----------------------------------------------------------------------

SELECT * FROM pedidos_detallados;

-- -----------------------------------------------------------------------
-- Total de cada pedido para una determinada fecha
-- -----------------------------------------------------------------------

SELECT id_cliente,razon_social, SUM(Total_renglon) AS "Total pedido" FROM pedido_cliente WHERE fecha = @fecha_pedido GROUP BY id_cliente;

-- ------------------------------------------------------------
-- Ver productos con los precios para cada lista de precios
-- ------------------------------------------------------------

CALL sp_pivot_listas();

-- ----------------------------------------------------------------
-- Agregar nueva lista de precios (y precios para algunos productos)
-- ----------------------------------------------------------------

INSERT INTO LISTAS (moneda, nombre, descripcion) VALUES ("ARS","100%","Lista sin descuentos");

INSERT INTO PRECIOS_PRODUCTO (fk_id_producto,fk_id_lista,precio) VALUES 
(1,4,15000),(2,4,20000),(3,4,12000);

-- Volver a llamar al sp de listas de precio para verificar que se agregó la columna

CALL sp_pivot_listas();


-- -----------------------------------------------------------------------------------------
-- Totales de volumen, peso y cantidad de los pedidos del dia 2024-08-31, agrupados por zona
-- -----------------------------------------------------------------------------------------

SELECT * FROM totales_por_fecha;

-- -----------------------------------------------------------------------------------------
-- Modificaciones de estado de los pedidos
-- -----------------------------------------------------------------------------------------

SELECT * FROM MODIFICACION_ESTADOS;

