-- Ejecutar después de 001_initial_schema.sql del repositorio, en FestiSquad.
-- SQL Server 2016 SP1+; CREATE OR ALTER permite volver a ejecutar este script.
-- Los importes originales siguen siendo DECIMAL(18,2).
-- SUM amplía la precisión a DECIMAL(38,2) para no desbordar al acumular tickets.
CREATE OR ALTER VIEW dbo.fund_balances AS
WITH movements AS (
    SELECT squad_id, paid_by_user_id AS user_id, amount AS delta
    FROM dbo.expenses
    UNION ALL
    SELECT e.squad_id, p.user_id, -p.share_amount AS delta
    FROM dbo.expense_participants AS p
    JOIN dbo.expenses AS e ON e.id = p.expense_id
)
SELECT squad_id, user_id, SUM(delta) AS balance
FROM movements
GROUP BY squad_id, user_id;
