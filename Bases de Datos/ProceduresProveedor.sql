
--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_CONFIGURACION
AS
BEGIN 
DECLARE @jsonResult NVARCHAR(MAX);

    SELECT @jsonResult = (
        SELECT * 
        FROM CLIENTES 
        FOR JSON AUTO
    );

    SELECT @jsonResult AS Configuracion;
	END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER  PROCEDURE dbo.OBTENER_PRODUCTOS
AS
BEGIN
DECLARE @jsonResult NVARCHAR(MAX);

    SELECT @jsonResult = (
        SELECT * 
        FROM PRODUCTOS 
        FOR JSON AUTO
    );

    SELECT @jsonResult AS Productos;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_ESCALA
AS
BEGIN
  DECLARE @jsonResult NVARCHAR(MAX);

    SELECT @jsonResult = (
        SELECT * 
        FROM ESCALA 
        FOR JSON AUTO
    );
	
    SELECT @jsonResult AS Escala;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_PEDIDO @json VARCHAR(max)
AS
DECLARE
@codigo_seguimiento VARCHAR(150) = (SELECT codigo_seguimiento = JSON_VALUE(@json, '$.codigo_seguimiento') )
BEGIN
		
DECLARE @jsonResult NVARCHAR(MAX);

    SELECT @jsonResult = (
        SELECT * 
        FROM PEDIDOS 
		WHERE codigo_seguimiento = @codigo_seguimiento
        FOR JSON AUTO
    );

    SELECT @jsonResult AS Pedido;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER   PROCEDURE dbo.OBTENER_PEDIDOS
AS
BEGIN 
DECLARE @jsonResult NVARCHAR(MAX);

    SELECT @jsonResult = (
        SELECT * 
		FROM PEDIDOS 
		ORDER BY fecha_pedido DESC,
				 CASE codigo_estado
				 WHEN 'PENDIENTE' THEN 1
				 WHEN 'EN_PROCESO' THEN 2
				 WHEN 'ENVIADO' THEN 3
				 WHEN 'ENTREGADO' THEN 4
				 WHEN 'CANCELADO' THEN 5
				 ELSE 6
		END
        FOR JSON AUTO
    );

    SELECT @jsonResult AS Pedidos
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.CANCELAR_PEDIDO
    @json VARCHAR(max)
AS
DECLARE
@codigo_seguimiento VARCHAR(150) = JSON_VALUE(@json, '$.codigo_seguimiento')
DECLARE @jsonResult NVARCHAR(MAX);
BEGIN

	IF EXISTS (SELECT 1 FROM PEDIDOS WHERE codigo_seguimiento = @codigo_seguimiento AND codigo_estado IN ('PENDIENTE'))
    BEGIN
        -- Si el codigo_estado es 'PENDIENTE' , lo cambia a CANCELADO  
		UPDATE PEDIDOS
	    SET codigo_estado = 'CANCELADO'
		WHERE codigo_seguimiento = @codigo_seguimiento

		 SELECT @jsonResult = (
            SELECT *
            FROM PEDIDOS
            WHERE codigo_seguimiento = @codigo_seguimiento
            FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
        );
		
        SELECT @jsonResult AS PedidoCancelado;
    END
    ELSE
    BEGIN
        RAISERROR('El pedido no está en estado PENDIENTE o no EXISTE. No se puede cancelar.', 16, 1);
    END	
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.INSERTAR_DETALLE
    @id_pedido INT,
    @json NVARCHAR(MAX)
AS
BEGIN
    DECLARE @total DECIMAL(18, 2) = 0;

    DECLARE @json_table TABLE (
        codigo_barra NVARCHAR(150),
        cantidad INT
    );

    INSERT INTO @json_table (codigo_barra, cantidad)
    SELECT codigo_barra, cantidad
    FROM OPENJSON(@json)
    WITH (
        codigo_barra NVARCHAR(150) '$.codigo_barra',
        cantidad INT '$.cantidad'
    );

    DECLARE @codigo_barra NVARCHAR(150);
    DECLARE @cantidad INT;
    DECLARE @precio_unitario DECIMAL(18, 2);

    DECLARE detalle_cursor CURSOR FOR
    SELECT codigo_barra, cantidad FROM @json_table;

    OPEN detalle_cursor;
    FETCH NEXT FROM detalle_cursor INTO @codigo_barra, @cantidad;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @precio_unitario = precio
        FROM PRODUCTOS
        WHERE codigo_barra = @codigo_barra;

        IF @precio_unitario IS NULL
        BEGIN
            RAISERROR('No se encontró el precio para el código de barra: %s', 16, 1, @codigo_barra);
            CLOSE detalle_cursor;
            DEALLOCATE detalle_cursor;
            RETURN;
        END

        SET @total = @total + (@precio_unitario * @cantidad);

        INSERT INTO DETALLE_PEDIDO (
            id_pedido,
            codigo_barra,
            cantidad,
            precio_unitario
        ) VALUES (
            @id_pedido,
            @codigo_barra,
            @cantidad,
            @precio_unitario
        );

        FETCH NEXT FROM detalle_cursor INTO @codigo_barra, @cantidad;
    END;

    CLOSE detalle_cursor;
    DEALLOCATE detalle_cursor;

    UPDATE PEDIDOS
    SET total = @total
    WHERE id_pedido = @id_pedido;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.INSERTAR_PEDIDO
    @id_cliente INT,
    @json NVARCHAR(MAX),
    @codigo_seguimiento NVARCHAR(150) OUTPUT
AS
BEGIN
    DECLARE @fecha_actual DATETIME = GETDATE();
    DECLARE @nuevo_id_pedido TABLE (id_pedido INT);
    DECLARE @id_pedido INT;

    INSERT INTO PEDIDOS (
        id_cliente,
        codigo_estado,
        fecha_pedido,
        fecha_entrega_prevista,
        total,
        codigo_seguimiento,
        id_escala
    )
    OUTPUT inserted.id_pedido INTO @nuevo_id_pedido
    VALUES (
        @id_cliente,
        'PENDIENTE',
        @fecha_actual,
        DATEADD(DAY, 3, @fecha_actual),
        0, 
        CONCAT('ABCD', FLOOR(RAND() * (999999 - 1) + 1)),
        1
    );

    SELECT @id_pedido = id_pedido FROM @nuevo_id_pedido;

    IF @id_pedido IS NULL
    BEGIN
        RAISERROR('No se pudo insertar el pedido.', 16, 1);
        RETURN;
    END

    EXEC INSERTAR_DETALLE @id_pedido, @json;

    SELECT @codigo_seguimiento = codigo_seguimiento
    FROM PEDIDOS
    WHERE id_pedido = @id_pedido;

    SELECT @codigo_seguimiento AS PedidoInsertado;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER   PROCEDURE VERIFICAR_TOKEN
    @token VARCHAR(150)
AS
BEGIN
	SELECT token_api FROM CLIENTES WHERE token_api = @token 
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE OBTENER_DETALLE_ULTIMO_PEDIDO
AS
BEGIN
    DECLARE @id_pedido INT;

    SELECT @id_pedido = MAX(id_pedido) FROM PEDIDOS;

    IF @id_pedido IS NULL
    BEGIN
        RAISERROR('No se encontraron pedidos.', 16, 1);
        RETURN;
    END

    -- Datos del pedido
    DECLARE @pedido NVARCHAR(MAX);
    SELECT @pedido = (SELECT p.id_pedido, p.codigo_estado, p.fecha_entrega_prevista, p.fecha_entrega_real, p.fecha_pedido, p.id_escala, p.total, p.codigo_seguimiento
                      FROM PEDIDOS p
                      WHERE p.id_pedido = @id_pedido
                      FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

    -- Datos del detalle del pedido
    DECLARE @detalles NVARCHAR(MAX);
    SELECT @detalles = (SELECT dp.codigo_barra, dp.cantidad, dp.precio_unitario
                        FROM DETALLE_PEDIDO dp
                        WHERE dp.id_pedido = @id_pedido
                        FOR JSON PATH);	

    -- Combinar ambos resultados en un solo JSON
    DECLARE @jsonResult NVARCHAR(MAX);
    SET @jsonResult = CONCAT('[{"Pedido":', @pedido, ', "Detalles":', @detalles, '}]');

    SELECT @jsonResult AS Resultado;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

EXEC dbo.OBTENER_CONFIGURACION;
GO

EXEC dbo.OBTENER_PRODUCTOS;
GO

EXEC dbo.OBTENER_ESCALA;
GO

EXEC dbo.OBTENER_PEDIDO @json = '{"codigo_seguimiento": "TRACK123"}';
GO

EXEC dbo.OBTENER_PEDIDOS;
GO

EXEC dbo.CANCELAR_PEDIDO @json = '{"codigo_seguimiento": "TRACK123"}';
GO

DECLARE @codigo_seguimiento NVARCHAR(150);

EXEC dbo.INSERTAR_PEDIDO 
    @id_cliente = 1, 
    @json = '[{"codigo_barra": "1234567890123", "cantidad": 2}]', 
    @codigo_seguimiento = @codigo_seguimiento OUTPUT;


SELECT @codigo_seguimiento AS CodigoSeguimiento;
GO

EXEC dbo.OBTENER_DETALLE_ULTIMO_PEDIDO;
GO

-- Eliminar procedimientos almacenados
IF OBJECT_ID('dbo.OBTENER_CONFIGURACION', 'P') IS NOT NULL
    DROP PROCEDURE dbo.OBTENER_CONFIGURACION;
GO

IF OBJECT_ID('dbo.OBTENER_PRODUCTOS', 'P') IS NOT NULL
    DROP PROCEDURE dbo.OBTENER_PRODUCTOS;
GO

IF OBJECT_ID('dbo.OBTENER_ESCALA', 'P') IS NOT NULL
    DROP PROCEDURE dbo.OBTENER_ESCALA;
GO

IF OBJECT_ID('dbo.OBTENER_PEDIDO', 'P') IS NOT NULL
    DROP PROCEDURE dbo.OBTENER_PEDIDO;
GO

IF OBJECT_ID('dbo.OBTENER_PEDIDOS', 'P') IS NOT NULL
    DROP PROCEDURE dbo.OBTENER_PEDIDOS;
GO

IF OBJECT_ID('dbo.CANCELAR_PEDIDO', 'P') IS NOT NULL
    DROP PROCEDURE dbo.CANCELAR_PEDIDO;
GO

IF OBJECT_ID('dbo.INSERTAR_PEDIDO', 'P') IS NOT NULL
    DROP PROCEDURE dbo.INSERTAR_PEDIDO;
GO

IF OBJECT_ID('dbo.INSERTAR_DETALLE', 'P') IS NOT NULL
    DROP PROCEDURE dbo.INSERTAR_DETALLE;
GO

IF OBJECT_ID('dbo.VERIFICAR_TOKEN', 'P') IS NOT NULL
    DROP PROCEDURE dbo.VERIFICAR_TOKEN;
GO

IF OBJECT_ID('dbo.OBTENER_DETALLE_ULTIMO_PEDIDO', 'P') IS NOT NULL
    DROP PROCEDURE dbo.OBTENER_DETALLE_ULTIMO_PEDIDO;
GO
