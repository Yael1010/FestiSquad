SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('dbo.expenses', 'status') IS NULL
    EXEC(N'ALTER TABLE dbo.expenses ADD status NVARCHAR(20) NOT NULL
        CONSTRAINT df_expenses_status DEFAULT ''active''');

IF COL_LENGTH('dbo.expenses', 'cancelled_at') IS NULL
    EXEC(N'ALTER TABLE dbo.expenses ADD cancelled_at DATETIME2 NULL');

IF COL_LENGTH('dbo.expenses', 'cancelled_by_user_id') IS NULL
    EXEC(N'ALTER TABLE dbo.expenses ADD cancelled_by_user_id UNIQUEIDENTIFIER NULL');

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_expenses_cancelled_by'
)
    EXEC(N'ALTER TABLE dbo.expenses ADD CONSTRAINT fk_expenses_cancelled_by
        FOREIGN KEY (cancelled_by_user_id) REFERENCES dbo.users(id)');

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints WHERE name = 'ck_expenses_status'
)
    EXEC(N'ALTER TABLE dbo.expenses ADD CONSTRAINT ck_expenses_status
        CHECK (status IN (''active'', ''cancelled''))');

IF COL_LENGTH('dbo.settlements', 'status') IS NULL
    EXEC(N'ALTER TABLE dbo.settlements ADD status NVARCHAR(20) NOT NULL
        CONSTRAINT df_settlements_status DEFAULT ''active''');

IF COL_LENGTH('dbo.settlements', 'cancelled_at') IS NULL
    EXEC(N'ALTER TABLE dbo.settlements ADD cancelled_at DATETIME2 NULL');

IF COL_LENGTH('dbo.settlements', 'cancelled_by_user_id') IS NULL
    EXEC(N'ALTER TABLE dbo.settlements ADD cancelled_by_user_id UNIQUEIDENTIFIER NULL');

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_settlements_cancelled_by'
)
    EXEC(N'ALTER TABLE dbo.settlements ADD CONSTRAINT fk_settlements_cancelled_by
        FOREIGN KEY (cancelled_by_user_id) REFERENCES dbo.users(id)');

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints WHERE name = 'ck_settlements_status'
)
    EXEC(N'ALTER TABLE dbo.settlements ADD CONSTRAINT ck_settlements_status
        CHECK (status IN (''active'', ''cancelled''))');

COMMIT TRANSACTION;

EXEC(N'
CREATE OR ALTER VIEW dbo.fund_balances AS
WITH movements AS (
    SELECT squad_id, paid_by_user_id AS user_id, amount AS delta
    FROM dbo.expenses
    WHERE status = ''active''
    UNION ALL
    SELECT e.squad_id, p.user_id, -p.share_amount AS delta
    FROM dbo.expense_participants AS p
    JOIN dbo.expenses AS e ON e.id = p.expense_id
    WHERE e.status = ''active''
    UNION ALL
    SELECT squad_id, from_user_id AS user_id, amount AS delta
    FROM dbo.settlements
    WHERE status = ''active''
    UNION ALL
    SELECT squad_id, to_user_id AS user_id, -amount AS delta
    FROM dbo.settlements
    WHERE status = ''active''
)
SELECT squad_id, user_id, SUM(delta) AS balance
FROM movements
GROUP BY squad_id, user_id;
');
