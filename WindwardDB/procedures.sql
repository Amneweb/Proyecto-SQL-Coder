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

-- Este SP es para agregar los pedidos a la tabla PEDIDOS, y los correspondientes objetos {producto,cantidad} a la tabla DETALLE_PEDIDOS. El id del pedido se obtiene con el trigger disparado por la insersión del nuevo pedido en la tabla PEDIDOS.

-- Los datos de entrada son:

-- 1) El id del cliente
-- 2) Un json con los productos y las cantidades

-- Los pasos del SP son:

-- 1. Verifica que exista el cliente
-- 2. Verifica que el array del json no esté vacío
-- 3. Si las condiciones anteriores se cumplen, carga un nuevo registro en la tabla PEDIDOS
-- 4. En base a la longitud del json de pedidos, se itera sobre el mismo y se van insertando los pares producto-cantidad en la tabla de detalles siempre que:
-- ..4.a El id del producto corresponda a un producto existente
-- ..4.b La cantidad solicitada sea mayor que 0
-- ..4.c El stock del producto sea mayor que 0
-- 5. Si las condiciones anteriores hacen que no se pueda ingresar ningún registro a la tabla detalle de pedidos, se borra el registro recién ingresado a la tabla pedidos.

DROP PROCEDURE IF EXISTS sp_generar_pedidos;
DELIMITER $$
CREATE PROCEDURE `sp_generar_pedidos` (IN IDcliente INT, IN json_pedido JSON)
BEGIN
-- Longitud del JSON del pedido
DECLARE n INT;
-- Contador para iterar sobre el pedido
DECLARE i INT;
-- Acumulado de errores en el pedido
DECLARE j INT;
SET n=JSON_LENGTH(json_pedido);
-- Primero verifico si existe el cliente
-- 1
IF NOT EXISTS (SELECT id_cliente FROM CLIENTES WHERE id_cliente = IDcliente) THEN 
	SET @err = "No existe ningún cliente con ese ID"; 
	SELECT @err;
ELSE
	SET @err = '';
	-- Verifico si el carrito tiene productos (mediante la longitud del array)
	-- 2
	IF (n = 0) THEN
		SET @err = "El carrito está vacío, no se puede generar el pedido";
		SELECT @err;
	ELSE
		SET @err = '';
		SET @errIteracion = '';
		SET i = 0;
		set j = 0;
		INSERT INTO PEDIDOS (fk_id_cliente, fk_id_estado, fecha_pedido, fecha_entrega, fecha_efectiva_entrega) VALUES (IDcliente, "HEC", CURDATE(),CURDATE(),NULL);
		WHILE i < n DO
			-- Verifico que el producto exista
			-- 3
			IF NOT EXISTS (SELECT id_producto FROM PRODUCTOS WHERE id_producto = (SELECT JSON_EXTRACT(json_pedido,concat('$[',i,'].producto')) AS json_producto)) THEN
				SET @errIteracion = CONCAT(@errIteracion," Uno de los productos que trataste de ingresar (ingresado en la posicion ",i,") tiene un id inexistente y será borrado. ");
				SET j=j+1;
				SELECT @errIteracion;
				SELECT j;
			ELSE
				-- Verifico que la cantidad solicitada no sea = 0 o que el producto no tenga stock = 0
				-- 4
				IF (SELECT JSON_EXTRACT(json_pedido,concat('$[',i,'].cantidad'))= 0) THEN 
					SET @errIteracion=concat(@errIteracion," Uno de los productos solicitados (en la posicion ",i,") tenia cantidad 0 y fue borrado del pedido. ");
					SET j=j+1;
					SELECT @errIteracion;
					SELECT j;
				ELSE
					-- 5
					IF ((SELECT stock FROM PRODUCTOS WHERE id_producto = (SELECT JSON_EXTRACT(json_pedido,concat('$[',i,'].producto')) AS json_producto))=0) THEN 
						SET @errIteracion=concat(@errIteracion," Uno de los productos solicitados (en la posicion ",i,") tenia stock 0 y fue borrado del pedido. ");
						SET j = j+1;
						SELECT @errIteracion;
						SELECT j;
					ELSE 
						INSERT INTO DETALLE_PEDIDOS (fk_id_producto, cantidad,fk_id_pedido ) VALUES ((SELECT JSON_EXTRACT(json_pedido,concat('$[',i,'].producto')) AS producto),(SELECT JSON_EXTRACT(json_pedido,concat('$[',i,'].cantidad')) AS cantidad),@idNuevoPedido);
					-- cierro 5
					END IF;
				-- cierro 4
				END IF;
			-- cierro 3
			END IF;
			SET i=i+1;
		END WHILE;
	-- cierro 2	
	END IF;
-- cierro 1
END IF;
IF j>=n THEN 
SET @err = "No se pudo cargar ningún producto debido a que no se cumplieron las condiciones";
DELETE FROM PEDIDOS WHERE id_pedido = @idNuevoPedido;
END IF;
SELECT @err,@errIteracion;	
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

-- -----------------------------------------------
-- TRIGGERS tr_verificar_stock al insertar datos
-- -----------------------------------------------

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

-- --------------------------------------------------
-- TRIGGERS tr_verificar_stock al modificar pedidos
-- --------------------------------------------------

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
-- SP sp_totales_por_fecha
-- ----------------------------------
DROP PROCEDURE IF EXISTS sp_totales_por_fecha;
DELIMITER $$
CREATE PROCEDURE `sp_totales_por_fecha`(IN fecha_elegida DATE)
BEGIN
DROP TABLE IF EXISTS totales_por_fecha;
SET @sql = CONCAT('CREATE TEMPORARY TABLE totales_por_fecha (SELECT zona, fecha, sum(volumen) AS "volumen total", sum(peso_total) AS "peso total", sum(qty) AS "cantidad total" FROM dimensiones WHERE fecha="',fecha_elegida,'" GROUP BY zona order by sum(peso_total))');
PREPARE sentencia FROM @sql;
EXECUTE sentencia;
DEALLOCATE PREPARE sentencia;
END $$;

-- ----------------------------------
-- SP sp_generar_reparto
-- ----------------------------------
-- A este procedimiento se lo llama por zona y por fecha y asigna un vehículo en función del peso máximo y del peso total de las órdenes para el día y la zona correspondientes (A futoro: me queda por programar que haya que llamarlo una sola vez y que itere por zona, estuve intentando pero se me hizo complicado y decidí dejarlo así) - ATENCION: antes de llamar a este sp, hay que asegurarse de que hayamos llamado al sp que genera la tabla totales_por_fecha.
-- Pasos del SP
-- 1) Genera una tabla repartos_por_fecha, en la que se filtran los repartos en base a la fecha elegida. 
-- 2) Se verifica que la zona no tenga ningún reparto asignado. Si es así, se genera un mensaje de error
-- 3) Se seleccionan los "vehículos libres", es decir aquéllos que aun no han sido asignados a ningun reparto en la fecha. Esto se hace con un left join entre vehiculos y repartos_por_fecha.
-- 4) Se itera la tabla de vehiculos libres, comparando el peso maximo de dichos vehiculos con el peso de las ordenes de la zona
-- 5) En cuanto hay un vehiculo que cumple con la condición, se lo asigna a la zona y se genera el reparto
-- 6) Si ningún vehiculo cumple, se genera un error

DROP PROCEDURE IF EXISTS sp_generar_reparto;
DELIMITER $$
CREATE PROCEDURE `sp_generar_reparto`(IN IDzona INT, IN fecha_elegida DATE)
BEGIN
DECLARE IDlibre INT;
DECLARE peso FLOAT;
DECLARE j INT;
DECLARE k INT;

DROP TABLE IF EXISTS repartos_por_fecha;
SET @sql = CONCAT('CREATE TEMPORARY TABLE repartos_por_fecha (SELECT id_reparto, fk_id_vehiculo, fk_id_zona FROM REPARTOS WHERE fecha = "',fecha_elegida,'")');
PREPARE sentencia FROM @sql;
EXECUTE sentencia;
DEALLOCATE PREPARE sentencia;
SET peso = (SELECT `peso total` FROM totales_por_fecha WHERE zona = IDzona);
IF NOT EXISTS (SELECT fk_id_zona FROM repartos_por_fecha WHERE fk_id_zona = IDzona) THEN
DROP TABLE IF EXISTS vehiculos_libres;
CREATE TEMPORARY TABLE vehiculos_libres (SELECT vl.id_vehiculo
FROM VEHICULOS vl
LEFT JOIN repartos_por_fecha vr
      ON vl.id_vehiculo = vr.fk_id_vehiculo
      WHERE fk_id_vehiculo IS NULL);
	  SET k = (SELECT COUNT(*) FROM vehiculos_libres);
SET j=0;
SET @err = '';
iterar_vehiculos_libres: WHILE j < k DO
SELECT * FROM vehiculos_libres LIMIT j,1 INTO IDlibre;
SELECT IDlibre; 
IF ((SELECT max_peso FROM VEHICULOS v WHERE v.id_vehiculo = IDlibre)>peso) THEN
INSERT INTO REPARTOS VALUES (NULL,IDlibre,1,IDzona,fecha_elegida,NULL, NULL);
LEAVE iterar_vehiculos_libres;
ELSE
SET @err = CONCAT(@err," El vehiculo con id ",IDlibre," no se pudo seleccionar porque su peso maximo es menor que el de la zona");
END IF;
SET j = j + 1;
END WHILE iterar_vehiculos_libres; 
ELSE
SET @err = "La zona ya tiene un reparto asignado. Para seleccionar otro vehiculo, ir al procedimiento correspondiente";
END IF;
IF (@err <>'') THEN SELECT @err;  END IF;
END $$

-- ----------------------------------
-- SP sp_cargar_km
-- ----------------------------------

-- Al comenzar y finalizar el reparto, cada chofer deberá ingresar los datos del kilometraje, para que el sistema calcule los km totales recorridos. En un futuro, se podría relacionar esta app con alguna app de tracking que calcule sola los km recorridos. 
-- Los parámetros de entrada son 
-- 1) el id del reparto;
-- 2) el id del chofer; 
-- 3) una variable que representa el momento en que se carga el kilomentraje (si momento = INI, significa que se cargan los km al comienzo del viaje; si momento = FIN, los km son al final del viaje. Para que sean válidos, FIN > INI) 
-- 4) los km que marca el odómetro del vehículo en el momento de cargar los datos

DROP PROCEDURE IF EXISTS sp_cargar_km;
DELIMITER $$
CREATE PROCEDURE `sp_cargar_km`(IN nro_reparto INT,IN nro_chofer INT, IN momento VARCHAR(3), IN km INT)
BEGIN
DECLARE err VARCHAR(200);
DECLARE kmIniciales INT;
IF NOT EXISTS (SELECT id_reparto FROM REPARTOS WHERE id_reparto = nro_reparto AND fk_chofer = nro_chofer) THEN
	SET err = "El chofer que está intentando cargar los datos no es el chofer que hizo el reparto";
	SELECT err;
ELSE	
	IF (momento = "FIN") THEN 
		SELECT km_ini FROM REPARTOS WHERE id_reparto = nro_reparto INTO kmIniciales;
		IF ISNULL(kmIniciales) THEN 
			SET err = "Falta cargar el kilometraje inicial";
			SELECT err;
		ELSE 
			IF (km <= kmIniciales) THEN
				SET err = "Error al cargar los datos, el kilometraje final que se intenta cargar es menor que el inicial";
				SELECT err;
				ELSE
				UPDATE REPARTOS SET km_fin=km WHERE id_reparto = nro_reparto; 
			END IF;
		END IF;
	ELSE
		UPDATE REPARTOS SET km_ini=km WHERE id_reparto = nro_reparto;
	END IF;
END IF;
IF err <> '' THEN 
SELECT err;
ELSE
SET err='Los datos se cargaron con éxito';
SELECT err;
END IF;
END $$