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
DROP PROCEDURE IF EXISTS sp_generar_pedidos;
DELIMITER $$
CREATE PROCEDURE `sp_generar_pedidos` (IN IDcliente INT, IN json_pedido JSON)
BEGIN
DECLARE n INT;
DECLARE i INT;
-- Primero verifico si existe el cliente
-- 1
IF NOT EXISTS (SELECT id_cliente FROM CLIENTES WHERE id_cliente = IDcliente) THEN SET @err = "No existe ningún cliente con ese ID"; SELECT @err;
	ELSE
		SET n=JSON_LENGTH(json_pedido);
		-- 2
		IF (n = 0) THEN
		SET @err = "El carrito está vacío, no se puede generar el pedido";
		SELECT @err;
			ELSE
				SET i = 0;
				WHILE i<n DO
				-- 3
				IF NOT EXISTS (SELECT id_producto FROM PRODUCTOS WHERE id_producto = (SELECT JSON_EXTRACT(json_pedido,concat('$[',i,'].producto')) AS json_producto)) THEN
				SET json_pedido = JSON_REMOVE(json_pedido,concat('$[',i,'].producto'),concat('$[',i,'].cantidad'));
				SET @err = "uno de los productos que trataste de ingresar tiene un id inexistente y será borrado";
				ELSE
					-- 4
					IF ((SELECT JSON_EXTRACT(json_pedido,concat('$[',i,'].cantidad'))= 0) OR ((SELECT stock FROM PRODUCTOS WHERE 
					id_producto = (SELECT JSON_EXTRACT(json_pedido,concat('$[',i,'].producto')) AS json_producto)=0))) THEN 
					SET json_pedido = JSON_REMOVE(json_pedido,concat('$[',i,'].producto'),concat('$[',i,'].cantidad'));
					SET @err="Uno de los productos solicitados tenia cantidad 0 y fue borrado del pedido";
					-- cierro 4
					END IF;
				-- cierro 3
				END IF;
				SET i=i+1;
			END WHILE;
			SELECT @err;
			-- 5
			IF @err ='' THEN
				INSERT INTO PEDIDOS (fk_id_cliente, fk_id_estado, fecha_pedido, fecha_entrega, fecha_efectiva_entrega)
				VALUES (IDcliente, "HEC", CURDATE(),CURDATE(),NULL);
				INSERT INTO DETALLE_PEDIDOS (fk_id_producto, cantidad,fk_id_pedido ) (SELECT *,@idNuevoPedido FROM JSON_TABLE(json_pedido,"$[*]" COLUMNS (fk_id_producto INT PATH "$.producto", cantidad INT PATH "$.cantidad")) AS detalles_json);
				SELECT @msj;
				ELSE
					SELECT @err;
			-- cierro 5
			END IF;
		-- cierro 2	
		END IF;
	-- cierro 1
	END IF;
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
INSERT INTO MODIFICACION_ESTADOS (fk_id_pedido,fk_id_empleado,hora_modificacion,fk_id_estado,fk_id_estado_anterior) VALUES (idpedido,idempleado,CURRENT_TIMESTAMP(),"APR", @EstadoPedido);
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
-- TRIGGERS tr_verificar_stock
-- --------------------------------------

-- Este trigger es disparado justo antes de agregar un pedido a la tabla DETALLE_PEDIDOS. Para cada producto, verifica que la cantidad solicitada sea menor o igual a las existencias en stock. Si se solicitan más productos de los que hay en stock, en el pedido sólo se carga lo que hay en stock.

DROP TRIGGER IF EXISTS tr_verificar_stock_on_insert;
DELIMITER $$
CREATE TRIGGER `tr_verificar_stock_on_insert`
BEFORE INSERT ON DETALLE_PEDIDOS
FOR EACH ROW
BEGIN
SET @msj = '';
SET @stock_existente = (SELECT stock FROM PRODUCTOS WHERE id_producto = NEW.fk_id_producto);
IF NEW.cantidad > @stock_existente THEN
SET NEW.cantidad = @stock_existente;
SET @msj="Las cantidades solicitadas de uno o varios de los productos son mayores al stock disponible. En esos casos el pedido se armo con el stock existente"; 
ELSE 
SET @msj="Los productos se agregaron sin problemas.";
END IF;
END$$

-- --------------------------------------
-- TRIGGERS tr_verificar_stock
-- --------------------------------------

-- Este trigger es disparado justo antes de agregar un pedido a la tabla DETALLE_PEDIDOS. Para cada producto, verifica que la cantidad solicitada sea menor o igual a las existencias en stock. Si se solicitan más productos de los que hay en stock, en el pedido sólo se carga lo que hay en stock.

DROP TRIGGER IF EXISTS tr_verificar_stock_on_update;
DELIMITER $$
CREATE TRIGGER `tr_verificar_stock_on_update`
BEFORE UPDATE ON DETALLE_PEDIDOS
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

-- ----------------------------------
-- SP sp_modificar_pedido
-- ----------------------------------
-- Para modificar un pedido existente. La modificacion de cantidad se hace producto por producto, lo mismo que el borrado de un producto. Si el producto está en estado aprobado, no se puede modificar.
-- Tablas/Vistas involucradas: PEDIDOS, CLIENTES, DETALLE_PEDIDOS

DROP PROCEDURE IF EXISTS sp_modificar_pedido;
DELIMITER $$
CREATE PROCEDURE `sp_modificar_pedido` (IN IDcliente INT, IN IDpedido INT, IN qty INT, IN IDproducto INT, IN tipo_modificacion VARCHAR (10))
BEGIN
IF EXISTS (SELECT id_pedido,fk_id_estado FROM PEDIDOS WHERE id_pedido=IDpedido AND fk_id_estado = "APR") THEN
    SET @err = "No se puede modificar un pedido que ya fue aprobado.";
	SELECT @err;
    ELSE
		SET @err = '';
		IF (IDcliente = 0 OR IDpedido = 0 OR IDproducto = 0 OR qty = 0 OR tipo_modificacion ='') THEN
			SET @err = 'Ni los ID del pedido, cliente y producto, ni la cantidad, ni el código de modificación pueden ser 0 o vacíos, por favor verifique sus datos.';
			SELECT @err;
		ELSE
			SET @err = '';
			IF NOT EXISTS
				(SELECT id_cliente from CLIENTES WHERE id_cliente = IDcliente) 
				THEN
				SET @err = CONCAT('No existe el cliente con ID ', IDcliente);
			END IF;
			IF NOT EXISTS
				(SELECT id_producto from PRODUCTOS WHERE id_producto = IDproducto) 
				THEN
				SET @err = CONCAT('No existe ningún producto con ID ', IDproducto);
			END IF;
			IF NOT EXISTS
				(SELECT FIND_IN_SET(tipo_modificacion,"ADD,UPDATE,DELETE"))
				THEN
				SET @err = CONCAT('El código de modificación ingresado no es un código permitido. El código debe ser ADD, UPDATE o DELETE. Usted ingresó ',tipo_modificacion);
			END IF;
			IF NOT EXISTS
				(SELECT id_pedido from PEDIDOS WHERE (id_pedido = IDpedido AND fk_id_cliente = IDcliente)) 
				THEN
				SET @err = CONCAT('El pedido con id ', IDpedido, ' no corresponde al cliente con id ',IDcliente);
			END IF;
			IF @err != '' 
				THEN
				SELECT @err;
			ELSE
				CASE
				WHEN tipo_modificacion = "UPDATE" THEN
				UPDATE DETALLE_PEDIDOS SET cantidad = qty WHERE fk_id_pedido = IDpedido AND fk_id_producto = IDproducto;
						SELECT @msj;
				WHEN tipo_modificacion = "ADD" THEN
					IF NOT EXISTS (SELECT fk_id_producto FROM DETALLE_PEDIDOS WHERE fk_id_pedido = IDpedido AND fk_id_producto = IDproducto) THEN 
							INSERT INTO DETALLE_PEDIDOS (fk_id_pedido,fk_id_producto,cantidad) VALUES (IDpedido,IDproducto,qty);
							SET @msj = "El pedido se modificó con éxito";
							ELSE
							SET @msj = "El producto ya está en el pedido. Para modificar la cantidad, ir a 'MODIFICAR PEDIDO'";
							END IF;
							SELECT @msj;
				WHEN tipo_modificacion = "DELETE" THEN
					DELETE FROM DETALLE_PEDIDOS WHERE fk_id_pedido = IDpedido AND fk_id_producto = IDproducto;
					SET @msj = "El producto se borró con éxito del pedido";
                    SELECT @msj;
					END CASE;
				END IF;
		END IF;
	END IF;
    SELECT @err;
END $$

-- ----------------------------------
-- SP sp_generar_reparto
-- ----------------------------------
-- En base a la tabla provisoria totales_por_fecha, se llama a la función que selecciona un vehículo para una determinada zona y se genera un reparto. Esto debería hacerse automáticamente para todas las zonas que tengan pedidos en el día en cuestión.

DROP PROCEDURE IF EXISTS sp_generar_reparto;
DELIMITER $$
CREATE PROCEDURE `sp_generar_reparto`(IN IDzona INT, IN fecha_elegida DATE)
BEGIN
DECLARE var_vehiculo INT;
DECLARE var_zona INT;
DECLARE var_fecha DATE;

CALL sp_generar_totales_por_fecha(fecha_elegida);

SELECT fn_seleccionar_vehiculo(fecha_elegida,`peso total`, `volumen total`,`cantidad total`) AS 'vehiculo' FROM totales_por_fecha WHERE zona=IDzona ORDER BY `peso total` ASC INTO var_vehiculo;
INSERT INTO REPARTOS VALUES (NULL,var_vehiculo,1,NULL,IDzona,fecha_elegida);
DROP TABLE IF EXISTS totales_por_fecha;
END $$


-- ----------------------------------
-- SP sp_generar_totales_por_fecha
-- ----------------------------------
-- SP para generar una tabla (que luego se borra) que contiene los totales de peso, volumen y cantidad agrupados por zona para una determinada fecha. Este SP es llamado por el sp que genera los repartos y al final del mismo, se borra la tabla. Lo hice con EXECUTE porque no me dejaba usar una variable en el WHERE del select.

DROP PROCEDURE IF EXISTS sp_generar_totales_por_fecha;
DELIMITER $$
CREATE PROCEDURE `sp_generar_totales_por_fecha` (IN fecha_elegida DATE)
BEGIN
DROP TABLE IF EXISTS totales_por_fecha;
SET @sql = CONCAT('CREATE TABLE totales_por_fecha (SELECT zona, fecha, sum(volumen) AS "volumen total", sum(peso_total) AS "peso total", sum(qty) AS "cantidad total" FROM dimensiones WHERE fecha="',fecha_elegida,'" GROUP BY zona)');
PREPARE sentencia FROM @sql;
EXECUTE sentencia;
DEALLOCATE PREPARE sentencia;
END $$

-- ------------------------------------------
-- SP sp_detalle_repartos
-- ------------------------------------------
-- SP que genera una vista con el detalle de los pedidos que componen cada reparto

DROP PROCEDURE IF EXISTS sp_detalle_repartos;
DELIMITER $$
CREATE PROCEDURE `sp_detalle_repartos` (IN fecha_elegida DATE, IN IDzona INT)
BEGIN
SET @sql = CONCAT('CREATE OR REPLACE VIEW vw_detalle_repartos AS (SELECT r.id_reparto, r.fk_id_zona, r.fecha, cz.fk_id_cliente,cz.id_pedido,pc.sku,pc.cantidad FROM REPARTOS r INNER JOIN (SELECT p.fk_id_cliente, c.fk_zona, p.fecha_pedido, p.id_pedido FROM PEDIDOS p INNER JOIN CLIENTES c ON p.fk_id_cliente = c.id_cliente WHERE c.fk_zona = ', IDzona, ' AND p.fecha_pedido = "',fecha_elegida, '") AS cz ON r.fk_id_zona = cz.fk_zona INNER JOIN pedido_cliente pc ON cz.fk_id_cliente = pc.id_cliente)');
PREPARE sentencia FROM @sql;
EXECUTE sentencia;
DEALLOCATE PREPARE sentencia;
END $$

-- ----------------------------------
-- SP sp_generar_repartos
-- ----------------------------------
-- En base a la tabla provisoria totales_por_fecha, se llama a la función que selecciona un vehículo para una determinada zona y se genera un reparto. Esto debería hacerse automáticamente para todas las zonas que tengan pedidos en el día en cuestión.

DROP PROCEDURE IF EXISTS sp_generar_repartos;
DELIMITER $$
CREATE PROCEDURE `sp_generar_repartos`(IN fecha_elegida DATE)
BEGIN
DECLARE var_vehiculo INT;
DECLARE IDzona INT;
DECLARE var_fecha DATE;
DECLARE i INT;
DECLARE n INT;

CALL sp_generar_totales_por_fecha(fecha_elegida);

SET n = (select count(*) from totales_por_fecha);
SET i = 0;

WHILE i < n DO
SET IDzona = (SELECT zona FROM totales_por_fecha LIMIT i,1);
SELECT fn_seleccionar_vehiculo(fecha_elegida,`peso total`, `volumen total`,`cantidad total`) AS 'vehiculo' FROM totales_por_fecha WHERE zona=IDzona ORDER BY `peso total` ASC INTO var_vehiculo;
INSERT INTO REPARTOS VALUES (NULL,var_vehiculo,1,NULL,IDzona,fecha_elegida);
SET i = i + 1;
END WHILE;

DROP TABLE IF EXISTS totales_por_fecha;
END $$
