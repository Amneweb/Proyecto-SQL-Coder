-- Created by Amneweb
CREATE SCHEMA `windward` DEFAULT CHARACTER SET utf8 COLLATE utf8_spanish_ci ;

USE windward;
-- tables

-- Table: ZONA (5)
CREATE TABLE ZONAS (
    nombre varchar(20) NOT NULL,
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY
);
-- Table: DOCUMENTOS (2)
CREATE TABLE DOCUMENTOS (
    nombre_documento varchar(20) NULL,
    sigla varchar(5) NOT NULL PRIMARY KEY
);
-- Table: CLIENTES (1)
CREATE TABLE CLIENTES (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    razon_social varchar(50) NOT NULL,
    sobrenombre varchar(50) NULL,
    tipo_documento varchar(10) NOT NULL,
    nro_documento varchar(20) NOT NULL,
    direccion_calle varchar(50) NOT NULL,
    direccion_localidad varchar(20) NOT NULL,
    direccion_provincia varchar(20) NOT NULL,
    zona int NOT NULL,
    nombre_contacto varchar(50) NULL,
    celular_contacto varchar(20) NOT NULL,
    lista_precios int NOT NULL,
    FOREIGN KEY (tipo_documento) REFERENCES DOCUMENTOS (sigla),
    FOREIGN KEY (zona) REFERENCES ZONAS (id)
);
-- Table: PRODUCTOS (4)  
CREATE TABLE PRODUCTOS (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    sku varchar(10) UNIQUE NOT NULL,
    nombre varchar(50) NULL,
    descripcion MEDIUMTEXT NULL,
    marca varchar(20) NULL,
    dimension_longitud int NOT NULL,
    dimension_ancho int NOT NULL,
    dimension_alto int NOT NULL,
    dimension_peso dec(3,2) NOT NULL,
    nombre_contacto varchar(50) NULL,
    stock int NOT NULL default 1
);

-- Table: LISTAS (3)
CREATE TABLE LISTAS (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    moneda varchar(5) UNIQUE NOT NULL,
    nombre varchar(20) NULL,
    descripcion varchar(50) NULL
);

-- Table: VEHICULOS (6)
CREATE TABLE VEHICULOS (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    patente varchar(10) UNIQUE NOT NULL,
    marca varchar(10) NULL,
    apodo varchar(10) NULL,
    max_volumen int NOT NULL,
    max_peso DEC (5,2) NOT NULL,
    max_cantidades int NOT NULL
);

-- Table: PRECIOS (7)
CREATE TABLE PRECIOS (
    id int NOT NULL AUTO_INCREMENT,
    id_producto int NOT NULL,
    id_lista int NOT NULL,
    PRIMARY KEY (id, id_producto),
    FOREIGN KEY (id_producto) REFERENCES PRODUCTOS (id),
    FOREIGN KEY (id_lista) REFERENCES LISTAS (id)
);

-- Table: ESTADOS (10)
CREATE TABLE ESTADOS (
    codigo varchar(3) NOT NULL PRIMARY KEY,
    descripcion varchar(20) NOT NULL
);

-- Table: PEDIDOS (8)
CREATE TABLE PEDIDOS (
    id int NOT NULL AUTO_INCREMENT,
    id_cliente int NOT NULL,
    id_estado varchar(3) NOT NULL DEFAULT "R",
    fecha_pedido date NOT NULL DEFAULT (CURRENT_DATE),
    fecha_entrega date NOT NULL,
    fecha_efectiva_entrega date,
    PRIMARY KEY (id, id_cliente),
    FOREIGN KEY (id_cliente) REFERENCES CLIENTES (id),
    FOREIGN KEY (id_estado) REFERENCES ESTADOS (codigo)
);

-- Table: PEDIDOS (9)
CREATE TABLE DETALLE_PEDIDOS (
    id_pedido int NOT NULL ,
    id_producto int NOT NULL ,
    cantidad int NOT NULL DEFAULT 1,
PRIMARY KEY (id_pedido, id_producto),
    FOREIGN KEY (id_pedido) REFERENCES PEDIDOS (id),
    FOREIGN KEY (id_producto) REFERENCES PRODUCTOS (id)
);

-- Table: ESTADOS (12)
CREATE TABLE ROLES (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre varchar(10) NOT NULL,
    descripcion varchar(20) NULL
);

-- Table: EMPLEADOS (11)
CREATE TABLE EMPLEADOS (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre varchar(50) NOT NULL,
    tipo_documento varchar(10) NOT NULL,
    nro_documento varchar(20) NOT NULL,
    telefono varchar(20) NULL,
    rol int NOT NULL,
    FOREIGN KEY (tipo_documento) REFERENCES DOCUMENTOS (sigla),
    FOREIGN KEY (rol) REFERENCES ROLES (id)
);

-- Table: MODIFICACION_ESTADOS (13)
CREATE TABLE MODIFICACION_ESTADOS (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_pedido int NOT NULL,
    id_empleado int NOT NULL,
    hora_modificacion date NOT NULL default (CURRENT_TIMESTAMP),
    id_estado varchar(3) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES PEDIDOS (id),
    FOREIGN KEY (id_empleado) REFERENCES EMPLEADOS (id),
    FOREIGN KEY (id_estado) REFERENCES ESTADOS (codigo)
);

-- Table: REPARTOS (14)
CREATE TABLE REPARTOS (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_pedido int NOT NULL,
    id_vehiculo int NOT NULL,
    id_empleado int NOT NULL,
    kilometros int NULL,
    combustible dec (4,2)
);