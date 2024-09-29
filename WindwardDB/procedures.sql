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

-- NOTA: Los errores se van guardando en una tabla temporaria

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
DROP TABLE IF EXISTS errores;
CREATE TEMPORARY TABLE errores (
    error VARCHAR(250) NOT NULL
);
-- Primero verifico si existe el cliente
-- 1
IF NOT EXISTS (SELECT id_cliente FROM CLIENTES WHERE id_cliente = IDcliente) THEN 
	INSERT INTO errores VALUES ("No existe ningún cliente con ese ID");
ELSE
	-- Verifico si el carrito tiene productos (mediante la longitud del array)
	-- 2
	IF (n = 0) THEN
		INSERT INTO errores VALUES ("El carrito está vacío, no se puede generar el pedido");
	ELSE
		SET i = 0;
		set j = 0;
		INSERT INTO PEDIDOS (fk_id_cliente, fk_id_estado, fecha_pedido, fecha_entrega, fecha_efectiva_entrega) VALUES (IDcliente, "HEC", CURDATE(),CURDATE(),NULL);
		WHILE i < n DO
			-- Verifico que el producto exista
			-- 3
			IF NOT EXISTS (SELECT id_producto FROM PRODUCTOS WHERE id_producto = (SELECT JSON_EXTRACT(json_pedido,CONCAT('$[',i,'].producto')) AS json_producto)) THEN
				INSERT INTO errores VALUES (CONCAT("Uno de los productos que trataste de ingresar (ingresado en la posicion ",i,") tiene un id inexistente y será borrado."));
				SET j=j+1;
			ELSE
				-- Verifico que la cantidad solicitada no sea = 0 o que el producto no tenga stock = 0
				-- 4
				IF (SELECT JSON_EXTRACT(json_pedido,concat('$[',i,'].cantidad'))= 0) THEN 
					INSERT INTO errores VALUES (CONCAT("Uno de los productos solicitados (en la posicion ",i,") tenia cantidad 0 y fue borrado del pedido."));
					SET j=j+1;
				ELSE
					-- 5
					IF ((SELECT stock FROM PRODUCTOS WHERE id_producto = (SELECT JSON_EXTRACT(json_pedido,concat('$[',i,'].producto')) AS json_producto))=0) THEN 
						INSERT INTO errores VALUES (CONCAT("Uno de los productos solicitados (en la posicion ",i,") tenia stock 0 y fue borrado del pedido. "));
						SET j = j+1;
					ELSE 
						SET @json_prod = (SELECT JSON_EXTRACT(json_pedido,CONCAT('$[',i,'].producto')));
						SET @json_cant = (SELECT JSON_EXTRACT(json_pedido,CONCAT('$[',i,'].cantidad')));
						INSERT INTO DETALLE_PEDIDOS (fk_id_producto, cantidad,fk_id_pedido ) VALUES (@json_prod,@json_cant,@idNuevoPedido);
						UPDATE PRODUCTOS
						SET stock = @nuevo_stock 
						WHERE id_producto = @json_prod;
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
	INSERT INTO errores VALUES ("No se pudo cargar ningún producto debido a que no se cumplieron las condiciones");
	DELETE FROM PEDIDOS WHERE id_pedido = @idNuevoPedido;
END IF;
IF ((SELECT COUNT(*) FROM errores)>0) THEN
	SELECT * FROM errores;
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
			SET @msj = "El pedido fue borrado exitosamente";
			SELECT @msj;
		END IF;
	END IF;
END $$


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
			IF 
				(FIND_IN_SET(tipo_modificacion,"ADD,UPDATE,DELETE")=0)
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
				SET @msj = "El pedido se actualizó con éxito";
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

END $$



-- ----------------------------------
-- SP sp_generar_reparto
-- ----------------------------------
-- A este procedimiento se lo llama por zona y por fecha y asigna un vehículo en función del peso máximo y del peso total de las órdenes para el día y la zona correspondientes (A futoro: me queda por programar que haya que llamarlo una sola vez y que itere por zona, estuve intentando pero se me hizo complicado y decidí dejarlo así)
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
DECLARE n INT;
DROP TABLE IF EXISTS repartos_por_fecha;
SET @sql = CONCAT('CREATE TEMPORARY TABLE repartos_por_fecha (SELECT id_reparto, fk_id_vehiculo, fk_id_zona FROM REPARTOS WHERE fecha = "',fecha_elegida,'")');
PREPARE sentencia FROM @sql;
EXECUTE sentencia;
DEALLOCATE PREPARE sentencia;
SET peso = (SELECT `peso total` FROM totales WHERE zona = IDzona AND fecha = fecha_elegida);
-- Si peso=0 significa que no hubo pedidos para la zona
IF peso = 0 THEN
	SET @err = CONCAT("No hay pedidos para la zona ",IDzona," en el día ",fecha_elegida);
ELSE
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
			IF ((SELECT max_peso FROM VEHICULOS v WHERE v.id_vehiculo = IDlibre)>peso) THEN
				INSERT INTO REPARTOS (fk_id_vehiculo,fk_chofer,fk_id_zona,fecha) VALUES (IDlibre,1,IDzona,fecha_elegida);
				INSERT INTO DETALLE_REPARTOS (fk_id_reparto,fk_id_pedido)((SELECT @idNuevoReparto, p.id_pedido FROM pedidos_aprobados p INNER JOIN CLIENTES c ON p.fk_id_cliente = c.id_cliente WHERE c.fk_zona = IDzona AND p.fecha_pedido = fecha_elegida));
				LEAVE iterar_vehiculos_libres;
			ELSE
				SET @err = CONCAT(@err," El vehiculo con id ",IDlibre," no se pudo seleccionar porque su peso maximo es menor que el de la zona");
			END IF;
			SET j = j + 1;
			IF (j>=k) THEN
			DROP TABLE IF EXISTS pedidos_zona;
			CREATE TEMPORARY TABLE pedidos_zona (SELECT c.fk_zona, p.id_pedido, p.fecha_pedido FROM CLIENTES c INNER JOIN pedidos_aprobados p ON p.fk_id_cliente = c.id_cliente WHERE fk_zona=IDzona AND fecha_pedido = fecha_elegida);
			SET @cant_pedidos_sin_reparto = (SELECT COUNT(id_pedido) FROM pedidos_zona GROUP BY fk_zona);
			SET n = 0;
			WHILE n < @cant_pedidos_sin_reparto DO
			CALL sp_modificar_estado((SELECT id_pedido FROM pedidos_zona LIMIT n,1),1,"SBY");
			INSERT INTO MODIFICACION_ESTADOS (fk_id_pedido,fk_id_empleado,hora_modificacion,fk_id_estado,fk_id_estado_anterior) VALUES ((SELECT id_pedido FROM pedidos_zona LIMIT n,1),1,CURRENT_TIMESTAMP(),"SBY", "APR");
			SET n = n +1;
			END WHILE;
				SET @err = "No se pudo generar el reparto debido a que ningún vehículo puede llevar tanta carga. Se pasaron los pedidos al estado STAND-BY para su división en repartos más chicos";
			DROP TABLE IF EXISTS pedidos_zona;	
			END IF;
			END WHILE iterar_vehiculos_libres;
		ELSE
			SET @err = "La zona ya tiene un reparto asignado. Para seleccionar otro vehiculo, ir al procedimiento correspondiente";
		END IF;
END IF;
IF (@err !='') THEN 
	SELECT @err;  
END IF;
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

-- --------------------------------------
-- SP sp_modificar_estado
-- --------------------------------------

-- SP que modifica el estado del pedido, excepto cuando se lo aproeba, que tiene su propio stored procedure. Luego de la modificacion se agrega un registro a la tabla MODIFICACION_ESTADOS.
-- Los parámetros de entrada son los id de empleado y pedido, y el nuevo estado.

DROP PROCEDURE IF EXISTS sp_modificar_estado;
DELIMITER $$
CREATE PROCEDURE `sp_modificar_estado` (IN idpedido INT, IN idempleado INT, IN estado VARCHAR(3))
BEGIN
set @IDpedido = idpedido;
set @EstadoPedido = (SELECT fk_id_estado FROM PEDIDOS WHERE id_pedido = @IDpedido);
	UPDATE PEDIDOS SET fk_id_estado = estado WHERE id_pedido = @IDpedido;
	INSERT INTO MODIFICACION_ESTADOS (fk_id_pedido,fk_id_empleado,hora_modificacion,fk_id_estado,fk_id_estado_anterior) VALUES (idpedido,idempleado,CURRENT_TIMESTAMP(),estado, @EstadoPedido); 
	SET @msj = "El estado se modificó con éxito";
	SELECT @msj;
END $$

-- ///////////////////////////////////
-- Para INFORMES
-- ///////////////////////////////////

-- -----------------------------------------
-- SP sp_pivot_totales_peso
-- -----------------------------------------
-- Este proceso genera una vista similar a "totales", pero sólo para los pesos y con las zonas como columnas, de manera de poder visualizar los datos en un gráfico de barras


DROP PROCEDURE IF EXISTS sp_pivot_totales_peso;
DELIMITER $$
CREATE PROCEDURE `sp_pivot_totales_peso`()
BEGIN
SET @sql = NULL;
SELECT GROUP_CONCAT(DISTINCT
           'MAX(CASE WHEN zona = "', zona, '" THEN `peso total` END) AS "', zona, '"')
INTO @sql
FROM totales;

SET @sql = CONCAT('SELECT fecha, ', @sql, ' FROM totales GROUP BY fecha;');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END $$

-- -----------------------------------------
-- SP sp_pivot_cantidades_mes
-- -----------------------------------------
-- Este proceso genera una vista similar a la anterior, pero con los totales agrupados por mes


DROP PROCEDURE IF EXISTS sp_pivot_cantidades_mes;
DELIMITER $$
CREATE PROCEDURE `sp_pivot_cantidades_mes`()
BEGIN
SET @sql = NULL;
SELECT GROUP_CONCAT(DISTINCT
           'MAX(CASE WHEN zona = "', zona, '" THEN `peso total` END) AS "', zona, '"')
INTO @sql
FROM totales_por_mes;

SET @sql = CONCAT('SELECT mes, ', @sql, ' FROM totales_por_mes GROUP BY mes;');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END $$

-- -----------------------------------------------------------------------
-- Total de cada cliente para una determinada fecha o mes
-- -----------------------------------------------------------------------
-- Para armar una especie de ranking de clientes (para ver las cantidades y los montos en un mismo gráfico, divido los montos por 1000 y multiplico cantidades por 100)

-- 1) DIARIO

DROP PROCEDURE IF EXISTS sp_ranking_diario;
DELIMITER $$
CREATE PROCEDURE `sp_ranking_diario`(IN fecha DATE)
BEGIN
SELECT razon_social, SUM(Total_renglon/1000) AS "Total pedido", SUM(cantidad*100) AS "Total cantidades" FROM pedido_cliente  WHERE fecha = fecha  GROUP BY id_cliente ORDER BY `Total pedido`;
END $$

-- 2) MENSUAL

DROP PROCEDURE IF EXISTS sp_ranking_mensual;
DELIMITER $$
CREATE PROCEDURE `sp_ranking_mensual`(IN month_number INT)
BEGIN
SELECT razon_social, SUM(Total_renglon/1000) AS "Total pedido", SUM(cantidad*100) AS "Total cantidades" FROM pedido_cliente  WHERE MONTH(fecha) = month_number  GROUP BY id_cliente ORDER BY `Total pedido`;
END $$

-- -----------------------------------------------------------------------
-- Relación cantidad de baterías por kilómetro recorrido
-- -----------------------------------------------------------------------

DROP PROCEDURE IF EXISTS sp_km_cantidad_ratio;
DELIMITER $$
CREATE PROCEDURE `sp_km_cantidad_ratio`()
BEGIN
DROP TABLE IF EXISTS ratio;
CREATE TEMPORARY TABLE ratio 
(fk_id_reparto INT NOT NULL,
fk_id_zona INT NOT NULL,
fecha DATE NOT NULL,
cantidades INT NOT NULL,
kilometros INT NOT NULL);
INSERT INTO ratio
(SELECT fk_id_reparto,fk_id_zona, fecha, cantidades,kilometros FROM km_cantidad);
SELECT fecha, SUM(cantidades) AS qty, SUM(kilometros) AS km, (SUM(cantidades)/SUM(kilometros)*100) as rt from ratio GROUP BY fecha ORDER BY fecha ASC;
END $$
