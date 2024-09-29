-- --------------------------------------
-- TRIGGER add_new_pedido
-- --------------------------------------

-- Este trigger es para tomar el id generado al momento de cargar un pedido (como el id es autoincremental y se genera automáticamente, no lo sabemos de antemano, y me pareció que esta era una buena manera de obtenerlo y asegurarme de que sea el id que se genera en la misma conexión, cosa que no ocurriría haciendo un select del ultimo id generado porque si justo hubo un cliente que generó un pedido un segundo después, el select me devolvería un id de otro cliente)

CREATE TRIGGER `tr_add_new_pedido`
AFTER INSERT ON `PEDIDOS`
FOR EACH ROW
SET @idNuevoPedido = NEW.id_pedido;

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
SET @nuevo_stock = 0;
SET @msj="Las cantidades solicitadas de uno o varios de los productos son mayores al stock disponible. En esos casos el pedido se armó con el stock existente"; 
ELSE 
SET @nuevo_stock = @stock_existente - NEW.cantidad;
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
-- TRIGGER add_new_reparto
-- --------------------------------------

-- Este trigger es para tomar el id generado al momento de cargar un reparto y usar el mismo id para la tabla de detalle de repartos

CREATE TRIGGER `tr_add_new_reparto`
AFTER INSERT ON `REPARTOS`
FOR EACH ROW
SET @idNuevoReparto = NEW.id_reparto;

-- --------------------------------------
-- TRIGGER tr_pasar_a_reparto
-- --------------------------------------

-- Cambia el estado de los pedidos involucrados en un reparto determinado a "REP"

CREATE TRIGGER `tr_pasar_a_reparto`
AFTER INSERT ON `DETALLE_REPARTOS`
FOR EACH ROW
SET @idPedido = NEW.fk_id_pedido;
CALL sp_modificar_estado(@idPedido, 1, "REP")