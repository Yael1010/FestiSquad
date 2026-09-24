USE FestiSquad;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('dbo.expenses', 'client_request_id') IS NULL
BEGIN
    EXEC sp_executesql N'
        ALTER TABLE dbo.expenses
            ADD client_request_id UNIQUEIDENTIFIER NULL;
    ';
END;

EXEC sp_executesql N'
    UPDATE dbo.expenses
    SET client_request_id = id
    WHERE client_request_id IS NULL;

    ALTER TABLE dbo.expenses
        ALTER COLUMN client_request_id UNIQUEIDENTIFIER NOT NULL;
';

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'uq_expenses_client_request'
      AND object_id = OBJECT_ID('dbo.expenses')
)
    EXEC sp_executesql N'
        CREATE UNIQUE INDEX uq_expenses_client_request
            ON dbo.expenses(client_request_id);
    ';

COMMIT TRANSACTION;
GO
