-- Created by Amneweb
USE windward;
-- tables
-- Table: CLIENTES
CREATE TABLE CLIENTES (
    id_cliente int NOT NULL,
    razon_social varchar(50) NOT NULL,
    sobrenombre varchar(50) NULL,
    tipo_documento int NOT NULL,
    nro_documento varchar(20) NOT NULL,
    direccion_calle varchar(50) NOT NULL,
    direccion_localidad varchar(20) NOT NULL,
    direccion_provincia varchar(20) NOT NULL,
    zona int NULL,
    nombre_contacto varchar(50) NULL,
    celular_contacto varchar(20) NOT NULL,
    lista_precios int NOT NULL,
    CONSTRAINT PK_CLIENTES PRIMARY KEY (id_cliente)
);
CREATE TABLE DOCUMENTOS (
    id_tipo_documento int NOT NULL,
    nombre_documento varchar(20) NULL,
    sigla_documento varchar(5) NOT NULL,
    CONSTRAINT PK_DOCUMENTOS PRIMARY KEY (id_tipo_documento)
);  
CREATE TABLE PRODUCTOS (
    id_producto int NOT NULL,
    sku varchar(10) UNIQUE NOT NULL,
    nombre_producto varchar(50) NULL,
    descripcion_producto MEDIUMTEXT NULL,
    marca_producto varchar(20) NULL,
    dimension_longitud int NOT NULL,
    dimension_ancho int NOT NULL,
    dimension_alto int NOT NULL,
    dimension_peso dec(3,2) NOT NULL,
    nombre_contacto varchar(50) NULL,
    stock int NOT NULL default 1,
    CONSTRAINT PK_PRODUCTOS PRIMARY KEY (id_producto)
);
-- foreign keys
-- Reference: FK_CLIENTE_TIPO_DOCUMENTO (table: CLIENTES)
ALTER TABLE CLIENTES ADD CONSTRAINT FK_CLIENTE_TIPO_DOCUMENTO FOREIGN KEY FK_CLIENTE_TIPO_DOCUMENTO (tipo_documento)
    REFERENCES DOCUMENTOS (id_tipo_documento);