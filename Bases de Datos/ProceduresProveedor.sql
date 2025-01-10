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

CREATE OR ALTER   PROCEDURE [dbo].[OBTENER_PEDIDOS]
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
        SELECT @jsonResult AS Pedido;
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
    @id_pedido INT OUTPUT
AS
BEGIN
    DECLARE @fecha_actual DATETIME = GETDATE();
    DECLARE @codigo_seguimiento VARCHAR(150) = CONCAT('ABCD', FLOOR(RAND() * (999999 - 1) + 1));
    DECLARE @nuevo_id_pedido TABLE (id_pedido INT);

    -- Insertar el nuevo pedido y capturar el id_pedido generado
    INSERT INTO PEDIDOS (codigo_estado, fecha_entrega_prevista, fecha_entrega_real, fecha_pedido, total, codigo_seguimiento, id_escala) 
    OUTPUT inserted.id_pedido INTO @nuevo_id_pedido
    VALUES (
        'PENDIENTE',
        DATEADD(DAY, 3, @fecha_actual),
        NULL,
        @fecha_actual,
        NULL,
        0,
        @codigo_seguimiento,
		1
    );

    -- Asignar el id_pedido generado al parámetro de salida
    SELECT @id_pedido = id_pedido FROM @nuevo_id_pedido;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////