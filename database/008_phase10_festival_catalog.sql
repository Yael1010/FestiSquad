USE FestiSquad;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('dbo.users', 'is_platform_admin') IS NULL
BEGIN
    ALTER TABLE dbo.users ADD is_platform_admin BIT NOT NULL
        CONSTRAINT df_users_is_platform_admin DEFAULT 0;
END;

IF COL_LENGTH('dbo.festivals', 'venue_name') IS NULL
BEGIN
    ALTER TABLE dbo.festivals ADD venue_name NVARCHAR(160) NOT NULL
        CONSTRAINT df_festivals_venue_name DEFAULT 'Por definir';
END;

IF COL_LENGTH('dbo.festivals', 'city') IS NULL
BEGIN
    ALTER TABLE dbo.festivals ADD city NVARCHAR(120) NOT NULL
        CONSTRAINT df_festivals_city DEFAULT 'Por definir';
END;

IF COL_LENGTH('dbo.festivals', 'country_code') IS NULL
BEGIN
    ALTER TABLE dbo.festivals ADD country_code CHAR(2) NOT NULL
        CONSTRAINT df_festivals_country_code DEFAULT 'MX';
END;

IF COL_LENGTH('dbo.festivals', 'timezone') IS NULL
BEGIN
    ALTER TABLE dbo.festivals ADD timezone NVARCHAR(64) NOT NULL
        CONSTRAINT df_festivals_timezone DEFAULT 'America/Mexico_City';
END;

IF COL_LENGTH('dbo.festivals', 'image_url') IS NULL
    ALTER TABLE dbo.festivals ADD image_url NVARCHAR(1000) NULL;

IF COL_LENGTH('dbo.festivals', 'official_url') IS NULL
    ALTER TABLE dbo.festivals ADD official_url NVARCHAR(1000) NULL;

IF COL_LENGTH('dbo.festivals', 'status') IS NULL
BEGIN
    ALTER TABLE dbo.festivals ADD status NVARCHAR(20) NOT NULL
        CONSTRAINT df_festivals_status DEFAULT 'draft';
    -- Los registros previos ya eran visibles antes de existir el flujo editorial.
    EXEC sys.sp_executesql
        N'UPDATE dbo.festivals SET status = ''published'';';
END;

IF COL_LENGTH('dbo.festivals', 'updated_at') IS NULL
BEGIN
    ALTER TABLE dbo.festivals ADD updated_at DATETIME2 NOT NULL
        CONSTRAINT df_festivals_updated_at DEFAULT SYSUTCDATETIME();
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'ck_festivals_dates'
      AND parent_object_id = OBJECT_ID('dbo.festivals')
)
    ALTER TABLE dbo.festivals ADD CONSTRAINT ck_festivals_dates
        CHECK (ends_at > starts_at);

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'ck_festivals_status'
      AND parent_object_id = OBJECT_ID('dbo.festivals')
)
    EXEC sys.sp_executesql N'
        ALTER TABLE dbo.festivals ADD CONSTRAINT ck_festivals_status
            CHECK (status IN (''draft'', ''published'', ''archived''));';

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'ix_festivals_status_starts'
      AND object_id = OBJECT_ID('dbo.festivals')
)
    EXEC sys.sp_executesql N'
        CREATE INDEX ix_festivals_status_starts
            ON dbo.festivals(status, starts_at);';

COMMIT TRANSACTION;
GO

-- Promueve explícitamente una cuenta existente antes de usar administración:
-- UPDATE dbo.users SET is_platform_admin = 1 WHERE email = 'admin@example.com';

USE FestiSquad;

SELECT
    name,
    venue_name,
    city,
    status,
    updated_at
FROM dbo.festivals;

SELECT
    name,
    email,
    is_platform_admin
FROM dbo.users;

UPDATE dbo.users
SET is_platform_admin = 1
WHERE email = 'fyael7093@gmail.com';