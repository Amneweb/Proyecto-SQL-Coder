insert into TIPO_DOCUMENTO VALUES ("DNI","Documento Nacional de Identidad"),
("CI","Cedula de Identidad"),("CUIT","Clave Unica de Identificacion Tributaria"),("CUIL","Clave Unica de Identificacion Laboral");

insert into ZONAS (nombre) VALUES ("Norte del GBA, hasta San Fernando"),
("Zarate"),("Oeste del GBA, hasta Gonzalez Catan"),("Sur del GBA, hasta La Plata");

insert into LISTAS (moneda, nombre, descripcion) VALUES ("ARS","50%","50% respecto al precio de lista"),("ARS","45 + 5%","5% sobre el 45% del precio de lista"),("ARS","45%","45% del precio de lista"),("ARS","MAYORISTA","Lista especial de EDNA");

insert into ESTADOS VALUES ("HEC","Pedido recien hecho por el cliente"),("APR","Pedido aprobado por administracion"),
("STO","Stock de productos ok"),("CAR","Pedido completo cargado en la camioneta"),("REP","Pedido en reparto"),("ENT","Pedido entregado");

insert into ROLES (nombre,descripcion) VALUES ("DEPOSITO","Encargado de deposito"),("ADMIN","Empleado de administracion"),("CHOFER","Chofer de vehiculos de reparto");

INSERT INTO PRODUCTOS (sku, nombre, descripcion, marca, dimension_longitud, dimension_ancho, dimension_alto, dimension_peso, stock) VALUES
	('FW90', 'Edna 12x75 FW90 Linea Premium', 'Batería de 12x75 amperes, calcio-plata, marca Edna, fabricada en Argentina', 'EDNA', 185, 140, 190, 18, 10),
	('FW70', 'Edna 12x65 FW70', 'Edna 12x65 FW70, especial para autos nafteros, Edna línea Premium', 'EDNA', 185, 135, 180, 14, 4),
	('FW100', 'Edna 12x100 FW100 Bora', 'Edna 12x65 FW70, especial para autos nafteros, Edna línea Premium', 'EDNA', 200, 150, 190, 23, 20);

INSERT INTO EMPLEADOS (nombre,fk_tipo_documento,nro_documento,telefono,fk_rol)VALUES("Mario Daniel","DNI","40000000","116666666",3), ("Mario Guillermo","DNI","40000001","116666666",3),("Mario Ramirez","DNI","40000002","116666666",3);

insert into CLIENTES (razon_social,sobrenombre,fk_tipo_documento,nro_documento,direccion_calle,direccion_localidad,direccion_provincia,fk_zona,nombre_contacto,celular_contacto,fk_lista_precios) VALUES 
("Baterias SRL","Mr Baterias","CUIT","11111111","direccion 1","localidad 1","Buenos Aires",1,"nombre 1","01133333333",1),
("Lubricentro Pepito S de H","Lubricentro Pepito","CUIT","11111112","direccion 2","localidad 1","Buenos Aires",1,"nombre 2","01133333332",1),
("Fulano y Mengano","Baterias Fulanito","CUIT","11111113","direccion 3","localidad 2","Buenos Aires",2,"nombre 3","01133333331",2),
("Battery Power SA","Battery Power","DNI","1111114","direccion 11","localidad 5","Buenos Aires",1,"nombre 11","01133333334",3),
("Energy de Juan Perez","Energy","CUIT","11111115","direccion 4","localidad 2","Buenos Aires",2,"nombre 12","01133333433",1),
("Casa de Baterias de Juan Cruz","Recargando...","CUIT","11111116","direccion 5","localidad 7","Buenos Aires",3,"nombre 4","01133333333",2),
("Baterias de JC y AZ","Los amigos","CUIL","11111117","direccion 6","localidad 4","Buenos Aires",2,"nombre apellido","01133333335",1),
("Insumos para vehiculos SRL","Delivery de baterias","CUIL","11111118","direccion 7","localidad 4","Buenos Aires",2,"nombre 20","01133333338",1);

insert into PRECIOS_PRODUCTO (fk_id_producto,fk_id_lista,precio) VALUES 
(1,1,15000),(1,2,20000),(1,3,12000),
(2,1,12000),(2,2,15000),(2,3,10000),
(3,1,25000),(3,2,30000),(3,3,22000);

