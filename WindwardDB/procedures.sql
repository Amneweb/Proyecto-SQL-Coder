-- --------------------------------------
-- TRIGGER add_new_pedido
-- --------------------------------------

-- Este trigger es para tomar el id generado al momento de cargar un pedido (como el id es autoincremental y se genera automáticamente, no lo sabemos de antemano, y me pareció que esta era una buena manera de obtenerlo y asegurarme de que sea el id que se genera en la misma conexión, cosa que no ocurriría haciendo un select del ultimo id generado porque si justo hubo un cliente que generó un pedido un segundo después, el select me devolvería un id de otro cliente)

CREATE TRIGGER `tr_add_new_pedido`
AFTER INSERT ON `PEDIDOS`
FOR EACH ROW
SET @idNuevoPedido = NEW.id_pedido;

-- --------------------------------------
-- SP sp_generar_pedidos
-- --------------------------------------

-- Este SP es para agregar los productos y las respectivas cantidades a la tabla detalle de pedidos, y toma como dato el id generado en la tabla PEDIDOS, que lo recupero con el trigger anterior. Los datos de entrada son:
-- 1) El id del cliente
-- 2) Un json con los productos y las cantidades
-- Los pasos del SP son:
-- 1) Inserta el pedido en la tabla PEDIDOS, con el id del cliente, el estado del pedido que en este caso es "HEC" (hecho), y las fechas del pedido y programadasa de entrega
-- 2) Una vez insertado el pedido, el trigger devuelve el nuevo id del pedido
-- 3) Convierte los datos del json en una tabla provisoria
-- 4) Guarda los datos de la tabla provisoria junto con el id del pedido en la tabla detalle de pedidos
-- 5) Justo antes del insert en la tabla detalle de pedidos, se dispara el trigger de verificación de stock, para no generar pedidos con más cantidades de las existentes. Si de un producto se pide una cantidad mayor al stock, el trigger hace que la cantidad guardada en el pedido sea igual al stock.
-- 6) Borra la tabla provisoria y devuelve los mensajes de alerta generados por el trigger

DELIMITER $$
CREATE PROCEDURE `sp_generar_pedidos` (IN id_cliente INT, IN json_pedido JSON)
BEGIN
INSERT INTO PEDIDOS (fk_id_cliente, fk_id_estado, fecha_pedido, fecha_entrega, fecha_efectiva_entrega)
VALUES (id_cliente, "HEC", CURDATE(),CURDATE(),NULL);
CREATE TABLE detalle_provisorio 
(producto INT NOT NULL,
cantidad INT NOT NULL);
INSERT INTO detalle_provisorio (producto, cantidad) SELECT * FROM JSON_TABLE(json_pedido,"$[*]" COLUMNS (
    fk_id_producto INT PATH "$.producto", cantidad INT PATH "$.cantidad"
)) AS detalles_json;

    INSERT INTO DETALLE_PEDIDOS (fk_id_producto, cantidad,fk_id_pedido ) (SELECT producto, cantidad, @idNuevoPedido FROM detalle_provisorio );
	SELECT @msj;
DROP TABLE detalle_provisorio;
END $$

-- --------------------------------------
-- SP sp_borrar_pedido
-- --------------------------------------

-- SP que permite que un cliente borre un pedido completo. Se utiliza el control de errores mostrado en clase como ejemplo.
-- Como hay integridad de datos entre las tablas PEDIDO y DETALLE_PEDIDOS, al borrar un pedido se borran los registros correspondientes en la tabla detalle de pedidos
-- Los parámetros de entrada son los id de cliente y pedido. Se verifica que existan los correspondientes cliente y pedido y que el pedido le pertenezca al cliente.

DELIMITER $$
CREATE PROCEDURE `sp_borrar_pedido` (IN IDcliente INT, IN IDpedido INT)
BEGIN
IF (IDcliente = 0 OR IDpedido = 0) THEN
		SET @err = 'ni el id del cliente ni el id del pedido deben ser 0';
        SELECT @err;
        ELSE
		SET @err = '';
		IF NOT EXISTS
        (SELECT id_cliente from CLIENTES WHERE id_cliente = IDcliente) THEN
			SET @err = CONCAT('No existe el cliente con ID ', IDcliente);
        	END IF;
            IF NOT EXISTS
        (SELECT id_pedido from PEDIDOS WHERE id_pedido = IDpedido) THEN
			SET @err = CONCAT('No existe el pedido con ID ', IDpedido);
        	END IF;
        	IF NOT EXISTS
            (SELECT id_pedido from PEDIDOS WHERE (id_pedido = IDpedido AND fk_id_cliente = IDcliente)) THEN
			SET @err = CONCAT('El pedido con id ', IDpedido, ' no corresponde al cliente con id ',IDcliente);
        	END IF;
        	IF @err != '' THEN
			SELECT @err;
		ELSE
			DELETE FROM PEDIDOS WHERE id_pedido = IDpedido;
		END IF;
	END IF;
END $$

-- --------------------------------------
-- SP sp_aprobar_pedido
-- --------------------------------------

-- SP que modifica el estado del pedido, pasandolo a aprobado y dando de baja las cantidades de stock de cada producto segun la orden de pedidos del cliente. Luego de la modificacion se agrega un registro a la tabla MODIFICACION_ESTADOS.
-- Los parámetros de entrada son los id de empleado y pedido.

DROP PROCEDURE IF EXISTS sp_aprobar_pedido;
DELIMITER $$
CREATE PROCEDURE `sp_aprobar_pedido` (IN idpedido INT, IN idempleado INT)
BEGIN
DECLARE i INT;
DECLARE n INT;
set @IDpedido = idpedido;
set @EstadoPedido = (SELECT fk_id_estado FROM PEDIDOS WHERE id_pedido = @IDpedido);
IF (@EstadoPedido != "APR") THEN 
UPDATE PEDIDOS SET fk_id_estado = "APR" WHERE id_pedido = @IDpedido;
INSERT INTO MODIFICACION_ESTADOS (fk_id_pedido,fk_id_empleado,hora_modificacion,fk_id_estado,fk_id_estado_anterior) VALUES (idpedido,idempleado,CURRENT_TIMESTAMP(),"APR", @estadoAnterior);
DROP TABLE IF EXISTS stock_temporal;
CREATE TABLE stock_temporal (SELECT fk_id_producto AS IDproducto, cantidad FROM DETALLE_PEDIDOS WHERE fk_id_pedido = @IDpedido);
SET n = (SELECT COUNT(*) FROM stock_temporal);
SET i=0;
WHILE i < n DO
SET @id_pedido_i = (SELECT IDproducto FROM stock_temporal LIMIT i,1);
UPDATE PRODUCTOS
SET stock = stock - (SELECT cantidad FROM stock_temporal LIMIT i,1) 
WHERE id_producto = @id_pedido_i;
SET i = i + 1;
END WHILE;
DROP TABLE stock_temporal;
ELSE
SET @msj = "El pedido ya estaba aprobado";
SELECT @msj;
END IF;
END $$

-- --------------------------------------
-- TRIGGER tr_verificar_stock
-- --------------------------------------

-- Este trigger es disparado justo antes de agregar un pedido a la tabla DETALLE_PEDIDOS. Para cada producto, verifica que la cantidad solicitada sea menor o igual a las existencias en stock. Si se solicitan más productos de los que hay en stock, en el pedido sólo se carga lo que hay en stock.

DELIMITER $$
CREATE TRIGGER `tr_verificar_stock`
BEFORE INSERT ON DETALLE_PEDIDOS
FOR EACH ROW
BEGIN
SET @msj = '';
SET @stock_existente = (SELECT stock FROM PRODUCTOS WHERE id_producto = NEW.fk_id_producto);
IF NEW.cantidad > @stock_existente THEN
SET NEW.cantidad = @stock_existente;
SET @msj="Las cantidades solicitadas de uno o varios de los productos es mayor al stock disponible. En esos casos el pedido se armo con el stock existente"; 
END IF;
END$$

-- --------------------------------------
-- TRIGGER tr_auditar_estados
-- --------------------------------------

-- Para obtener el valor del estado anterior en el pedido, y asi poder guardarlo en la tabla MODIFICACION_ESTADOS, que es como una auditoria de los estados por los que pasa un pedido.

CREATE TRIGGER `tr_auditar_estados`
AFTER UPDATE ON PEDIDOS
FOR EACH ROW
SET @estadoAnterior = OLD.fk_id_estado;

-- --------------------------------------
-- SP sp_pivot_listas
-- --------------------------------------

-- SP que genera una vista de los productos con sus precios, trasponiendo la vista productos_con_precios dinámicamente.

DROP PROCEDURE IF EXISTS sp_pivot_listas;
DELIMITER $$
CREATE PROCEDURE `sp_pivot_listas`()
BEGIN
SET @sql = NULL;
SELECT GROUP_CONCAT(DISTINCT
           'MAX(CASE WHEN lista = "', lista, '" THEN precio END) AS "Lista_', lista, '"')
INTO @sql
FROM (SELECT pro.sku as 'sku', pro.nombre as 'nombre', pro.stock as 'stock', pre.precio as 'precio', pre.fk_id_lista as 'lista' FROM PRODUCTOS pro INNER JOIN PRECIOS_PRODUCTO pre ON pro.id_producto = pre.fk_id_producto ORDER BY pro.nombre) as productos_con_precio;

SET @sql = CONCAT('SELECT sku, nombre, ', @sql, ' FROM (SELECT pro.sku as "sku", pro.nombre as "nombre", pro.stock as "stock", pre.precio as "precio", pre.fk_id_lista as "lista" FROM PRODUCTOS pro INNER JOIN PRECIOS_PRODUCTO pre ON pro.id_producto = pre.fk_id_producto ORDER BY pro.nombre) as productos_con_precio
GROUP BY sku;');

PREPARE sentencia FROM @sql;
EXECUTE sentencia;
DEALLOCATE PREPARE sentencia;
END $$