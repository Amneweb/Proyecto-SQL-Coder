-- Ejemplo de llamado al SP. Hay que tener cuidado con el id del cliente. Como se genera automáticamente, no sé si en las tablas de prueba llega a existir el id '15'
CALL sp_generar_pedidos (15,'[{"producto":1,"cantidad":2},{"producto":2,"cantidad":10}]');

SELECT * FROM windward.pedidos_por_cliente;