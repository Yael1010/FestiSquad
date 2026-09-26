SET NOCOUNT ON;

-- Debe devolver cero filas: ningún importe financiero puede usar aproximación.
SELECT
    OBJECT_SCHEMA_NAME(c.object_id) AS schema_name,
    OBJECT_NAME(c.object_id) AS table_name,
    c.name AS column_name,
    t.name AS data_type
FROM sys.columns AS c
JOIN sys.types AS t ON c.user_type_id = t.user_type_id
WHERE OBJECT_NAME(c.object_id) IN ('expenses', 'expense_participants')
  AND t.name IN ('float', 'real', 'money', 'smallmoney');

-- Debe mostrar DECIMAL(18,2) para amount y share_amount.
SELECT
    OBJECT_NAME(c.object_id) AS table_name,
    c.name AS column_name,
    t.name AS data_type,
    c.precision,
    c.scale
FROM sys.columns AS c
JOIN sys.types AS t ON c.user_type_id = t.user_type_id
WHERE (OBJECT_NAME(c.object_id) = 'expenses' AND c.name = 'amount')
   OR (OBJECT_NAME(c.object_id) = 'expense_participants' AND c.name = 'share_amount');
