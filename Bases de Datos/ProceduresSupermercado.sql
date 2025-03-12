
DROP PROCEDURE IF EXISTS dbo.LOGIN_USUARIO;
DROP PROCEDURE IF EXISTS dbo.OBTENER_CREDENCIALES;
DROP PROCEDURE IF EXISTS dbo.CANCELAR_PEDIDO;
DROP PROCEDURE IF EXISTS dbo.ACTUALIZAR_PUNTAJE_PROVEEDOR;
DROP PROCEDURE IF EXISTS dbo.EVALUAR_PEDIDO;
DROP PROCEDURE IF EXISTS dbo.OBTENER_RANKING_PONDERACION;
DROP PROCEDURE IF EXISTS dbo.INSERTAR_DATOS_PROVEEDOR;
DROP PROCEDURE IF EXISTS dbo.DAR_BAJA_PROVEEDOR;
DROP PROCEDURE IF EXISTS dbo.OBTENER_PRODUCTOS_PROVEEDOR;
DROP PROCEDURE IF EXISTS dbo.OBTENER_PEDIDOS;
DROP PROCEDURE IF EXISTS dbo.OBTENER_PEDIDOS_PROVEEDOR;
DROP PROCEDURE IF EXISTS dbo.OBTENER_DETALLE_PEDIDO;
DROP PROCEDURE IF EXISTS dbo.OBTENER_PROVEEDORES;
DROP PROCEDURE IF EXISTS dbo.OBTENER_PROVEEDOR;
DROP PROCEDURE IF EXISTS dbo.DETECTAR_PRODUCTOS_STOCK_MINIMO;
DROP PROCEDURE IF EXISTS dbo.ACTUALIZAR_PRECIOS_PROD_STOCK_MINIMO;
DROP PROCEDURE IF EXISTS dbo.SELECCIONAR_MEJOR_PROVEEDOR;
DROP PROCEDURE IF EXISTS dbo.GENERAR_PEDIDO_AUTOMATICO;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.LOGIN_USUARIO
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuario NVARCHAR(50), @clave NVARCHAR(50), @resultado NVARCHAR(MAX)

    SELECT 
        @usuario = JSON_VALUE(@json, '$.usuario'),
        @clave = JSON_VALUE(@json, '$.clave')

    IF EXISTS (SELECT 1 FROM USUARIOS WHERE usuario = @usuario AND clave = @clave)
    BEGIN
        SET @resultado = '{"status": "success", "message": "Login exitoso"}'
    END
    ELSE
    BEGIN
        SET @resultado = '{"status": "error", "message": "Usuario o clave incorrectos"}'
    END

    SELECT @resultado AS ResultadoLogin;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_CREDENCIALES
@json VARCHAR(max)
AS
BEGIN
    DECLARE @id_proveedor INT;
    DECLARE @jsonResult NVARCHAR(MAX);
	
    SET @id_proveedor = JSON_VALUE(@json, '$.id_proveedor');

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

    SET @jsonResult = REPLACE(@jsonResult, '\/', '/');

    SELECT @jsonResult AS credenciales;
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

	IF EXISTS (SELECT 1 FROM PEDIDOS WHERE codigo_seguimiento = @codigo_seguimiento AND estado IN ('PENDIENTE'))
    BEGIN
		UPDATE PEDIDOS
	    SET estado = 'CANCELADO'
		WHERE codigo_seguimiento = @codigo_seguimiento

		 SELECT @jsonResult = (
            SELECT *
            FROM PEDIDOS
            WHERE codigo_seguimiento = @codigo_seguimiento
            FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
        );

        SELECT @jsonResult AS pedido_cancelado;
    END
    ELSE
    BEGIN
        RAISERROR('El pedido no está en estado PENDIENTE o no EXISTE. No se puede cancelar.', 16, 1);
    END	
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.ACTUALIZAR_PUNTAJE_PROVEEDOR
    @id_proveedor INT
AS
BEGIN
    UPDATE PROVEEDORES
    SET puntaje = COALESCE((
        SELECT AVG(rp.ponderacion)  
        FROM PEDIDOS p
        INNER JOIN RANKING_PROVEEDOR rp 
            ON p.id_proveedor = rp.id_proveedor 
            AND p.evaluacion = rp.valor_original
        WHERE p.id_proveedor = @id_proveedor
          AND p.estado = 'EVALUADO'
    ), 0)
    WHERE id_proveedor = @id_proveedor;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.EVALUAR_PEDIDO
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @id_pedido INT;
    DECLARE @id_proveedor INT;
    DECLARE @estado NVARCHAR(50);
    DECLARE @evaluacion NVARCHAR(150);
    DECLARE @ponderacion DECIMAL(10,2);
    DECLARE @escala INT;

    SELECT
        @id_pedido = JSON_VALUE(@json, '$.id_pedido'),
        @escala = JSON_VALUE(@json, '$.escala'),
        @evaluacion = JSON_VALUE(@json, '$.evaluacion');

    IF NOT EXISTS (SELECT 1 FROM PEDIDOS WHERE id_pedido = @id_pedido)
    BEGIN
        RAISERROR('El pedido no existe.', 16, 1);
        RETURN;
    END

    SELECT 
        @id_proveedor = id_proveedor,
        @estado = estado
    FROM PEDIDOS
    WHERE id_pedido = @id_pedido;

    IF @id_proveedor IS NULL
    BEGIN
        RAISERROR('El pedido no tiene un proveedor asociado.', 16, 1);
        RETURN;
    END

    IF @estado <> 'ENTREGADO'
    BEGIN
        RAISERROR('El pedido no está en estado ENTREGADO. No se puede evaluar.', 16, 1);
        RETURN;
    END

    SELECT @ponderacion = ponderacion
    FROM RANKING_PROVEEDOR
    WHERE id_proveedor = @id_proveedor 
      AND id_escala = @escala 
      AND valor_original = @evaluacion;

    IF @ponderacion IS NULL
    BEGIN
        RAISERROR('La evaluación no es válida para el proveedor. No coincide la escala.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    UPDATE PEDIDOS
    SET evaluacion = @evaluacion,
        fecha_evaluacion = GETDATE(),
        estado = 'EVALUADO'
    WHERE id_pedido = @id_pedido;

    EXEC dbo.ACTUALIZAR_PUNTAJE_PROVEEDOR @id_proveedor;

    COMMIT TRANSACTION;

    DECLARE @jsonResult NVARCHAR(MAX);
    SELECT @jsonResult = (
        SELECT *
        FROM PEDIDOS
        WHERE id_pedido = @id_pedido
        FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
    );

    SELECT @jsonResult AS pedido_evaluado;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_RANKING_PONDERACION 
    @json NVARCHAR(MAX)
AS
BEGIN 
    SET NOCOUNT ON;

    DECLARE @id_proveedor INT;
    DECLARE @jsonResult NVARCHAR(MAX);

    SET @id_proveedor = TRY_CAST(JSON_VALUE(@json, '$.id_proveedor') AS INT);

    IF @id_proveedor IS NULL
    BEGIN
        RAISERROR('El id_proveedor es inválido o no fue proporcionado.', 16, 1);
        RETURN;
    END

    SELECT @jsonResult = (
        SELECT id_ranking_proveedor, id_escala, id_proveedor, valor_original, ponderacion, descripcion_valor
        FROM RANKING_PROVEEDOR
        WHERE id_proveedor = @id_proveedor
        ORDER BY ponderacion
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    IF @jsonResult IS NULL
        SET @jsonResult = '[]';

    SELECT @jsonResult AS ranking;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.INSERTAR_DATOS_PROVEEDOR
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @nombre_url NVARCHAR(150), @nombre NVARCHAR(50), @cuil NVARCHAR(150),
            @mail NVARCHAR(150), @token NVARCHAR(150), @habilitado BIT, @id_proveedor INT;

    SELECT 
        @nombre_url = JSON_VALUE(@json, '$.proveedor.nombre_url'),
        @nombre = JSON_VALUE(@json, '$.proveedor.nombre'),
        @cuil = JSON_VALUE(@json, '$.proveedor.cuil'),
        @mail = JSON_VALUE(@json, '$.proveedor.mail'),
        @token = JSON_VALUE(@json, '$.proveedor.token'),
        @habilitado = TRY_CAST(JSON_VALUE(@json, '$.proveedor.habilitado') AS BIT);

    IF EXISTS (SELECT 1 FROM PROVEEDORES WHERE nombre_url = @nombre_url)
    BEGIN
        RAISERROR('El proveedor ya existe.', 16, 1);
        RETURN;
    END

    INSERT INTO PROVEEDORES (nombre, mail, nombre_url, token, cuil, habilitado)
    VALUES (@nombre, @mail, @nombre_url, @token, @cuil, @habilitado);

    SET @id_proveedor = SCOPE_IDENTITY();

    INSERT INTO RANKING_PROVEEDOR (id_proveedor, id_escala, valor_original, ponderacion, descripcion_valor)
    SELECT @id_proveedor, 
           TRY_CAST(JSON_VALUE(ranking.value, '$.id_escala') AS INT),
           JSON_VALUE(ranking.value, '$.evaluacion'),
           TRY_CAST(JSON_VALUE(ranking.value, '$.ponderacion') AS DECIMAL(10,2)),
           JSON_VALUE(ranking.value, '$.descripcion_valor')
    FROM OPENJSON(@json, '$.ranking') AS ranking;

    INSERT INTO PRODUCTO_PROVEEDOR (codigo_barra, id_proveedor, precio)
    SELECT p.codigo_barra, @id_proveedor, TRY_CAST(JSON_VALUE(producto.value, '$.precio') AS DECIMAL(10,2))
    FROM OPENJSON(@json, '$.productos') AS producto
    INNER JOIN PRODUCTOS p ON p.codigo_barra = JSON_VALUE(producto.value, '$.codigo_barra'); -- Solo inserta si existe el producto

    DECLARE @result NVARCHAR(MAX);
    SELECT @result = (
        SELECT id_proveedor, nombre_url, nombre, token
        FROM PROVEEDORES
        WHERE id_proveedor = @id_proveedor
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    SELECT @result AS proveedor_registrado;

    SET NOCOUNT OFF;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.DAR_BAJA_PROVEEDOR
    @id_proveedor INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM PROVEEDORES WHERE id_proveedor = @id_proveedor)
    BEGIN
        RAISERROR('El proveedor no existe.', 16, 1);
        RETURN;
    END

    UPDATE PROVEEDORES
    SET habilitado = 0
    WHERE id_proveedor = @id_proveedor;

    SELECT 'Proveedor deshabilitado correctamente.' AS Mensaje;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_PRODUCTOS_PROVEEDOR
    @json NVARCHAR(MAX)
AS
BEGIN 
    SET NOCOUNT ON;

    DECLARE @jsonResult NVARCHAR(MAX);
    DECLARE @id_proveedor INT = JSON_VALUE(@json, '$.id_proveedor');

    IF NOT EXISTS (SELECT 1 FROM PROVEEDORES WHERE id_proveedor = @id_proveedor)
    BEGIN
        RAISERROR('El proveedor no existe.', 16, 1);
        RETURN;
    END

    SELECT @jsonResult = (
        SELECT 
            pp.codigo_barra,
            p.nombre AS nombre_producto,
            pp.precio AS precio_unitario,
            p.stock_actual,
            p.stock_minimo AS stock_minimo,
            p.imagen_contenido
        FROM 
            PRODUCTO_PROVEEDOR pp
        JOIN 
            PRODUCTOS p ON pp.codigo_barra = p.codigo_barra
        WHERE 
            pp.id_proveedor = @id_proveedor
        FOR JSON PATH
    );

    SELECT @jsonResult AS productos_proveedor;

    SET NOCOUNT OFF;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_PEDIDOS
AS
BEGIN 
    SET NOCOUNT ON;

    DECLARE @jsonResult NVARCHAR(MAX);

    SELECT @jsonResult = (
        SELECT
            p.id_pedido,
            p.id_proveedor,
            p.estado,
            p.fecha_entrega_prevista,
            p.fecha_entrega_real,
            p.fecha_pedido,
            p.total,
            p.evaluacion,
            p.codigo_seguimiento,
            pr.nombre AS nombre_proveedor 
        FROM 
            PEDIDOS p
            INNER JOIN PROVEEDORES pr ON p.id_proveedor = pr.id_proveedor
        ORDER BY 
            CASE p.estado
                WHEN 'PENDIENTE' THEN 1
                WHEN 'ENTREGADO' THEN 2
                WHEN 'ENVIADO' THEN 3
                WHEN 'CANCELADO' THEN 4
                WHEN 'EN_PROCESO' THEN 5
				WHEN 'EVALUADO' THEN 6
                ELSE 7
            END
        FOR JSON PATH
    );

    SELECT @jsonResult AS pedidos;

    SET NOCOUNT OFF;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_PEDIDOS_PROVEEDOR
    @id_proveedor INT
AS
BEGIN 
    DECLARE @jsonResult NVARCHAR(MAX);

    SELECT @jsonResult = (
        SELECT
            p.id_pedido,
            p.id_proveedor,
            p.estado,
            p.fecha_entrega_prevista,
            p.fecha_pedido,
            p.total,
            p.evaluacion,
            p.codigo_seguimiento,
            pr.nombre AS nombre_proveedor
        FROM 
            PEDIDOS p
            INNER JOIN PROVEEDORES pr ON p.id_proveedor = pr.id_proveedor
        WHERE 
            p.id_proveedor = @id_proveedor
        ORDER BY 
            CASE p.estado
                WHEN 'PENDIENTE' THEN 1
                WHEN 'ENTREGADO' THEN 2
                WHEN 'ENVIADO' THEN 3
                WHEN 'CANCELADO' THEN 4
                WHEN 'EN_PROCESO' THEN 5
                ELSE 6
            END
        FOR JSON PATH
    );

    SELECT @jsonResult AS pedidos_proveedor;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_DETALLE_PEDIDO
    @id_pedido INT
AS
BEGIN 
    DECLARE @jsonResult NVARCHAR(MAX);

    SELECT @jsonResult = (
        SELECT
            dp.codigo_barra,
            p.nombre AS nombre_producto,
            dp.cantidad,
            dp.precio_unitario,
            dp.fecha_registro
        FROM 
            DETALLE_PEDIDO dp
            INNER JOIN PRODUCTOS p ON dp.codigo_barra = p.codigo_barra
        WHERE 
            dp.id_pedido = @id_pedido
        FOR JSON PATH
    );

    SELECT @jsonResult AS detalle_pedido;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_PROVEEDORES
AS
BEGIN
    DECLARE @jsonResult NVARCHAR(MAX);

    SELECT @jsonResult = (
        SELECT 
            id_proveedor,
            nombre,
            cuil,
            mail,
            nombre_url,
            habilitado,
            puntaje,
            fecha_actualizacion_proveedor
        FROM 
            PROVEEDORES
        ORDER BY nombre
        FOR JSON PATH
    );

    SELECT @jsonResult AS proveedores;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.OBTENER_PROVEEDOR
    @id_proveedor INT = NULL,
    @nombre NVARCHAR(50) = NULL
AS
BEGIN
    DECLARE @jsonResult NVARCHAR(MAX);

    IF @id_proveedor IS NULL AND @nombre IS NULL
    BEGIN
        RAISERROR('Debe proporcionar al menos un parámetro: id_proveedor o nombre.', 16, 1);
        RETURN;
    END

    SELECT @jsonResult = (
        SELECT 
            id_proveedor,
            nombre,
            cuil,
            mail,
            nombre_url,
            habilitado,
            puntaje,
            fecha_actualizacion_proveedor
        FROM 
            PROVEEDORES
        WHERE 
            (@id_proveedor IS NULL OR id_proveedor = @id_proveedor)
            AND (@nombre IS NULL OR nombre = @nombre)
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    IF @jsonResult IS NULL
    BEGIN
        RAISERROR('Proveedor no encontrado.', 16, 1);
        RETURN;
    END

    SELECT @jsonResult AS proveedor;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
	- PROCEDIMIENTOS PARA GENERAR LOS PEDIDOS AUTOMATICOS
*/

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.DETECTAR_PRODUCTOS_STOCK_MINIMO
    @jsonResult NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @jsonResult = (
        SELECT 
            p.codigo_barra,
            p.nombre AS nombre_producto,
            p.stock_actual,
            p.stock_minimo,
            CASE 
                WHEN (p.stock_minimo - p.stock_actual - ISNULL(pedidos_pendientes.cantidad_pedida, 0)) > 0 
                THEN (p.stock_minimo - p.stock_actual - ISNULL(pedidos_pendientes.cantidad_pedida, 0))
                ELSE 0 
            END AS cantidad_faltante
        FROM PRODUCTOS p
        LEFT JOIN (
            SELECT dp.codigo_barra, SUM(dp.cantidad) AS cantidad_pedida
            FROM DETALLE_PEDIDO dp
            JOIN PEDIDOS pe ON dp.id_pedido = pe.id_pedido
            WHERE pe.estado IN ('PENDIENTE', 'EN PROCESO', 'ENVIADO')
            GROUP BY dp.codigo_barra
        ) pedidos_pendientes ON p.codigo_barra = pedidos_pendientes.codigo_barra
        WHERE p.stock_actual < p.stock_minimo 
            AND (p.stock_minimo - p.stock_actual - ISNULL(pedidos_pendientes.cantidad_pedida, 0)) > 0
        FOR JSON PATH
    );
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.ACTUALIZAR_PRECIOS_PROD_STOCK_MINIMO 
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #ProductosStockMin (
        codigo_barra VARCHAR(150)
    );

    INSERT INTO #ProductosStockMin (codigo_barra)
    SELECT codigo_barra
    FROM OPENJSON(@json)
    WITH (codigo_barra VARCHAR(150));

    UPDATE pp
    SET 
        pp.precio = src.precio,
        pp.fecha_actualizacion_precio = GETDATE()
    FROM PRODUCTO_PROVEEDOR pp
    JOIN #ProductosStockMin pm ON pp.codigo_barra = pm.codigo_barra
    JOIN PRODUCTO_PROVEEDOR src ON pp.codigo_barra = src.codigo_barra
    WHERE pp.id_proveedor = src.id_proveedor;

    DROP TABLE #ProductosStockMin;
END;
GO

/*
DECLARE @json NVARCHAR(MAX);

-- Ejecutar el procedimiento 1 y obtener el JSON con productos en stock mínimo
EXEC dbo.DETECTAR_PRODUCTOS_STOCK_MINIMO @json = @json OUTPUT;

-- Pasar ese JSON al procedimiento 2 para actualizar precios
EXEC dbo.ACTUALIZAR_PRECIOS_PROD_STOCK_MINIMO @json;
GO
*/

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.SELECCIONAR_MEJOR_PROVEEDOR
    @jsonProductos NVARCHAR(MAX),
    @jsonProveedores NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    CREATE TABLE #ProductosReposicion (codigo_barra VARCHAR(150));

    INSERT INTO #ProductosReposicion (codigo_barra)
    SELECT codigo_barra
    FROM OPENJSON(@jsonProductos)
    WITH (codigo_barra VARCHAR(150));

    CREATE TABLE #ProveedoresSeleccionados (
        codigo_barra VARCHAR(150),
        id_proveedor INT,
        precio DECIMAL(18,2)
    );

    INSERT INTO #ProveedoresSeleccionados (codigo_barra, id_proveedor, precio)
    SELECT 
        ppr.codigo_barra,
        ppr.id_proveedor,
        ppr.precio
    FROM PRODUCTO_PROVEEDOR ppr
    INNER JOIN #ProductosReposicion pr ON ppr.codigo_barra = pr.codigo_barra
    WHERE ppr.id_proveedor = (
        SELECT TOP 1 pp1.id_proveedor
        FROM PRODUCTO_PROVEEDOR pp1
        JOIN PROVEEDORES pr1 ON pp1.id_proveedor = pr1.id_proveedor
        WHERE pp1.codigo_barra = ppr.codigo_barra
        ORDER BY pp1.precio ASC, pr1.puntaje DESC
    );

    SELECT @jsonProveedores = (
        SELECT codigo_barra, id_proveedor, precio 
        FROM #ProveedoresSeleccionados
        FOR JSON AUTO
    );

    DROP TABLE #ProductosReposicion;
    DROP TABLE #ProveedoresSeleccionados;
END;
GO


--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE dbo.GENERAR_PEDIDO_AUTOMATICO
    @jsonProveedores NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #ProductosSeleccionados (
        codigo_barra VARCHAR(150),
        id_proveedor INT,
        precio DECIMAL(18,2)
    );

    INSERT INTO #ProductosSeleccionados (codigo_barra, id_proveedor, precio)
    SELECT codigo_barra, id_proveedor, precio
    FROM OPENJSON(@jsonProveedores)
    WITH (
        codigo_barra VARCHAR(150),
        id_proveedor INT,
        precio DECIMAL(18,2)
    );

    DECLARE @id_proveedor INT;
    DECLARE cur CURSOR FOR
    SELECT DISTINCT id_proveedor FROM #ProductosSeleccionados;

    OPEN cur;
    FETCH NEXT FROM cur INTO @id_proveedor;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @id_pedido INT = NULL;
        DECLARE @total DECIMAL(18,2) = 0;

        SELECT TOP 1 @id_pedido = id_pedido
        FROM PEDIDOS
        WHERE id_proveedor = @id_proveedor
          AND estado = 'PENDIENTE'
        ORDER BY fecha_pedido DESC;

        IF @id_pedido IS NULL
        BEGIN
            INSERT INTO PEDIDOS (id_proveedor, estado, codigo_seguimiento, fecha_pedido, fecha_entrega_prevista, total)
            VALUES (
                @id_proveedor, 
                'PENDIENTE', 
                LEFT(CAST(NEWID() AS VARCHAR(36)), 20), 
                GETDATE(),
                CAST(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 7 + 1, GETDATE()) AS DATE), -- Fecha estimada entre 1 y 7 días
                0
            );

            SET @id_pedido = SCOPE_IDENTITY();
        END

        DECLARE @codigo_barra VARCHAR(150);
        DECLARE @cantidad_faltante INT;
        DECLARE @precio DECIMAL(18,2);

        DECLARE prod_cur CURSOR FOR
        SELECT 
            p.codigo_barra, 
            (prod.stock_minimo - prod.stock_actual - ISNULL(pedidos_pendientes.cantidad_pedida, 0)) AS cantidad_faltante,
            p.precio
        FROM #ProductosSeleccionados p
        JOIN PRODUCTOS prod ON p.codigo_barra = prod.codigo_barra
        LEFT JOIN (
            SELECT dp.codigo_barra, SUM(dp.cantidad) AS cantidad_pedida
            FROM DETALLE_PEDIDO dp
            JOIN PEDIDOS pe ON dp.id_pedido = pe.id_pedido
            WHERE pe.estado IN ('PENDIENTE', 'EN PROCESO', 'ENVIADO')
            GROUP BY dp.codigo_barra
        ) pedidos_pendientes ON p.codigo_barra = pedidos_pendientes.codigo_barra
        WHERE p.id_proveedor = @id_proveedor
          AND (prod.stock_minimo - prod.stock_actual - ISNULL(pedidos_pendientes.cantidad_pedida, 0)) > 0;

        OPEN prod_cur;
        FETCH NEXT FROM prod_cur INTO @codigo_barra, @cantidad_faltante, @precio;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF EXISTS (SELECT 1 FROM DETALLE_PEDIDO WHERE id_pedido = @id_pedido AND codigo_barra = @codigo_barra)
            BEGIN
                UPDATE DETALLE_PEDIDO
                SET cantidad = cantidad + @cantidad_faltante
                WHERE id_pedido = @id_pedido
                  AND codigo_barra = @codigo_barra;
            END
            ELSE
            BEGIN
                INSERT INTO DETALLE_PEDIDO (id_pedido, codigo_barra, cantidad, precio_unitario, fecha_registro)
                VALUES (@id_pedido, @codigo_barra, @cantidad_faltante, @precio, GETDATE());
            END

            FETCH NEXT FROM prod_cur INTO @codigo_barra, @cantidad_faltante, @precio;
        END

        CLOSE prod_cur;
        DEALLOCATE prod_cur;

        SELECT @total = SUM(precio_unitario * cantidad)
        FROM DETALLE_PEDIDO
        WHERE id_pedido = @id_pedido;

        UPDATE PEDIDOS
        SET total = @total
        WHERE id_pedido = @id_pedido;

        FETCH NEXT FROM cur INTO @id_proveedor;
    END

    CLOSE cur;
    DEALLOCATE cur;

    DROP TABLE #ProductosSeleccionados;
END;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-- FLUJO PARA PROBAR LOS PROCEDIMIENTOS DE GENERAR PEDIDOS

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

DECLARE @jsonProductos NVARCHAR(MAX);
DECLARE @jsonProveedores NVARCHAR(MAX);

-- Paso 1: Detectar productos con stock mínimo
EXEC dbo.DETECTAR_PRODUCTOS_STOCK_MINIMO @jsonResult = @jsonProductos OUTPUT;

-- Ver productos con stock minimo: 
SELECT @jsonProductos AS ResultadoStockMínimo;

-- Paso 2: Actualizar precios de los productos con stock mínimo
EXEC dbo.ACTUALIZAR_PRECIOS_PROD_STOCK_MINIMO @jsonProductos;

-- Paso 3: Seleccionar el mejor proveedor para cada producto
EXEC dbo.SELECCIONAR_MEJOR_PROVEEDOR @jsonProductos, @jsonProveedores OUTPUT;

-- Ver proveedores seleccionados para cada producto
SELECT @jsonProveedores AS ResultadoProveedores;

-- Paso 4: Generar pedido automático con los proveedores seleccionados
EXEC dbo.GENERAR_PEDIDO_AUTOMATICO @jsonProveedores;
GO

--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////