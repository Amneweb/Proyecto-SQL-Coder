-- Created by Amneweb
CREATE SCHEMA `windward3` DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

USE windward3;
-- tables

-- Table: ZONA
CREATE TABLE ZONAS (
    id_zona int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre varchar(40) NOT NULL
    
);
-- Table: TIPO_DOC
CREATE TABLE TIPO_DOCUMENTO (
    sigla varchar(5) NOT NULL PRIMARY KEY,
    nombre_documento varchar(40) NULL
);

-- Table: LISTAS
CREATE TABLE LISTAS (
    id_lista int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    moneda varchar(5) NOT NULL,
    nombre varchar(40) NULL,
    descripcion varchar(50) NULL
);

-- Table: CLIENTES
CREATE TABLE CLIENTES (
    id_cliente int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    razon_social varchar(50) NOT NULL,
    sobrenombre varchar(50) NULL,
    fk_tipo_documento varchar(10) NOT NULL,
    nro_documento varchar(20) NOT NULL,
    direccion_calle varchar(50) NOT NULL,
    direccion_localidad varchar(20) NOT NULL,
    direccion_provincia varchar(20) NOT NULL,
    fk_zona int NOT NULL,
    nombre_contacto varchar(50) NULL,
    celular_contacto varchar(20) NOT NULL,
    fk_lista_precios int NOT NULL,
    FOREIGN KEY (fk_tipo_documento) REFERENCES TIPO_DOCUMENTO (sigla),
    FOREIGN KEY (fk_zona) REFERENCES ZONAS (id_zona),
    FOREIGN KEY (fk_lista_precios) REFERENCES LISTAS (id_lista)
);
-- Table: PRODUCTOS  
CREATE TABLE PRODUCTOS (
    id_producto int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    sku varchar(10) UNIQUE NOT NULL,
    nombre varchar(50) NULL,
    descripcion MEDIUMTEXT NULL,
    marca varchar(20) NULL,
    dimension_longitud int NOT NULL,
    dimension_ancho int NOT NULL,
    dimension_alto int NOT NULL,
    dimension_peso dec(5,2) NOT NULL,
    stock int NOT NULL default 1
);



-- Table: VEHICULOS
DROP TABLE IF EXISTS VEHICULOS;
CREATE TABLE VEHICULOS (
    id_vehiculo int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    patente varchar(10) UNIQUE NOT NULL,
    marca varchar(20) NULL,
    apodo varchar(20) NULL,
    max_peso int NOT NULL,
    max_volumen DEC (8,2) NOT NULL,
    max_cantidades int NOT NULL,
    consumo DEC (5,1) NOT NULL
);

-- Table: PRECIOS_PRODUCTO
CREATE TABLE PRECIOS_PRODUCTO (
    id_precio int NOT NULL AUTO_INCREMENT,
    fk_id_producto int NOT NULL,
    fk_id_lista int NOT NULL,
    PRIMARY KEY (id_precio, fk_id_producto),
    FOREIGN KEY (fk_id_producto) REFERENCES PRODUCTOS (id_producto),
    FOREIGN KEY (fk_id_lista) REFERENCES LISTAS (id_lista)
);

ALTER TABLE PRECIOS_PRODUCTO
ADD precio dec(12,2) NOT NULL;

-- Table: ESTADOS
CREATE TABLE ESTADOS (
    codigo varchar(3) NOT NULL PRIMARY KEY,
    descripcion varchar(40) NOT NULL
);

-- Table: PEDIDOS
CREATE TABLE PEDIDOS (
    id_pedido int NOT NULL AUTO_INCREMENT,
    fk_id_cliente int NOT NULL,
    fk_id_estado varchar(3) NOT NULL DEFAULT "HEC",
    fecha_pedido date NOT NULL DEFAULT (CURRENT_DATE),
    fecha_entrega date NOT NULL,
    fecha_efectiva_entrega date,
    PRIMARY KEY (id_pedido),
    FOREIGN KEY (fk_id_cliente) REFERENCES CLIENTES (id_cliente),
    FOREIGN KEY (fk_id_estado) REFERENCES ESTADOS (codigo)
);

-- Table: DETALLE_PEDIDOS
CREATE TABLE DETALLE_PEDIDOS (
    fk_id_pedido int NOT NULL ,
    fk_id_producto int NOT NULL ,
    cantidad int NOT NULL DEFAULT 1,
PRIMARY KEY (fk_id_pedido, fk_id_producto),
    FOREIGN KEY (fk_id_pedido) REFERENCES PEDIDOS (id_pedido),
    FOREIGN KEY (fk_id_producto) REFERENCES PRODUCTOS (id_producto)
);

-- Table: ROLES
CREATE TABLE ROLES (
    id_rol int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre varchar(10) NOT NULL,
    descripcion varchar(40) NULL
);

-- Table: EMPLEADOS
CREATE TABLE EMPLEADOS (
    id_empleado int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre varchar(50) NOT NULL,
    fk_tipo_documento varchar(10) NOT NULL,
    nro_documento varchar(20) NOT NULL,
    telefono varchar(20) NULL,
    fk_rol int NOT NULL,
    FOREIGN KEY (fk_tipo_documento) REFERENCES TIPO_DOCUMENTO (sigla),
    FOREIGN KEY (fk_rol) REFERENCES ROLES (id_rol)
);

-- Table: MODIFICACION_ESTADOS
CREATE TABLE MODIFICACION_ESTADOS (
    id_modificacion int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    fk_id_pedido int NOT NULL,
    fk_id_empleado int NOT NULL,
    hora_modificacion datetime NOT NULL default (CURRENT_TIMESTAMP),
    fk_id_estado varchar(3) NOT NULL,
    FOREIGN KEY (fk_id_pedido) REFERENCES PEDIDOS (id_pedido),
    FOREIGN KEY (fk_id_empleado) REFERENCES EMPLEADOS (id_empleado),
    FOREIGN KEY (fk_id_estado) REFERENCES ESTADOS (codigo)
);

ALTER TABLE MODIFICACION_ESTADOS 
ADD fk_id_estado_anterior varchar(3) NOT NULL,
ADD CONSTRAINT modificacion_estados_ibfk_4
FOREIGN KEY (fk_id_estado_anterior)
REFERENCES ESTADOS (codigo);

-- Table: REPARTOS
CREATE TABLE REPARTOS (
    id_reparto int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    fk_id_pedido int NOT NULL,
    fk_id_vehiculo int NOT NULL,
    fk_chofer int NOT NULL,
    kilometros int NULL,
    FOREIGN KEY (fk_id_pedido) REFERENCES PEDIDOS (id_pedido),
    FOREIGN KEY (fk_chofer) REFERENCES EMPLEADOS (id_empleado),
    FOREIGN KEY (fk_id_vehiculo) REFERENCES VEHICULOS (id_vehiculo)
);

-- Crea constraint entre pedidos y detalle de pedidos para borrar en cascada. Primero miramos los nombres de las claves constraint.
SHOW CREATE TABLE PEDIDOS;
SHOW CREATE TABLE DETALLE_PEDIDOS;

ALTER TABLE DETALLE_PEDIDOS
DROP FOREIGN KEY detalle_pedidos_ibfk_1;

ALTER TABLE DETALLE_PEDIDOS
ADD CONSTRAINT detalle_pedidos_ibfk_1
FOREIGN KEY (fk_id_pedido)
REFERENCES PEDIDOS (id_pedido)
ON DELETE CASCADE;

-- No necesito el id de cada pedido en la tabla de repartos. Con saber la zona y la fecha (que se la agrego con el alter table de más abajo) puedo armar una vista con el detalle de los pedidos involucrados (vw_detalle_repartos)
ALTER TABLE REPARTOS
DROP FOREIGN KEY repartos_ibfk_1;

ALTER TABLE REPARTOS
DROP COLUMN fk_id_pedido;

ALTER TABLE REPARTOS
ADD fk_id_zona  INT,
ADD FOREIGN KEY (fk_id_zona)
REFERENCES ZONAS (id_zona)
ON DELETE CASCADE;

ALTER TABLE REPARTOS
ADD fecha DATETIME NOT NULL default (CURRENT_TIMESTAMP);

-- En un principio había pensado que el chofer podía ingresar los km recorridos calculados por él mism, pero mucho mejor es que ingrese los kilometrajes del vehículo al comienzo y al final del recorrido. Para eso saco la columna kilómetros y agrego km_ini y km_fin

ALTER TABLE REPARTOS
ADD km_ini INT,
ADD km_fin INT,
DROP COLUMN kilometros;

-- Table: DETALLE_REPARTOS
CREATE TABLE DETALLE_REPARTOS (
    fk_id_reparto int NOT NULL ,
    fk_id_pedido int NOT NULL ,
PRIMARY KEY (fk_id_reparto, fk_id_pedido),
    FOREIGN KEY (fk_id_reparto) REFERENCES REPARTOS (id_reparto),
    FOREIGN KEY (fk_id_pedido) REFERENCES PEDIDOS (id_pedido)
);

ALTER TABLE DETALLE_REPARTOS 
DROP FOREIGN KEY detalle_repartos_ibfk_1;
ALTER TABLE DETALLE_REPARTOS 
ADD CONSTRAINT detalle_repartos_ibfk_1
  FOREIGN KEY (fk_id_reparto)
  REFERENCES REPARTOS (id_reparto)
  ON DELETE CASCADE;

ALTER TABLE DETALLE_REPARTOS 
DROP FOREIGN KEY detalle_repartos_ibfk_2;
ALTER TABLE DETALLE_REPARTOS 
ADD CONSTRAINT detalle_repartos_ibfk_2
  FOREIGN KEY (fk_id_pedido)
  REFERENCES PEDIDOS (id_pedido)
  ON DELETE CASCADE;

-- /////////////////////////////
-- DATOS
-- ////////////////////////////
INSERT INTO TIPO_DOCUMENTO VALUES ("DNI","Documento Nacional de Identidad"),
("CI","Cedula de Identidad"),("CUIT","Clave Unica de Identificacion Tributaria"),("CUIL","Clave Unica de Identificacion Laboral");

INSERT INTO ZONAS (nombre) VALUES ("Norte del GBA, hasta San Fernando"),
("Zarate"),("Oeste del GBA, hasta Gonzalez Catan"),("Sur del GBA, hasta La Plata");

INSERT INTO LISTAS (moneda, nombre, descripcion) VALUES ("ARS","50%","50% respecto al precio de lista"),("ARS","45 + 5%","5% sobre el 45% del precio de lista"),("ARS","45%","45% del precio de lista"),("ARS","MAYORISTA","Lista especial de EDNA");

INSERT INTO ESTADOS VALUES ("HEC","Pedido recien hecho por el cliente"),("APR","Pedido aprobado por administracion"),
("STO","Stock de productos ok"),("CAR","Pedido completo cargado en la camioneta"),("REP","Pedido en reparto"),("ENT","Pedido entregado");

INSERT INTO ROLES (nombre,descripcion) VALUES ("DEPOSITO","Encargado de deposito"),("ADMIN","Empleado de administracion"),("CHOFER","Chofer de vehiculos de reparto");

INSERT INTO PRODUCTOS (sku, nombre, descripcion, marca, dimension_longitud, dimension_ancho, dimension_alto, dimension_peso, stock) VALUES
('FW85', 'Edna 12x70 FW85 Linea Premium', 'Batería de 12x75 amperes, calcio-plata, marca Edna, fabricada en Argentina', 'EDNA', 185, 140, 190, 18, 0),
	('FW90', 'Edna 12x75 FW90 Linea Premium', 'Batería de 12x75 amperes, calcio-plata, marca Edna, fabricada en Argentina', 'EDNA', 185, 140, 190, 18, 10),
	('FW70', 'Edna 12x65 FW70', 'Edna 12x65 FW70, especial para autos nafteros, Edna línea Premium', 'EDNA', 185, 135, 180, 14, 4),
	('FW100', 'Edna 12x100 FW100 Bora', 'Edna 12x65 FW70, especial para autos nafteros, Edna línea Premium', 'EDNA', 200, 150, 190, 23, 20);
INSERT INTO PRODUCTOS (sku, nombre, descripcion, marca, dimension_longitud, dimension_ancho, dimension_alto, dimension_peso, stock) VALUES
	('CL65PB', 'Clorex 12x75 FW90 Linea Premium', 'Batería de 12x75 amperes, calcio-plata, marca Edna, fabricada en Argentina', 'CLOREX', 185, 140, 190, 18, 40),
	('CL65PBS', 'Edna 12x65 FW70', 'Edna 12x65 FW70, especial para autos nafteros, Edna línea Premium', 'CLOREX', 185, 135, 180, 14, 45),
	('CL16019', 'Clorex 19 placas para colectivos', 'Edna 12x65 FW70, especial para autos nafteros, Edna línea Premium', 'CLOREX', 200, 150, 190, 23, 28);
	INSERT INTO PRODUCTOS VALUES
	(NULL,'CL23P180', 'Clorex 23 placas para colectivos', 'Clorex 180 para colectivos, 23 placas, garantia 1 año', 'CLOREX', 500, 200, 190, 50, 50),
	(NULL,'MB25', 'Edna 25 placas para colectivos', 'Edna para colectivos, garantia 1 año', 'CLOREX', 500, 200, 190, 50, 20),
	(NULL,'MB250', 'Edna 25 placas', 'Edna para colectivos, garantia 1 año', 'EDNA', 500, 200, 190, 50, 200)
	;

INSERT INTO EMPLEADOS (nombre,fk_tipo_documento,nro_documento,telefono,fk_rol)VALUES("Mario Daniel","DNI","40000000","116666666",3), ("Mario Guillermo","DNI","40000001","116666666",3),("Mario Ramirez","DNI","40000002","116666666",3);

INSERT INTO CLIENTES (razon_social,sobrenombre,fk_tipo_documento,nro_documento,direccion_calle,direccion_localidad,direccion_provincia,fk_zona,nombre_contacto,celular_contacto,fk_lista_precios) VALUES 
("Baterias SRL","Mr Baterias","CUIT","11111111","direccion 1","localidad 1","Buenos Aires",1,"nombre 1","01133333333",1),
("Lubricentro Pepito S de H","Lubricentro Pepito","CUIT","11111112","direccion 2","localidad 1","Buenos Aires",1,"nombre 2","01133333332",1),
("Fulano y Mengano","Baterias Fulanito","CUIT","11111113","direccion 3","localidad 2","Buenos Aires",2,"nombre 3","01133333331",2),
("Battery Power SA","Battery Power","DNI","1111114","direccion 11","localidad 5","Buenos Aires",1,"nombre 11","01133333334",3),
("Energy de Juan Perez","Energy","CUIT","11111115","direccion 4","localidad 2","Buenos Aires",2,"nombre 12","01133333433",1),
("Casa de Baterias de Juan Cruz","Recargando...","CUIT","11111116","direccion 5","localidad 7","Buenos Aires",3,"nombre 4","01133333333",2),
("Baterias de JC y AZ","Los amigos","CUIL","11111117","direccion 6","localidad 4","Buenos Aires",2,"nombre apellido","01133333335",1),
("Insumos para vehiculos SRL","Delivery de baterias","CUIL","11111118","direccion 7","localidad 4","Buenos Aires",2,"nombre 20","01133333338",1),
("Baticueva","Baticueva","CUIL","11111002","direccion 9","localidad 9","Buenos Aires",3,"nombre 20","01133334338",3),
("Otro Cliente","Otro Cliente","CUIL","11111012","direccion 10","localidad 10","Buenos Aires",3,"nombre 21","01133344338",3),
("Otro Cliente 2","Otro Cliente 2","CUIL","11111112","direccion 11","localidad 11","Buenos Aires",3,"nombre 22","01143344338",2),
("Otro Cliente 3","Otro Cliente 3","CUIL","11111312","direccion 12","localidad 12","Buenos Aires",2,"nombre 23","01143344338",1);

INSERT INTO PRECIOS_PRODUCTO (fk_id_producto,fk_id_lista,precio) VALUES 
(1,1,15000),(1,2,20000),(1,3,12000),
(2,1,12000),(2,2,15000),(2,3,10000),
(3,1,25000),(3,2,30000),(3,3,22000),
(4,1,25000),(4,2,30000),(4,3,22000),
(5,1,30000),(5,2,39000),(5,3,25000),
(6,1,220000),(6,2,300000),(6,3,245000);
INSERT INTO PRECIOS_PRODUCTO VALUES
(NULL,7,1,300000),(NULL,7,2,400500),(NULL,7,3,325000),
(NULL,8,1,230000),(NULL, 8, 2, 250000),(NULL,8,3,235000);


INSERT INTO PEDIDOS (fk_id_cliente, fk_id_estado, fecha_pedido, fecha_entrega, fecha_efectiva_entrega)
VALUES (1, "HEC", '2024-08-31','2024-08-31',NULL),
(5, "APR", '2024-08-31','2024-08-31',NULL),
(7, "APR", '2024-08-31','2024-08-31',NULL),
(8, "APR", '2024-08-31','2024-08-31',NULL);

INSERT INTO PEDIDOS VALUES 
(NULL,8,"APR",'2024-08-31','2024-08-31',NULL),
(NULL,6,"APR",'2024-08-31','2024-08-31',NULL),
(NULL,9,"APR",'2024-08-31','2024-08-31',NULL),
(NULL,10,"APR",'2024-08-31','2024-08-31',NULL);


INSERT INTO DETALLE_PEDIDOS (fk_id_pedido,fk_id_producto,cantidad)
VALUES (1,3,5),(1,2,5),(1,5,2),(2,2,3),(3,4,15),(3,2,5),(3,1,21),(4,2,20),(4,1,1),
(5,9,10),(5,8,5),(6,9,2),(6,7,10),(6,4,15),(7,8,5),(7,7,21),(8,5,20),(8,1,1)
;


INSERT INTO ESTADOS VALUES ("SBY","Stand By, en espera de stock o lugar");

INSERT INTO VEHICULOS VALUES 
(NULL,"ZZZ-111-AA", "Mercedes Benz", "Sprinter Blanca", 2500,2000,200,10),
(NULL,"ZZZ-222-AA", "Mercedes Benz", "Sprinter Azul", 4500,3000,300,10),
(NULL,"ZZZ-333-AA", "Iveco", "Iveco", 2500,2000,200,10),
(NULL,"ZZZ-444-AA", "Renault", "Camion", 7000,5000,500,20);

-- ////////////////////////
-- PROCEDURES
-- ///////////////////////
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
						INSERT INTO DETALLE_PEDIDOS (fk_id_producto, cantidad,fk_id_pedido ) VALUES ((SELECT JSON_EXTRACT(json_pedido,CONCAT('$[',i,'].producto')) AS producto),(SELECT JSON_EXTRACT(json_pedido,CONCAT('$[',i,'].cantidad')) AS cantidad),@idNuevoPedido);
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
IF ((@EstadoPedido != "APR") AND (@EstadoPedido != "SBY")) THEN 
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
SET @msj="Las cantidades solicitadas de uno o varios de los productos son mayores al stock disponible. En esos casos el pedido se armó con el stock existente"; 
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
SET @msj="Las cantidades solicitadas de uno o varios de los productos es mayor al stock disponible. En esos casos el pedido se armó con el stock existente"; 
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



-- --------------------------------------
-- TRIGGER add_new_reparto
-- --------------------------------------

-- Este trigger es para tomar el id generado al momento de cargar un reparto y usar el mismo id para la tabla de detalle de repartos

CREATE TRIGGER `tr_add_new_reparto`
AFTER INSERT ON `REPARTOS`
FOR EACH ROW
SET @idNuevoReparto = NEW.id_reparto;

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

IF (@err !='') THEN 
	SELECT @err;  
END IF;
END $$

-- --------------------------------------
-- TRIGGER tr_pasar_a_reparto
-- --------------------------------------

-- Cambia el estado de los pedidos involucrados en un reparto determinado a "REP"

CREATE TRIGGER `tr_pasar_a_reparto`
AFTER INSERT ON `DETALLE_REPARTOS`
FOR EACH ROW
SET @idPedido = NEW.fk_id_pedido;
CALL sp_modificar_estado(@idPedido, 1, "REP")

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


-- /////////////////////////////
-- FUNCTIONS
-- /////////////////////////////

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_generar_variable_lista`(cliente INT) RETURNS int
    DETERMINISTIC
RETURN (SELECT fk_lista_precios FROM CLIENTES WHERE id_cliente = cliente);

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_peso_individual`(peso FLOAT,cantidad INT) RETURNS float
    NO SQL
RETURN (peso*cantidad);

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_volumen_individual`(alto INT,ancho INT, largo INT, cantidad INT) RETURNS decimal(8,2)
    NO SQL
RETURN (alto/100*ancho/100*largo/100*cantidad);

-- //////////////////////////
-- VIEWS
-- /////////////////////////
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


