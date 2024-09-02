-- --------------------------------------
-- FUNCION fn_generar_variable_lista
-- --------------------------------------

-- Función para poder usar la variable id_lista en la vista de precios por lista en base al id del cliente (para poder usar el id del cliente como variable y no como valor fijo en la cláusula de WHERE)

CREATE FUNCTION `fn_generar_variable_lista` (cliente INT) RETURNS INT DETERMINISTIC RETURN (SELECT fk_lista_precios FROM CLIENTES WHERE id_cliente = cliente);

-- --------------------------------------
-- FUNCION fn_volumen_individual
-- --------------------------------------

-- Función para calcular el volumen de cada producto en un determinado pedido - el volumen es para la cantidada total de dicho producto. Los parámetros de entrada son las dimensiones del producto -en cm- y la salida es el volumen en m3.

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