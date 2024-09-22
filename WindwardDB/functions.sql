-- --------------------------------------
-- FUNCION fn_generar_variable_lista
-- --------------------------------------

-- Función para poder usar la variable id_lista en la vista de precios por lista en base al id del cliente (para poder usar el id del cliente como variable y no como valor fijo en la cláusula de WHERE)

CREATE FUNCTION `fn_generar_variable_lista` (cliente INT) RETURNS INT DETERMINISTIC RETURN (SELECT fk_lista_precios FROM CLIENTES WHERE id_cliente = cliente);

-- --------------------------------------
-- FUNCION fn_volumen_individual
-- --------------------------------------

-- Función para calcular el volumen de cada producto en un determinado pedido - el volumen es para la cantidada total de dicho producto. Los parámetros de entrada son las dimensiones del producto -en mm- y la salida es el volumen en dm3.

CREATE FUNCTION `fn_volumen_individual` (alto INT,ancho INT, largo INT, cantidad INT) RETURNS DEC(8,2)
NO SQL
RETURN (alto/100*ancho/100*largo/100*cantidad);

-- --------------------------------------
-- FUNCION fn_peso_individual
-- --------------------------------------

-- Función para calcular el peso por producto en cada pedido. (= peso individual x cantidad)

CREATE FUNCTION `fn_peso_individual` (peso FLOAT,cantidad INT) RETURNS FLOAT
NO SQL
RETURN (peso*cantidad);




-- --------------------------------------
-- FUNCION fn_seleccionar_vehiculo
-- --------------------------------------
-- En base a los repartos por fecha, y a los vehiculos que aun no han sido asignados, se elige un vehiculo para la zona determinada
DROP FUNCTION IF EXISTS fn_seleccionar_vehiculo;
DELIMITER $$
CREATE FUNCTION `fn_seleccionar_vehiculo`(fpeso FLOAT, volumen FLOAT, cantidad INT) RETURNS int
    READS SQL DATA
BEGIN
DECLARE maxVolumen INT DEFAULT 0;
DECLARE maxPeso INT DEFAULT 0;
DECLARE maxCantidad INT DEFAULT 0;
DECLARE id_seleccionado INT DEFAULT 0;
DECLARE n INT DEFAULT 0;
DECLARE i INT DEFAULT 0;
SET i=0;



 SET n = (SELECT COUNT(*) FROM vehiculos_libres);


WHILE i < n DO

SELECT max_peso, max_volumen, max_cantidades, id_vehiculo  FROM VEHICULOS v INNER JOIN vehiculos_libres as vl ON vl.id_libres = v.id_vehiculo ORDER BY max_peso ASC LIMIT i,1 INTO maxPeso, maxVolumen, maxCantidad,id_seleccionado;
-- Empieza primer verificacion con el peso
IF (peso > maxPeso) THEN
SET i = i + 1;
ELSE
    IF (volumen > maxVolumen) THEN
    SET i = i + 1;
    ELSE
        IF (cantidad > maxCantidad) THEN
        SET i = i + 1;
        ELSE
          RETURN id_seleccionado;
        END IF;
    END IF;
END IF;
END WHILE;
RETURN id_seleccionado; 
END $$

-- ---------------------???????????????
-- opcion 2
-- ---------------------------
DROP FUNCTION IF EXISTS fn_confirmar_vehiculo;
DELIMITER $$
CREATE FUNCTION `fn_confirmar_vehiculo`(IDlibre INT,peso FLOAT, volumen FLOAT, cantidad INT) RETURNS VARCHAR(6)
    READS SQL DATA
BEGIN
DECLARE maxVolumen INT DEFAULT 0;
DECLARE maxPeso INT DEFAULT 0;
DECLARE maxCantidad INT DEFAULT 0;


SELECT max_peso, max_volumen, max_cantidades, id_vehiculo  FROM VEHICULOS v WHERE id_vehiculo = IDlibre INTO maxPeso, maxVolumen, maxCantidad;
-- Empieza primer verificacion con el peso
IF (peso > maxPeso) THEN
RETURN "NOTOK";
ELSE
    IF (volumen > maxVolumen) THEN
    RETURN "NOTOK";
    ELSE
        IF (cantidad > maxCantidad) THEN
        RETURN "NOTOK";
        ELSE
          RETURN "OK";
        END IF;
    END IF;
END IF;

END $$