-- Created by Amneweb
CREATE SCHEMA `windward2` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8_spanish_ci ;

USE windward2;
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

