-- Tabla USUARIOS
CREATE TABLE USUARIOS (
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    usuario VARCHAR(50),
    clave VARCHAR(50) 
);
GO

-- Tabla PROVEEDORES con información de configuración integrada
CREATE TABLE PROVEEDORES (
    id_proveedor INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50),
    cuil VARCHAR(150),
    mail VARCHAR(150),
    nombre_url VARCHAR(150),  -- URL del proveedor para conexión
    token VARCHAR(150),       -- Token de autenticación para conexión
    tecnologia VARCHAR(50),
    habilitado BIT DEFAULT 0,
	puntaje DECIMAL (10,2),
    fecha_actualizacion_proveedor DATETIME
);
GO

-- Tabla PRODUCTOS
CREATE TABLE PRODUCTOS (
    codigo_barra VARCHAR(150) PRIMARY KEY,
    nombre VARCHAR(150),
    imagen_contenido VARBINARY(MAX),
    stock_actual INT,
    stock_minimo INT
);
GO

-- Tabla PRODUCTO_PROVEEDOR
CREATE TABLE PRODUCTO_PROVEEDOR (
    codigo_barra VARCHAR(150),
    id_proveedor INT,
    precio INT,
    PRIMARY KEY (codigo_barra, id_proveedor),
    FOREIGN KEY (codigo_barra) REFERENCES PRODUCTOS(codigo_barra),
    FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor)
);
GO

-- Tabla de dominio: EstadosPedido
CREATE TABLE ESTADOS_PEDIDO (
    Codigo VARCHAR(20) PRIMARY KEY, -- Código único para identificar el estado
    Descripcion VARCHAR(100) NOT NULL -- Descripción legible del estado
);
GO

-- Tabla PEDIDOS (con relación a EstadosPedido)
CREATE TABLE PEDIDOS (
    id_pedido INT IDENTITY(1,1) PRIMARY KEY,
    id_proveedor INT,
    estado VARCHAR(20) NOT NULL, -- Referencia a EstadosPedido
    codigo_seguimiento VARCHAR(20),
	fecha_entrega_prevista DATETIME,
    fecha_entrega_real DATETIME,
    fecha_pedido DATETIME,
    total INT,
	--id_escala INT,
	evaluacion_pedido VARCHAR(20),
	fecha_evaluacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor),
    FOREIGN KEY (estado) REFERENCES ESTADOS_PEDIDO(Codigo)
	--FOREIGN KEY (id_escala) REFERENCES ESCALA_PROVEEDORES(id_escala)
);
GO

-- Tabla DETALLE_PEDIDO
CREATE TABLE DETALLE_PEDIDO (
    id_pedido INT,
    codigo_barra VARCHAR(150),
    cantidad INT,
    precio_unitario INT,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_pedido, codigo_barra),
    FOREIGN KEY (id_pedido) REFERENCES PEDIDOS(id_pedido),
    FOREIGN KEY (codigo_barra) REFERENCES PRODUCTOS(codigo_barra)
);
GO

-- Tabla RANKING_PROVEEDOR 
CREATE TABLE RANKING_PROVEEDOR (
    id_ranking_proveedor INT IDENTITY(1,1) PRIMARY KEY, -- Agregado como clave primaria autoincremental
    id_proveedor INT,           -- Referencia al proveedor dueño de la tabla
    valor_original VARCHAR(50), -- Valor dado por el proveedor (ej: "Bueno", "4 estrellas")
    ponderacion DECIMAL(10,2),  -- Valor normalizado (ej: Bueno=6, 4 estrellas=8)
    descripcion_valor VARCHAR(50),
    FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor)
);

INSERT INTO USUARIOS (usuario, clave)
VALUES 
('admin', 'admin123'),
('operador', 'operador123');
GO

INSERT INTO PROVEEDORES (nombre, cuil, mail, nombre_url, token, tecnologia, habilitado, puntaje, fecha_actualizacion_proveedor)
VALUES 
('Proveedor A', '20-12345678-9', 'contacto@proveedora.com', 'proveedora', 'token123', 'API', 1, 4.5, CAST(GETDATE() AS DATE)),
('Proveedor B', '30-87654321-9', 'info@proveedorb.com', 'proveedorb', 'token456', 'API', 1, 3.8, CAST(GETDATE() AS DATE)),
('Proveedor C', '40-11111111-1', 'contacto@proveedorc.com', 'proveedorc', 'token789', 'API', 1, 4.0, CAST(GETDATE() AS DATE)),
('Proveedor D', '50-22222222-2', 'contacto@proveedord.com', 'proveedord', 'token101', 'API', 1, 3.5, CAST(GETDATE() AS DATE));
GO

-- INSERTS para PRODUCTOS
INSERT INTO PRODUCTOS (codigo_barra, nombre, imagen_contenido, stock_actual, stock_minimo)
VALUES 
('1234567890123', 'Producto 1', NULL, 50, 10),
('2345678901234', 'Producto 2', NULL, 20, 5);
GO

-- INSERTS para PRODUCTO_PROVEEDOR
INSERT INTO PRODUCTO_PROVEEDOR (codigo_barra, id_proveedor, precio)
VALUES 
('1234567890123', 1, 100.50),
('2345678901234', 2, 200.75);
GO

-- INSERTS para ESTADOS_PEDIDO
INSERT INTO ESTADOS_PEDIDO (Codigo, Descripcion)
VALUES
('PENDIENTE', 'Pedido en espera de procesamiento.'),
('EN_PROCESO', 'Pedido en proceso de preparación.'),
('ENVIADO', 'Pedido enviado al cliente.'),
('ENTREGADO', 'Pedido entregado exitosamente.'),
('CANCELADO', 'Pedido cancelado por el cliente o sistema.');
GO

INSERT INTO PEDIDOS (id_proveedor, estado, codigo_seguimiento, fecha_entrega_prevista, fecha_entrega_real, fecha_pedido, total, evaluacion_pedido, fecha_evaluacion)
VALUES 
(1, 'PENDIENTE', 'TRACK123', '2025-01-25', NULL, '2025-01-20', 1000.50, NULL, NULL),
(2, 'EN_PROCESO', 'TRACK456', '2025-01-27', '2025-01-26', '2025-01-20', 1500.75, '4.2', '2025-01-27');

-- INSERTS para DETALLE_PEDIDO
INSERT INTO DETALLE_PEDIDO (id_pedido, codigo_barra, cantidad, precio_unitario, fecha_registro)
VALUES 
(1, '1234567890123', 10, 100.50, '2025-01-20'),
(2, '2345678901234', 5, 200.75, '2025-01-20');
GO

-- Proveedor 1
INSERT INTO RANKING_PROVEEDOR (id_proveedor, valor_original, ponderacion, descripcion_valor)
VALUES
(1, 'A', 1.0, 'Excelente'),
(1, 'B', 0.8, 'Muy Bueno'),
(1, 'C', 0.6, 'Bueno'),
(1, 'D', 0.4, 'Regular'),
(1, 'E', 0.2, 'Malo');
GO

-- Proveedor 2
INSERT INTO RANKING_PROVEEDOR (id_proveedor, valor_original, ponderacion, descripcion_valor)
VALUES
(2, 5, 1.0, 'Excelente'),
(2, 4, 0.8, 'Muy Bueno'),
(2, 3, 0.6, 'Bueno'),
(2, 2, 0.4, 'Regular'),
(2, 1, 0.2, 'Malo');
GO

-- Proveedor 3
INSERT INTO RANKING_PROVEEDOR (id_proveedor, valor_original, ponderacion, descripcion_valor)
VALUES
(3, 100, 1.0, 'Excelente'),
(3, 80, 0.8, 'Muy Bueno'),
(3, 60, 0.6, 'Bueno'),
(3, 40, 0.4, 'Regular'),
(3, 20, 0.2, 'Malo');
GO

-- Proveedor 4
INSERT INTO RANKING_PROVEEDOR (id_proveedor, valor_original, ponderacion, descripcion_valor)
VALUES
(4, '*****', 1.0, 'Excelente'),
(4, '****', 0.8, 'Muy Bueno'),
(4, '***', 0.6, 'Bueno'),
(4, '**', 0.4, 'Regular'),
(4, '*', 0.2, 'Malo');
GO

-- Verificar contenido de la tabla USUARIOS
SELECT * FROM USUARIOS;

-- Verificar contenido de la tabla ESTADOS_PEDIDO
SELECT * FROM ESTADOS_PEDIDO;

-- Verificar contenido de la tabla PROVEEDORES
SELECT * FROM PROVEEDORES;

-- Verificar contenido de la tabla PRODUCTOS
SELECT * FROM PRODUCTOS;

-- Verificar contenido de la tabla PRODUCTO_PROVEEDOR
SELECT * FROM PRODUCTO_PROVEEDOR;

-- Verificar contenido de la tabla RANKING_PROVEEDOR
SELECT * FROM RANKING_PROVEEDOR;

-- Verificar contenido de la tabla PEDIDOS
SELECT * FROM PEDIDOS;

-- Verificar contenido de la tabla DETALLE_PEDIDO
SELECT * FROM DETALLE_PEDIDO;
GO

-- Eliminar tablas dependientes primero
DROP TABLE IF EXISTS DETALLE_PEDIDO;
DROP TABLE IF EXISTS PEDIDOS;
DROP TABLE IF EXISTS RANKING_PROVEEDOR;
DROP TABLE IF EXISTS PRODUCTO_PROVEEDOR;

-- Eliminar tablas principales
DROP TABLE IF EXISTS ESCALA_PROVEEDORES;
DROP TABLE IF EXISTS ESTADOS_PEDIDO;
DROP TABLE IF EXISTS PRODUCTOS;
DROP TABLE IF EXISTS PROVEEDORES;
DROP TABLE IF EXISTS USUARIOS;
GO