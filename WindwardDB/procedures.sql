-- 1) CARGAR UN PEDIDO 
-- 1.a Carga un nuevo registro en la tabla de pedidos, ingresando el id del cliente, la fecha y el estado del pedido que será "HEC"
-- 1.b Teniendo el id del pedido generado cuando insertamos el registro, generamos los registros en la tabla detalle de pedidos en base al id mencionado y al array de productos
-- Los datos de entrada son: id de cliente, array de productos [id_producto, cantidad]

USE windward;

----------------------------------------
-- TRIGGER add_new_pedido
----------------------------------------

-- Este trigger es para tomar el id generado al momento de cargar un pedido (como el id es autoincremental y se genera automáticamente, no lo sabemos de antemano, y me pareció 
-- que esta era una buena manera de obtenerlo y asegurarme de que sea el id que se genera en la misma conexión, cosa que no ocurriría haciendo un select del ultimo id generado 
-- porque si justo hubo un cliente que generó un pedido un segundo después, el select me devolvería un id de otro cliente)
CREATE TRIGGER `tr_add_new_pedido`
AFTER INSERT ON `PEDIDOS`
FOR EACH ROW
SET @idNuevoPedido = NEW.id_pedido;

----------------------------------------
-- SP sp_generar_pedidos
----------------------------------------

-- Este SP es para agregar los productos y las respectivas cantidades a la tabla detalle de pedidos, y toma como dato el id generado en la tabla PEDIDOS, que lo recupero con el trigger anterior. Los datos de entrada son:
-- 1) El id del cliente
-- 2) Un json con los productos y las cantidades
-- Los pasos del SP son:
-- 1) Inserta el pedido en la tabla PEDIDOS, con el id del cliente, el estado del pedido que en este caso es "HEC" (hecho), y las fechas del pedido y programadasa de entrega
-- 2) Una vez insertado el pedido, el trigger devuelve el nuevo id del pedido
-- 3) Convierte los datos del json en una tabla provisoria
-- 4) Guarda los datos de la tabla provisoria junto con el id del pedido en la tabla detalle de pedidos
-- 5) Borra la tabla provisoria
DELIMITER $$
CREATE PROCEDURE `sp_generar_pedidos` (IN id_cliente INT, IN json_pedido JSON)
BEGIN
INSERT INTO PEDIDOS (fk_id_cliente, fk_id_estado, fecha_pedido, fecha_entrega, fecha_efectiva_entrega)
VALUES (id_cliente, "HEC", CURDATE(),CURDATE(),NULL);
CREATE TABLE detalle_provisorio 
(producto INT NOT NULL,
cantidad INT NOT NULL);
INSERT INTO detalle_provisorio (producto, cantidad) SELECT * FROM JSON_TABLE(json_pedido,"$[*]" COLUMNS (
    fk_id_producto INT PATH "$.producto", cantidad INT PATH "$.cantidad"
)) AS detalles_json;

    INSERT INTO DETALLE_PEDIDOS (fk_id_producto, cantidad,fk_id_pedido ) (SELECT producto, cantidad, @idNuevoPedido FROM detalle_provisorio );
DROP TABLE detalle_provisorio;
END $$

----------------------------------------
-- FUNCION fn_generar_variable_lista
----------------------------------------
-- Función para poder usar la variable id_lista en la vista de precios por lista en base al id del cliente (para poder usar el id del cliente como variable y no como valor fijo en la cláusula de WHERE)
CREATE FUNCTION `fn_generar_variable_lista` (cliente INT) RETURNS INT DETERMINISTIC RETURN (SELECT fk_lista_precios FROM CLIENTES WHERE id_cliente = cliente);
