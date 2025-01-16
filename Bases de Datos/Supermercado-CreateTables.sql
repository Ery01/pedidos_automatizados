-- Tabla USUARIOS
CREATE TABLE USUARIOS (
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    usuario VARCHAR(50),
    clave VARCHAR(50) 
);

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
    fecha_actualizacion_proveedor DATETIME
);

-- Tabla PRODUCTOS
CREATE TABLE PRODUCTOS (
    codigo_barra VARCHAR(150) PRIMARY KEY,
    nombre VARCHAR(150),
    imagen_contenido VARBINARY(MAX),
    stock_actual INT,
    stock_minimo INT
);

-- Tabla PRODUCTO_PROVEEDOR
CREATE TABLE PRODUCTO_PROVEEDOR (
    codigo_barra VARCHAR(150),
    id_proveedor INT,
    precio INT,
    PRIMARY KEY (codigo_barra, id_proveedor),
    FOREIGN KEY (codigo_barra) REFERENCES PRODUCTOS(codigo_barra),
    FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor)
);

-- Tabla de dominio: EstadosPedido
CREATE TABLE ESTADOS_PEDIDO (
    Codigo VARCHAR(20) PRIMARY KEY, -- Código único para identificar el estado
    Descripcion VARCHAR(100) NOT NULL -- Descripción legible del estado
);

-- Insertar los estados en la tabla EstadosPedido
INSERT INTO ESTADOS_PEDIDO (Codigo, Descripcion)
VALUES
('PENDIENTE', 'Pedido en espera de procesamiento.'),
('EN_PROCESO', 'Pedido en proceso de preparación.'),
('ENVIADO', 'Pedido enviado al cliente.'),
('ENTREGADO', 'Pedido entregado exitosamente.'),
('CANCELADO', 'Pedido cancelado por el cliente o sistema.');

CREATE TABLE ESCALA_PROVEEDORES (
 id_escala INT,
 escala_proveedor varchar(50),
 PRIMARY KEY (id_escala),
);

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
	id_escala INT,
	fecha_evaluacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor),
    FOREIGN KEY (estado) REFERENCES ESTADOS_PEDIDO(Codigo),
	FOREIGN KEY (id_escala) REFERENCES ESCALA_PROVEEDORES(id_escala)
);

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

-- Tabla RANKING_PROVEEDOR (rediseñada sin id_ranking)
CREATE TABLE RANKING_PROVEEDOR (
    id_escala INT,             -- Referencia al pedido evaluado
    id_proveedor INT,          -- Referencia al proveedor evaluado
    valor_original VARCHAR(50),  -- Valor dado por el proveedor (ej: "Bueno", "4 estrellas")
    ponderacion INT,           -- Valor normalizado (ej: Bueno=6, 4 estrellas=8)
	descripcion_valor VARCHAR(50),
    PRIMARY KEY (id_escala, id_proveedor), -- Clave primaria compuesta
    FOREIGN KEY (id_escala) REFERENCES ESCALA_PROVEEDORES(id_escala), -- Relación con PEDIDOS
    FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor)
);

-- Proveedor 1
INSERT INTO RANKING_PROVEEDOR (id_proveedor, valor_original, ponderacion, descripcion_valor)
VALUES
(1, 'A', 1.0, 'Excelente'),
(1, 'B', 0.8, 'Muy Bueno'),
(1, 'C', 0.6, 'Bueno'),
(1, 'D', 0.4, 'Regular'),
(1, 'E', 0.2, 'Malo');

-- Proveedor 2
INSERT INTO RANKING_PROVEEDOR (id_proveedor, valor_original, ponderacion, descripcion_valor)
VALUES
(2, 5, 1.0, 'Excelente'),
(2, 4, 0.8, 'Muy Bueno'),
(2, 3, 0.6, 'Bueno'),
(2, 2, 0.4, 'Regular'),
(2, 1, 0.2, 'Malo');

-- Proveedor 3
INSERT INTO RANKING_PROVEEDOR (id_proveedor, valor_original, ponderacion, descripcion_valor)
VALUES
(3, 100, 1.0, 'Excelente'),
(3, 80, 0.8, 'Muy Bueno'),
(3, 60, 0.6, 'Bueno'),
(3, 40, 0.4, 'Regular'),
(3, 20, 0.2, 'Malo');

-- Proveedor 4
INSERT INTO RANKING_PROVEEDOR (id_proveedor, valor_original, ponderacion, descripcion_valor)
VALUES
(4, '*****', 1.0, 'Excelente'),
(4, '****', 0.8, 'Muy Bueno'),
(4, '***', 0.6, 'Bueno'),
(4, '**', 0.4, 'Regular'),
(4, '*', 0.2, 'Malo');