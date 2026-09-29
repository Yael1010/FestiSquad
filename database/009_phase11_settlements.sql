USE FestiSquad;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('dbo.settlements', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.settlements (
        id UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT df_settlements_id DEFAULT NEWID(),
        squad_id UNIQUEIDENTIFIER NOT NULL,
        client_request_id UNIQUEIDENTIFIER NOT NULL,
        from_user_id UNIQUEIDENTIFIER NOT NULL,
        to_user_id UNIQUEIDENTIFIER NOT NULL,
        amount DECIMAL(18,2) NOT NULL,
        note NVARCHAR(180) NULL,
        created_at DATETIME2 NOT NULL
            CONSTRAINT df_settlements_created_at DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_settlements PRIMARY KEY (id),
        CONSTRAINT uq_settlements_client_request UNIQUE (client_request_id),
        CONSTRAINT ck_settlements_amount CHECK (amount > 0),
        CONSTRAINT ck_settlements_distinct_users
            CHECK (from_user_id <> to_user_id),
        CONSTRAINT fk_settlements_squad
            FOREIGN KEY (squad_id) REFERENCES dbo.squads(id),
        CONSTRAINT fk_settlements_from_user
            FOREIGN KEY (from_user_id) REFERENCES dbo.users(id),
        CONSTRAINT fk_settlements_to_user
            FOREIGN KEY (to_user_id) REFERENCES dbo.users(id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_settlements_squad_created'
      AND object_id = OBJECT_ID('dbo.settlements')
)
BEGIN
    CREATE INDEX ix_settlements_squad_created
        ON dbo.settlements(squad_id, created_at DESC);
END;

COMMIT TRANSACTION;
GO

CREATE OR ALTER VIEW dbo.fund_balances AS
WITH movements AS (
    SELECT squad_id, paid_by_user_id AS user_id, amount AS delta
    FROM dbo.expenses
    UNION ALL
    SELECT e.squad_id, p.user_id, -p.share_amount AS delta
    FROM dbo.expense_participants AS p
    JOIN dbo.expenses AS e ON e.id = p.expense_id
    UNION ALL
    SELECT squad_id, from_user_id AS user_id, amount AS delta
    FROM dbo.settlements
    UNION ALL
    SELECT squad_id, to_user_id AS user_id, -amount AS delta
    FROM dbo.settlements
)
SELECT squad_id, user_id, SUM(delta) AS balance
FROM movements
GROUP BY squad_id, user_id;
GO
