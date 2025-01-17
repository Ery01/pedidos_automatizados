
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

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.EVALUAR_PEDIDO
    @json NVARCHAR(MAX)
AS
BEGIN
    -- Declaración de variables
    DECLARE @id_pedido INT;
    DECLARE @id_proveedor INT;
    DECLARE @estado NVARCHAR(50);
    DECLARE @evaluacion NVARCHAR(150);
    DECLARE @ponderacion INT;

    -- Extraer valores del JSON
    SELECT
        @id_pedido = JSON_VALUE(@json, '$.id_pedido'),
		@escala = JSON_VALUE(@json, '$.escala'),
        @evaluacion = JSON_VALUE(@json, '$.evaluacion');

    -- Obtener el proveedor y el estado del pedido
    SELECT 
        @id_proveedor = id_proveedor,
        @estado = estado
    FROM PEDIDOS
    WHERE id_pedido = @id_pedido;

    -- Validar si el pedido existe
    IF @id_proveedor IS NULL
    BEGIN
        RAISERROR('El pedido no existe.', 16, 1);
        RETURN;
    END

    -- Validar si el pedido está en estado ENTREGADO
    IF @estado <> 'ENTREGADO'
    BEGIN
        RAISERROR('El pedido no está en estado ENTREGADO. No se puede evaluar.', 16, 1);
        RETURN;
    END

    -- Validar si la evaluación existe en la tabla RANKING_PROVEEDOR
    SELECT 1 --@ponderacion = ponderacion
    FROM RANKING_PROVEEDOR
    WHERE id_proveedor = @id_proveedor AND id_escala = @escala;

    --IF @ponderacion IS NULL
    BEGIN
        --RAISERROR('La evaluación no es válida para el proveedor. No se puede evaluar el pedido.', 16, 1);
		RAISERROR('La evaluación no es válida para el proveedor. No coincide la escala.', 16, 1);
        RETURN;
    END

    -- Actualizar la evaluación del pedido
    UPDATE PEDIDOS
    SET puntaje = @evaluacion,
        fecha_evaluacion = GETDATE(),
        estado = 'EVALUADO'
    WHERE id_pedido = @id_pedido;

    -- Calcular el puntaje promedio del proveedor basado en los pedidos evaluados
    UPDATE PROVEEDORES
    SET puntaje = (
        SELECT SUM(rp.ponderacion) * 1.0 / COUNT(p.id_pedido)
        FROM PEDIDOS p
        INNER JOIN RANKING_PROVEEDOR rp ON p.id_proveedor = rp.id_proveedor AND p.estado = 'EVALUADO'
        WHERE p.id_proveedor = @id_proveedor
    )
    WHERE id_proveedor = @id_proveedor;

    -- Devolver el pedido actualizado como JSON
    DECLARE @jsonResult NVARCHAR(MAX);
    SELECT @jsonResult = (
        SELECT *
        FROM PEDIDOS
        WHERE id_pedido = @id_pedido
        FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
    );

    -- Resultado final
    SELECT @jsonResult AS Pedido;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_RANKING_PONDERACION 
@json VARCHAR(max)
	AS
BEGIN 
DECLARE @jsonResult NVARCHAR(MAX);
DECLARE @id_proveedor VARCHAR(150) = JSON_VALUE(@json, '$.id_proveedor');

    -- Generar el JSON desde la tabla CONFIGURACION
    SELECT @jsonResult = (
        SELECT * FROM RANKING_PROVEEDOR
		WHERE id_proveedor = @id_proveedor
		ORDER BY ponderacion
        FOR JSON AUTO
    );

    -- Devolver el JSON con un nombre de columna específico
    SELECT @jsonResult AS Ranking
	END;
GO

/*EXECUTE OBTENER_RANKING_PONDERACION 
@json = '{"id_proveedor":2}' 
GO
*/

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.INSERTAR_DATOS_PROVEEDOR
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Declarar variables para los datos del proveedor
    DECLARE @nombre_url NVARCHAR(150), @nombre NVARCHAR(50), @cuil NVARCHAR(150), @mail NVARCHAR(150), @token NVARCHAR(150), @habilitado BIT;

    -- Declarar una tabla temporal para los datos del ranking
    DECLARE @RankingTemp TABLE (
        evaluacion NVARCHAR(50),
        ponderacion INT
    );

    -- Declarar una tabla temporal para los productos
    DECLARE @ProductoTemp TABLE (
        codigo_barra NVARCHAR(150),
        nombre NVARCHAR(150),
        precio INT,
        fecha_actualizacion_precio DATETIME
    );

    -- Extraer los datos del JSON
    SELECT
        @nombre_url = proveedor.nombre_url,
        @nombre = proveedor.nombre,
        @cuil = proveedor.cuil,
        @mail = proveedor.mail,
        @token = proveedor.token,
        @habilitado = proveedor.habilitado
    FROM
        OPENJSON(@json)
        WITH (
            proveedor NVARCHAR(MAX) AS JSON
        ) AS Proveedor
        CROSS APPLY OPENJSON(Proveedor.proveedor)
        WITH (
            nombre_url NVARCHAR(150),
            nombre NVARCHAR(50),
            cuil NVARCHAR(150),
            mail NVARCHAR(150),
            token NVARCHAR(150),
            habilitado BIT
        ) AS proveedor;

    -- Insertar datos en la tabla temporal de Ranking
    INSERT INTO @RankingTemp (evaluacion, ponderacion)
    SELECT evaluacion, ponderacion
    FROM
        OPENJSON(@json, '$.ranking')
        WITH (
            evaluacion NVARCHAR(50),
            ponderacion INT
        );

    -- Insertar datos en la tabla temporal de Productos
    INSERT INTO @ProductoTemp (codigo_barra, nombre, precio, fecha_actualizacion_precio)
    SELECT codigo_barra, nombre, precio, fecha_actualizacion_precio
    FROM
        OPENJSON(@json, '$.productos')
        WITH (
            codigo_barra NVARCHAR(150),
            nombre NVARCHAR(150),
            precio INT,
            fecha_actualizacion_precio DATETIME
        );

    -- Insertar datos en la tabla PROVEEDORES
    INSERT INTO PROVEEDORES (nombre, mail, nombre_url, token, cuil, habilitado)
    VALUES (@nombre, @mail, @nombre_url, @token, @cuil, @habilitado);

    -- Obtener el ID del proveedor recién insertado
    DECLARE @id_proveedor INT;
    SET @id_proveedor = SCOPE_IDENTITY();

    -- Insertar datos en la tabla RANKING_PROVEEDOR (relación de las evaluaciones con el proveedor)
    INSERT INTO RANKING_PROVEEDOR (id_proveedor, descripcion_valor, ponderacion)
    SELECT @id_proveedor, evaluacion, ponderacion
    FROM @RankingTemp;

    -- Insertar datos en la tabla PRODUCTO_PROVEEDOR (productos asociados al proveedor)
    INSERT INTO PRODUCTO_PROVEEDOR (codigo_barra, id_proveedor, precio, fecha_actualizacion_precio)
    SELECT codigo_barra, @id_proveedor, precio, fecha_actualizacion_precio
    FROM @ProductoTemp;

    -- Devolver JSON con la configuración del proveedor
    DECLARE @result NVARCHAR(MAX);
    SELECT @result = (
        SELECT nombre_url, nombre, token
        FROM PROVEEDORES
        WHERE id_proveedor = @id_proveedor
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
    
    -- Devolver el resultado
    SELECT @result AS configuracion;

    SET NOCOUNT OFF;
END;
GO

-- Comando para probar insertar un nuevo proveedor
EXEC dbo.INSERTAR_DATOS_PROVEEDOR 
    @json = '{"proveedor": {"nombre_url": "http://proveedor1.com", "nombre": "Proveedor 1", "cuil": "20-12345678-9", "mail": "contacto@proveedor1.com", "token": "token1234", "habilitado": 1}, "ranking": [{"evaluacion": "Excelente", "ponderacion": 5}, {"evaluacion": "Muy Bueno", "ponderacion": 4}], "productos": [{"codigo_barra": "1234567890123", "nombre": "Producto A", "precio": 100, "fecha_actualizacion_precio": "2025-01-15T00:00:00"}, {"codigo_barra": "2345678901234", "nombre": "Producto B", "precio": 200, "fecha_actualizacion_precio": "2025-01-15T00:00:00"}]}';
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_PRODUCTOS_PROVEEDOR
    @json VARCHAR(MAX)
AS
BEGIN 
    DECLARE @jsonResult NVARCHAR(MAX);
    DECLARE @id_proveedor INT = JSON_VALUE(@json, '$.id_proveedor');

    -- Generar el JSON desde las tablas PRODUCTO_PROVEEDOR y PRODUCTOS
    SELECT @jsonResult = (
        SELECT 
            pp.codigo_barra,
            pp.nombre AS nombre_producto,
            pp.precio AS precio_unitario,
            pp.fecha_actualizacion_precio,
            p.nombre AS nombre_producto_detalle,
            p.stock_actual,
            p.stock_optimo,
            p.imagen_contenido
        FROM 
            PRODUCTO_PROVEEDOR pp
        JOIN 
            PRODUCTOS p ON pp.codigo_barra = p.codigo_barra
        WHERE 
            pp.id_proveedor = @id_proveedor
        FOR JSON PATH
    );

    -- Devolver el JSON con un nombre de columna específico
    SELECT @jsonResult AS Productos;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_PEDIDOS
AS
BEGIN 
    DECLARE @jsonResult NVARCHAR(MAX);

    -- Generar el JSON desde la tabla PEDIDOS con nombre del proveedor
    SELECT @jsonResult = (
        SELECT
            p.id_pedido,
            p.id_proveedor,
            p.codigo_estado,
            p.fecha_entrega_prevista,
            p.fecha_pedido,
            p.total,
            p.evaluacion,
            p.ponderacion,
            p.codigo_seguimiento,
            pr.nombre AS nombre_proveedor, -- Nombre del proveedor
            p.id_proveedor AS id_proveedor -- Incluir el id_proveedor para facilitar filtrados posteriores
        FROM 
            PEDIDOS p
            INNER JOIN PROVEEDORES pr ON p.id_proveedor = pr.id_proveedor
        ORDER BY 
            CASE p.codigo_estado
                WHEN 'PENDIENTE' THEN 1
                WHEN 'ENTREGADO' THEN 2
                WHEN 'ENVIADO' THEN 3
                WHEN 'CANCELADO' THEN 4
                WHEN 'EN_PROCESO' THEN 5
                ELSE 6
            END
        FOR JSON PATH
    );

    -- Devolver el JSON con un nombre de columna específico
    SELECT @jsonResult AS Pedidos;
END;
GO

EXEC dbo.OBTENER_PEDIDOS;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_PEDIDOS_PROVEEDOR
    @id_proveedor INT
AS
BEGIN 
    DECLARE @jsonResult NVARCHAR(MAX);

    -- Generar el JSON desde la tabla PEDIDOS con nombre del proveedor, filtrando por id_proveedor
    SELECT @jsonResult = (
        SELECT
            p.id_pedido,
            p.id_proveedor,
            p.codigo_estado,
            p.fecha_entrega_prevista,
            p.fecha_pedido,
            p.total,
            p.evaluacion,
            p.ponderacion,
            p.codigo_seguimiento,
            pr.nombre AS nombre_proveedor -- Nombre del proveedor
        FROM 
            PEDIDOS p
            INNER JOIN PROVEEDORES pr ON p.id_proveedor = pr.id_proveedor
        WHERE 
            p.id_proveedor = @id_proveedor -- Filtrar por el id_proveedor recibido
        ORDER BY 
            CASE p.codigo_estado
                WHEN 'PENDIENTE' THEN 1
                WHEN 'ENTREGADO' THEN 2
                WHEN 'ENVIADO' THEN 3
                WHEN 'CANCELADO' THEN 4
                WHEN 'EN_PROCESO' THEN 5
                ELSE 6
            END
        FOR JSON PATH
    );

    -- Devolver el JSON con un nombre de columna específico
    SELECT @jsonResult AS Pedidos;
END;
GO

-- PUNTOS A REVISAR:
/*

- Procedimiento de actualizar ponderacion? 
- Procedimiento de obtener ranking ponderacion
- Procedimiento de obtener estadistica proveedor, para que sirve?
- Procedimiento para dar de baja un proveedor
- Procedimientos relacionados al detalle del pedido
- Procedimiento de obtener proveedores
- Procedimientos relacionados a actualizacion de precios
- Procedimiento de seleccionar mejor proveedor para el producto

*/