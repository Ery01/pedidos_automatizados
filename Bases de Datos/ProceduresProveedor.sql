CREATE OR ALTER PROCEDURE dbo.OBTENER_CONFIGURACION
AS
BEGIN 
DECLARE @jsonResult NVARCHAR(MAX);

    -- Generar el JSON desde la tabla CONFIGURACION
    SELECT @jsonResult = (
        SELECT * 
        FROM CLIENTES 
        FOR JSON AUTO
    );

    -- Devolver el JSON con un nombre de columna específico
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
-- Generar el JSON desde la tabla CONFIGURACION
    SELECT @jsonResult = (
        SELECT * 
        FROM ESCALA 
        FOR JSON AUTO
    );

    -- Devolver el JSON con un nombre de columna específico
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

    -- Generar el JSON desde la tabla PEDIDOS
    SELECT @jsonResult = (
        SELECT * 
        FROM PEDIDOS 
		WHERE codigo_seguimiento = @codigo_seguimiento
        FOR JSON AUTO
    );

    -- Devolver el JSON con un nombre de columna específico
    SELECT @jsonResult AS Pedido;
	END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER   PROCEDURE dbo.OBTENER_PEDIDOS
AS
BEGIN 
DECLARE @jsonResult NVARCHAR(MAX);

    -- Generar el JSON desde la tabla CONFIGURACION
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

    -- Devolver el JSON con un nombre de columna específico
    SELECT @jsonResult AS Pedidos
	END;
	GO
EXECUTE OBTENER_PEDIDOS 
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

        -- Devolver el JSON con un nombre de columna específico
        SELECT @jsonResult AS PedidoCancelado;
    END
    ELSE
    BEGIN
        -- Si no es 'PENDIENTE', lanzar un error o mensaje informativo
        RAISERROR('El pedido no está en estado PENDIENTE o no EXISTE. No se puede cancelar.', 16, 1);
    END	
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.INSERTAR_PEDIDO
    @id_cliente INT, -- Nuevo parámetro para vincular al cliente
    @json NVARCHAR(MAX), -- JSON con los productos
    @codigo_seguimiento NVARCHAR(150) OUTPUT
AS
BEGIN
    DECLARE @fecha_actual DATETIME = GETDATE();
    DECLARE @nuevo_id_pedido TABLE (id_pedido INT);
    DECLARE @id_pedido INT;

    -- Insertar el nuevo pedido
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
        0, -- Total inicial en 0, se actualizará después
        CONCAT('ABCD', FLOOR(RAND() * (999999 - 1) + 1)),
        1 -- Asumiendo id_escala = 1 por defecto
    );

    -- Obtener el id_pedido generado
    SELECT @id_pedido = id_pedido FROM @nuevo_id_pedido;

    -- Verificar si el pedido fue insertado correctamente
    IF @id_pedido IS NULL
    BEGIN
        RAISERROR('No se pudo insertar el pedido.', 16, 1);
        RETURN;
    END

    -- Llamar a INSERTAR_DETALLE para registrar los detalles del pedido
    EXEC INSERTAR_DETALLE @id_pedido, @json;

    -- Obtener el código de seguimiento
    SELECT @codigo_seguimiento = codigo_seguimiento
    FROM PEDIDOS
    WHERE id_pedido = @id_pedido;

    -- Devolver el código de seguimiento como resultado
    SELECT @codigo_seguimiento AS PedidoInsertado;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.INSERTAR_DETALLE
    @id_pedido INT,
    @json NVARCHAR(MAX)
AS
BEGIN
    DECLARE @total DECIMAL(18, 2) = 0;

    -- Procesar el JSON y recorrer los elementos
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

    -- Insertar los detalles del pedido
    DECLARE @codigo_barra NVARCHAR(150);
    DECLARE @cantidad INT;
    DECLARE @precio_unitario DECIMAL(18, 2);

    DECLARE detalle_cursor CURSOR FOR
    SELECT codigo_barra, cantidad FROM @json_table;

    OPEN detalle_cursor;
    FETCH NEXT FROM detalle_cursor INTO @codigo_barra, @cantidad;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Obtener el precio del producto
        SELECT @precio_unitario = precio
        FROM PRODUCTOS
        WHERE codigo_barra = @codigo_barra;

        -- Verificar si el precio fue encontrado
        IF @precio_unitario IS NULL
        BEGIN
            RAISERROR('No se encontró el precio para el código de barra: %s', 16, 1, @codigo_barra);
            CLOSE detalle_cursor;
            DEALLOCATE detalle_cursor;
            RETURN;
        END

        -- Calcular el total
        SET @total = @total + (@precio_unitario * @cantidad);

        -- Insertar en DETALLE_PEDIDOS
        INSERT INTO DETALLE_PEDIDOS (
            id_pedido,
            codigo_barra_producto,
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

    -- Actualizar el total en la tabla PEDIDOS
    UPDATE PEDIDOS
    SET total = @total
    WHERE id_pedido = @id_pedido;
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
    SELECT @detalles = (SELECT dp.codigo_barra_producto, dp.cantidad, dp.precio_unitario
                        FROM DETALLE_PEDIDOS dp
                        WHERE dp.id_pedido = @id_pedido
                        FOR JSON PATH);	

    -- Combinar ambos resultados en un solo JSON
    DECLARE @jsonResult NVARCHAR(MAX);
    SET @jsonResult = CONCAT('[{"Pedido":', @pedido, ', "Detalles":', @detalles, '}]');

    -- Devolver el resultado final
    SELECT @jsonResult AS Resultado;
END;
GO