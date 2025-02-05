-- Ahora puedes eliminar las tablas en el orden correcto
DROP TABLE IF EXISTS DETALLE_PEDIDO;
DROP TABLE IF EXISTS PEDIDOS;
DROP TABLE IF EXISTS ESTADOS_PEDIDOS;
DROP TABLE IF EXISTS PRODUCTOS;
DROP TABLE IF EXISTS ESCALA;
DROP TABLE IF EXISTS CLIENTES;
GO

CREATE TABLE CLIENTES (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nombre_cliente VARCHAR(150),
	token_api VARCHAR(150),
    direccion_cliente VARCHAR(255),
    telefono_cliente VARCHAR(50),
    mail_cliente VARCHAR(150),
    cuil_cliente VARCHAR(150),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);
GO

CREATE TABLE ESCALA (
	id_escala INT,
	descripcion varchar(50),
	PRIMARY KEY (id_escala),
);
GO

CREATE TABLE PRODUCTOS (
    codigo_barra VARCHAR(150),
    nombre VARCHAR(150),
    precio DECIMAL(10,2),
    fecha_actualizacion_precio DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (codigo_barra)
);
GO

CREATE TABLE PEDIDOS (
    id_pedido INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT,
    codigo_estado VARCHAR(20),
    fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega_prevista DATETIME,
    fecha_entrega_real DATETIME,
    total DECIMAL(10,2),
    id_escala INT,
	codigo_seguimiento VARCHAR(20),
    FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente) ON DELETE SET NULL,
    FOREIGN KEY (id_escala) REFERENCES ESCALA(id_escala) ON DELETE SET NULL
);
GO

CREATE TABLE ESTADOS_PEDIDOS (
	codigo VARCHAR(20) PRIMARY KEY,
	descripcion VARCHAR(100)
);
GO

CREATE TABLE DETALLE_PEDIDO (
    id_detalle INT IDENTITY(1,1) PRIMARY KEY,
    id_pedido INT,
    codigo_barra VARCHAR(150),
    cantidad INT,
    precio_unitario DECIMAL(10,2),
    FOREIGN KEY (id_pedido) REFERENCES PEDIDOS(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (codigo_barra) REFERENCES PRODUCTOS(codigo_barra) ON DELETE CASCADE
);
GO

INSERT INTO CLIENTES (nombre_cliente, token_api, direccion_cliente, telefono_cliente, mail_cliente, cuil_cliente)
VALUES
('Supermercado Principal', 'super123', 'Calle 123, Ciudad A', '123456789', 'contacto@supermercado.com', '20-98765432-1');
GO

INSERT INTO ESCALA (id_escala, descripcion)
VALUES
(1, 'LETRAS'),
(2, '1 AL 5'),
(3, '0 AL 100'),
(4, 'ESTRELLAS');
GO

INSERT INTO PRODUCTOS (codigo_barra, nombre, precio, fecha_actualizacion_precio)
VALUES
('1234567890123', 'Producto 1', 100.50, GETDATE()),
('2345678901234', 'Producto 2', 200.75, GETDATE());
GO

INSERT INTO ESTADOS_PEDIDOS (codigo, descripcion)
VALUES
('PENDIENTE', 'Pedido en espera de procesamiento.'),
('EN_PROCESO', 'Pedido en proceso de preparación.'),
('ENVIADO', 'Pedido enviado al cliente.'),
('ENTREGADO', 'Pedido entregado exitosamente.'),
('CANCELADO', 'Pedido cancelado por el cliente o sistema.');
GO

INSERT INTO PEDIDOS (id_cliente, codigo_estado, fecha_pedido, fecha_entrega_prevista, fecha_entrega_real, total, id_escala, codigo_seguimiento)
VALUES
(1, 'PENDIENTE', '2025-01-20', '2025-01-25', NULL, 1000.50, 1, 'TRACK123'),
(1, 'EN_PROCESO', '2025-01-20', '2025-01-27', '2025-01-26', 1500.75, 2, 'TRACK456');
GO

INSERT INTO DETALLE_PEDIDO (id_pedido, codigo_barra, cantidad, precio_unitario)
VALUES
(1, '1234567890123', 10, 100.50),
(2, '2345678901234', 5, 200.75);
GO

SELECT * FROM CLIENTES;
SELECT * FROM ESCALA;
SELECT * FROM PRODUCTOS;
SELECT * FROM ESTADOS_PEDIDOS;
SELECT * FROM PEDIDOS;
SELECT * FROM DETALLE_PEDIDO;
GO