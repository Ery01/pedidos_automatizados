-- Crear la tabla CLIENTES
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

CREATE TABLE ESCALA (
 id_escala INT,
 escala_proveedor varchar(50),
 PRIMARY KEY (id_escala),
);

-- Crear la tabla PRODUCTO
CREATE TABLE PRODUCTOS (
    codigo_barra VARCHAR(150),
    nombre_producto VARCHAR(150),
    precio INT,
    fecha_actualizacion_precio DATETIME,
    PRIMARY KEY (codigo_barra)
);

-- Crear la tabla PEDIDOS
CREATE TABLE PEDIDOS (
    id_pedido INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT,
    codigo_estado VARCHAR(20) CHECK (codigo_estado IN ('NO_REALIZADO', 'PENDIENTE', 'EN_PROCESO', 'ENVIADO', 'ENTREGADO', 'CANCELADO')),
    fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega_prevista DATETIME,
    fecha_entrega_real DATETIME,
    total INT,
    id_escala INT,
    FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente) ON DELETE SET NULL,
    FOREIGN KEY (id_escala) REFERENCES ESCALA(id_escala) ON DELETE SET NULL
);

-- Crear la tabla DETALLE_PEDIDOS
CREATE TABLE DETALLE_PEDIDOS (
    id_detalle INT IDENTITY(1,1) PRIMARY KEY,
    id_pedido INT, -- Relación con la tabla PEDIDOS
    codigo_barra_producto VARCHAR(150), -- Relación con la tabla PRODUCTO
    cantidad INT,
    precio_unitario INT,
    FOREIGN KEY (id_pedido) REFERENCES PEDIDOS(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (codigo_barra_producto) REFERENCES PRODUCTOS(codigo_barra) ON DELETE CASCADE
);

