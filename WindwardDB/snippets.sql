-- Ver productos con precios (a cada cliente le muestra los precios según su lista)

SET @cliente = 2;
SELECT * FROM productos_con_precios WHERE lista = fn_generar_variable_lista(@cliente);

-- Hacer un pedido. El primer argumento del procedure es el id del cliente y el segundo es el json producto-cantidad. Conviene primero ver la tabla pedidos para despues poder comparar.

CALL sp_generar_pedidos (3,'[{"producto":1,"cantidad":2},{"producto":2,"cantidad":10},{"producto":4,"cantidad":3}]');

-- Ver el pedido recien creado 

SET @cliente = 3;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- Hacer un pedido en que la cantidad de uno de los productos es mayor que el stock

CALL sp_generar_pedidos (2,'[{"producto":5,"cantidad":40}]');

-- Ver el pedido recien generado 

SET @cliente = 2;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- Ver pedidos con el detalle de la orden de compra de todos los clientes

SELECT * FROM pedidos_detallados;

-- Ver pedidos con el detalle de la orden de compra de un cliente en particular

SET @cliente = 2;
SELECT * FROM pedidos_detallados WHERE id_cliente = @cliente;

-- Lista de productos con los precios de cada lista de precios

SELECT * FROM pivot_productos_con_precios;

-- Totales de volumen, peso y cantidad de los pedidos del dia 2024-08-31, agrupados por zona

SELECT * FROM totales_por_fecha;

-- Aprobar un pedido (y dar de baja del stock los productos involucrados). En este caso conviene primero ver la tabla productos para ver el stock de los mismos y comparar el stock despues de correr el procedimiento para aprobar pedido

CALL sp_aprobar_pedido (5,2);

-- Ver productos y precios por lista

CALL sp_pivot_listas ();

-- Insertar una 4ta lista, para ver como funciona el procedure sp_pivot_listas

INSERT INTO LISTAS (moneda, nombre, descripcion) VALUES ("ARS","100%","Lista sin descuentos");

-- Insertar precios para esa nueva lista

INSERT INTO PRECIOS_PRODUCTO (fk_id_producto,fk_id_lista,precio) VALUES 
(1,4,15000),(2,4,20000),(3,4,12000);

-- Volver a llamar al sp de listas de precio para verificar que se agregó la columna

CALL sp_pivot_listas ();
