
DROP TABLE IF EXISTS DETALLE_PEDIDO;
DROP TABLE IF EXISTS PEDIDOS;
DROP TABLE IF EXISTS RANKING_PROVEEDOR;
DROP TABLE IF EXISTS PRODUCTO_PROVEEDOR;
DROP TABLE IF EXISTS ESCALA_PROVEEDORES;
DROP TABLE IF EXISTS ESTADOS_PEDIDO;
DROP TABLE IF EXISTS PRODUCTOS;
DROP TABLE IF EXISTS PROVEEDORES;
DROP TABLE IF EXISTS USUARIOS;
GO

CREATE TABLE USUARIOS (
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    usuario VARCHAR(50),
    clave VARCHAR(50) 
);
GO

CREATE TABLE PROVEEDORES (
    id_proveedor INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50),
    cuil VARCHAR(15),
    mail VARCHAR(150),
    nombre_url VARCHAR(150), 
    token VARCHAR(150),     
    tecnologia VARCHAR(50),
    habilitado BIT DEFAULT 0,
	puntaje DECIMAL (10,2),
    fecha_actualizacion_proveedor DATETIME
);
GO

CREATE TABLE PRODUCTOS (
    codigo_barra VARCHAR(150) PRIMARY KEY,
    nombre VARCHAR(150),
    imagen_contenido VARBINARY(MAX),
    stock_actual INT,
    stock_minimo INT
);
GO

CREATE TABLE PRODUCTO_PROVEEDOR (
    codigo_barra VARCHAR(150),
    id_proveedor INT,
    precio DECIMAL(10,2),
	fecha_actualizacion_precio DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (codigo_barra, id_proveedor),
    FOREIGN KEY (codigo_barra) REFERENCES PRODUCTOS(codigo_barra),
    FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor)
);
GO

CREATE TABLE ESCALA_PROVEEDORES (
    id_escala INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(50)
);
GO

CREATE TABLE ESTADOS_PEDIDO (
    codigo VARCHAR(20) PRIMARY KEY, 
    descripcion VARCHAR(100) NOT NULL 
);
GO

CREATE TABLE PEDIDOS (
    id_pedido INT IDENTITY(1,1) PRIMARY KEY,
    id_proveedor INT,
    estado VARCHAR(20) NOT NULL,
    codigo_seguimiento VARCHAR(50),
	fecha_entrega_prevista DATE,
    fecha_entrega_real DATETIME,
    fecha_pedido DATETIME,
    total DECIMAL(10,2) NULL,
	evaluacion DECIMAL(10,2) NULL,
	fecha_evaluacion DATETIME NULL,
    FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor),
    FOREIGN KEY (estado) REFERENCES ESTADOS_PEDIDO(Codigo)
);
GO

CREATE TABLE DETALLE_PEDIDO (
    id_pedido INT,
    codigo_barra VARCHAR(150),
    cantidad INT,
    precio_unitario DECIMAL(10,2),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_pedido, codigo_barra),
    FOREIGN KEY (id_pedido) REFERENCES PEDIDOS(id_pedido),
    FOREIGN KEY (codigo_barra) REFERENCES PRODUCTOS(codigo_barra)
);
GO

CREATE TABLE RANKING_PROVEEDOR (
    id_ranking_proveedor INT IDENTITY(1,1) PRIMARY KEY,
    id_escala INT,
	id_proveedor INT,          
    valor_original VARCHAR(50),
    ponderacion DECIMAL(10,2),
    descripcion_valor VARCHAR(50),
    FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor),
	FOREIGN KEY (id_escala) REFERENCES ESCALA_PROVEEDORES(id_escala)
);
GO

-- ///////////////////////////////////////////////////////////////////////////////////////////////////

INSERT INTO USUARIOS (usuario, clave) 
VALUES 
('admin', 'admin123'),
('operador', 'operador123');
GO

INSERT INTO PROVEEDORES (nombre, cuil, mail, nombre_url, token, tecnologia, habilitado, puntaje)
VALUES 
('Proveedor A', '20-12345678-9', 'contacto@proveedora.com', 'proveedora', 'token123', 'REST', 1, 4.5),
('Proveedor B', '30-87654321-9', 'info@proveedorb.com', 'proveedorb', 'token456', 'REST', 1, 3.8),
('Proveedor C', '40-11111111-1', 'contacto@proveedorc.com', 'proveedorc', 'token789', 'SOAP', 1, 4.0),
('Proveedor D', '50-22222222-2', 'contacto@proveedord.com', 'proveedord', 'token101', 'SOAP', 1, 3.5);
GO

INSERT INTO PRODUCTOS (codigo_barra, nombre, stock_actual, stock_minimo)
VALUES 
('1234567890123', 'Producto A', 5, 10),
('9876543210987', 'Producto B', 8, 8),
('1112223334445', 'Producto C', 12, 12),
('5556667778889', 'Producto D', 9, 9),
('9998887776665', 'Producto E', 30, 15),
('1122334455667', 'Producto F', 10, 10),
('2233445566778', 'Producto G', 5, 5),
('3344556677889', 'Producto H', 14, 14);

INSERT INTO PRODUCTO_PROVEEDOR (id_proveedor, codigo_barra, precio)
VALUES 
(1, '1234567890123', 1050),
(2, '1234567890123', 1050),
(3, '1234567890123', 1100),
(4, '1234567890123', 1000),

(1, '9876543210987', 750),
(2, '9876543210987', 800),
(3, '9876543210987', 750),
(4, '9876543210987', 850),

(1, '1112223334445', 1300),
(2, '1112223334445', 1350),
(3, '1112223334445', 1300),
(4, '1112223334445', 1250),

(1, '5556667778889', 950),
(2, '5556667778889', 900),
(3, '5556667778889', 950),
(4, '5556667778889', 1000),

(1, '9998887776665', 600),
(2, '9998887776665', 600),
(3, '9998887776665', 650),
(4, '9998887776665', 650),

(1, '1122334455667', 1400),
(2, '1122334455667', 1450),
(3, '1122334455667', 1500),
(4, '1122334455667', 1400),

(1, '2233445566778', 700),
(2, '2233445566778', 750),
(3, '2233445566778', 650),
(4, '2233445566778', 750),

(1, '3344556677889', 1250),
(2, '3344556677889', 1200),
(3, '3344556677889', 1250),
(4, '3344556677889', 1300);

INSERT INTO ESTADOS_PEDIDO (codigo, descripcion)
VALUES
('PENDIENTE', 'Pedido en espera de procesamiento.'),
('EN PROCESO', 'Pedido en proceso de preparación.'),
('ENVIADO', 'Pedido enviado al cliente.'),
('ENTREGADO', 'Pedido entregado exitosamente.'),
('EVALUADO', 'Pedido evaluado por el cliente.'),
('CANCELADO', 'Pedido cancelado por el cliente o sistema.');
GO

/*INSERT INTO PEDIDOS (id_proveedor, estado, codigo_seguimiento, fecha_entrega_prevista, total)
VALUES 
(1, 'PENDIENTE', 'TRACK123', '2025-01-25', 1000),
(2, 'EN PROCESO', 'TRACK456', '2025-01-27', 1200);
GO*/

/*INSERT INTO DETALLE_PEDIDO (id_pedido, codigo_barra, cantidad, precio_unitario)
VALUES 
(1, '1234567890123', 10, 100),
(2, '2345678901234', 6, 200);
GO*/

INSERT INTO ESCALA_PROVEEDORES(descripcion) 
VALUES
('LETRAS'),
('1 AL 5'),
('0 AL 100'),
('ESTRELLAS');
GO

INSERT INTO RANKING_PROVEEDOR (id_proveedor, id_escala, valor_original, ponderacion, descripcion_valor)
VALUES
(1, 1, 'A', 1.0, 'Excelente'),
(1, 1, 'B', 0.8, 'Muy Bueno'),
(1, 1, 'C', 0.6, 'Bueno'),
(1, 1, 'D', 0.4, 'Regular'),
(1, 1, 'E', 0.2, 'Malo');
GO

INSERT INTO RANKING_PROVEEDOR (id_proveedor, id_escala, valor_original, ponderacion, descripcion_valor)
VALUES
(2, 2, 5, 1.0, 'Excelente'),
(2, 2, 4, 0.8, 'Muy Bueno'),
(2, 2, 3, 0.6, 'Bueno'),
(2, 2, 2, 0.4, 'Regular'),
(2, 2, 1, 0.2, 'Malo');
GO

INSERT INTO RANKING_PROVEEDOR (id_proveedor, id_escala, valor_original, ponderacion, descripcion_valor)
VALUES
(3, 3, 100, 1.0, 'Excelente'),
(3, 3, 80, 0.8, 'Muy Bueno'),
(3, 3, 60, 0.6, 'Bueno'),
(3, 3, 40, 0.4, 'Regular'),
(3, 3, 20, 0.2, 'Malo');
GO

INSERT INTO RANKING_PROVEEDOR (id_proveedor, id_escala, valor_original, ponderacion, descripcion_valor)
VALUES
(4, 4, 5, 1.0, 'Excelente'),
(4, 4, 4, 0.8, 'Muy Bueno'),
(4, 4, 3, 0.6, 'Bueno'),
(4, 4, 2, 0.4, 'Regular'),
(4, 4, 1, 0.2, 'Malo');
GO

-- ///////////////////////////////////////////////////////////////////////////////////////////////////

SELECT * FROM USUARIOS;
SELECT * FROM ESTADOS_PEDIDO;
SELECT * FROM PROVEEDORES;
SELECT * FROM PRODUCTOS;
SELECT * FROM PRODUCTO_PROVEEDOR;
SELECT * FROM ESCALA_PROVEEDORES;
SELECT * FROM RANKING_PROVEEDOR;
SELECT * FROM PEDIDOS;
SELECT * FROM DETALLE_PEDIDO;
GO

-- ///////////////////////////////////////////////////////////////////////////////////////////////////