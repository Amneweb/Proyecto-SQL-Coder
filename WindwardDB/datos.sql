INSERT INTO TIPO_DOCUMENTO VALUES ("DNI","Documento Nacional de Identidad"),
("CI","Cedula de Identidad"),("CUIT","Clave Unica de Identificacion Tributaria"),("CUIL","Clave Unica de Identificacion Laboral");

INSERT INTO ZONAS (nombre) VALUES ("Norte del GBA, hasta San Fernando"),
("Zarate"),("Oeste del GBA, hasta Gonzalez Catan"),("Sur del GBA, hasta La Plata");

INSERT INTO LISTAS (moneda, nombre, descripcion) VALUES ("ARS","50%","50% respecto al precio de lista"),("ARS","45 + 5%","5% sobre el 45% del precio de lista"),("ARS","45%","45% del precio de lista"),("ARS","MAYORISTA","Lista especial de EDNA");

INSERT INTO ESTADOS VALUES ("HEC","Pedido recien hecho por el cliente"),("APR","Pedido aprobado por administracion"),
("STO","Stock de productos ok"),("CAR","Pedido completo cargado en la camioneta"),("REP","Pedido en reparto"),("ENT","Pedido entregado");

INSERT INTO ROLES (nombre,descripcion) VALUES ("DEPOSITO","Encargado de deposito"),("ADMIN","Empleado de administracion"),("CHOFER","Chofer de vehiculos de reparto");

INSERT INTO PRODUCTOS (sku, nombre, descripcion, marca, dimension_longitud, dimension_ancho, dimension_alto, dimension_peso, stock) VALUES
	('FW90', 'Edna 12x75 FW90 Linea Premium', 'Batería de 12x75 amperes, calcio-plata, marca Edna, fabricada en Argentina', 'EDNA', 185, 140, 190, 18, 10),
	('FW70', 'Edna 12x65 FW70', 'Edna 12x65 FW70, especial para autos nafteros, Edna línea Premium', 'EDNA', 185, 135, 180, 14, 4),
	('FW100', 'Edna 12x100 FW100 Bora', 'Edna 12x65 FW70, especial para autos nafteros, Edna línea Premium', 'EDNA', 200, 150, 190, 23, 20);
INSERT INTO PRODUCTOS (sku, nombre, descripcion, marca, dimension_longitud, dimension_ancho, dimension_alto, dimension_peso, stock) VALUES
	('CL65PB', 'Clorex 12x75 FW90 Linea Premium', 'Batería de 12x75 amperes, calcio-plata, marca Edna, fabricada en Argentina', 'CLOREX', 185, 140, 190, 18, 40),
	('CL65PBS', 'Edna 12x65 FW70', 'Edna 12x65 FW70, especial para autos nafteros, Edna línea Premium', 'CLOREX', 185, 135, 180, 14, 45),
	('CL16019', 'Clorex 19 placas para colectivos', 'Edna 12x65 FW70, especial para autos nafteros, Edna línea Premium', 'CLOREX', 200, 150, 190, 23, 28);
	INSERT INTO PRODUCTOS VALUES
	(NULL,'CL23P180', 'Clorex 23 placas para colectivos', 'Clorex 180 para colectivos, 23 placas, garantia 1 año', 'CLOREX', 500, 200, 190, 50, 50),
	(NULL,'MB25', 'Edna 25 placas para colectivos', 'Edna para colectivos, garantia 1 año', 'CLOREX', 500, 200, 190, 50, 20)
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
("Insumos para vehiculos SRL","Delivery de baterias","CUIL","11111118","direccion 7","localidad 4","Buenos Aires",2,"nombre 20","01133333338",1);

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
VALUES (1, "APR", '2024-08-31','2024-08-31',NULL),
(5, "HEC", '2024-08-31','2024-08-31',NULL),
(7, "HEC", '2024-08-31','2024-08-31',NULL),
(8, "HEC", '2024-08-31','2024-08-31',NULL);

INSERT INTO PEDIDOS VALUES (NULL,8,"APR",'2024-08-31','2024-08-31',NULL),
(NULL,6,"HEC",'2024-08-31','2024-08-31',NULL);

INSERT INTO DETALLE_PEDIDOS (fk_id_pedido,fk_id_producto,cantidad)
VALUES (1,1,10),(1,2,5),(1,5,2),(2,2,3),(3,4,15),(3,2,5),(3,1,21),(4,2,20),(4,1,1);

INSERT INTO DETALLE_PEDIDOS
VALUES (11,1,10),(11,4,2),(11,3,2),(11,2,3),(12,4,6),(12,2,5),(12,1,13);

INSERT INTO ESTADOS VALUES ("SBY","Stand By, en espera de stock o lugar");

INSERT INTO VEHICULOS VALUES 
(NULL,"ZZZ-111-AA", "Mercedes Benz", "Sprinter Blanca", 2500,2000,200,10),
(NULL,"ZZZ-222-AA", "Mercedes Benz", "Sprinter Azul", 4500,3000,300,10),
(NULL,"ZZZ-333-AA", "Iveco", "Iveco", 2500,2000,200,10),
(NULL,"ZZZ-444-AA", "Renault", "Camion", 7000,5000,500,20);






