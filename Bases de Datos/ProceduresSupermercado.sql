
--//////////////////////////////////////////////////////////////////////////////////////////////////////////OBTENER_CREDENCIALES

CREATE OR ALTER   PROCEDURE dbo.OBTENER_CREDENCIALES
@json VARCHAR(max)
AS
BEGIN
    DECLARE @id_proveedor INT;
    DECLARE @jsonResult NVARCHAR(MAX);

    -- Obtener el valor de id_proveedor del JSON de entrada
    SET @id_proveedor = JSON_VALUE(@json, '$.id_proveedor');

    -- Construir el JSON de respuesta
    SELECT @jsonResult = (
        SELECT 
            id_proveedor,
            nombre,
            cuil,
            mail,
            nombre_url,
            token,
			tecnologia,
            habilitado,
			fecha_actualizacion_proveedor
        FROM PROVEEDORES 
        WHERE id_proveedor = @id_proveedor
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    -- Reemplazar las barras invertidas en el JSON resultante
    SET @jsonResult = REPLACE(@jsonResult, '\/', '/');

    -- Devolver el JSON con un nombre de columna específico
    SELECT @jsonResult AS credenciales;
END;
GO

EXECUTE OBTENER_CREDENCIALES 
    @json = '{"id_proveedor":"2", "id_provsadsaeedor":"2", "id_proveasdasdedor":"2"}'
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.CANCELAR_PEDIDO
    @json VARCHAR(max)
AS
DECLARE
@codigo_seguimiento VARCHAR(150) = JSON_VALUE(@json, '$.codigo_seguimiento')
DECLARE @jsonResult NVARCHAR(MAX);
BEGIN

	IF EXISTS (SELECT 1 FROM PEDIDOS WHERE codigo_seguimiento = @codigo_seguimiento AND estado IN ('PENDIENTE'))
    BEGIN
        -- Si el codigo_estado es 'PENDIENTE' , lo cambia a CANCELADO  
		UPDATE PEDIDOS
	    SET estado = 'CANCELADO'
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

