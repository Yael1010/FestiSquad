USE FestiSquad;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('dbo.external_accounts', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.external_accounts (
        id UNIQUEIDENTIFIER NOT NULL CONSTRAINT df_external_accounts_id DEFAULT NEWID(),
        user_id UNIQUEIDENTIFIER NOT NULL,
        provider NVARCHAR(20) NOT NULL,
        provider_user_id NVARCHAR(255) NOT NULL,
        provider_email NVARCHAR(255) NULL,
        avatar_url NVARCHAR(1000) NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT df_external_accounts_created DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_external_accounts PRIMARY KEY (id),
        CONSTRAINT uq_external_accounts_provider_user UNIQUE (provider, provider_user_id),
        CONSTRAINT uq_external_accounts_user_provider UNIQUE (user_id, provider),
        CONSTRAINT ck_external_accounts_provider CHECK (provider IN ('google', 'spotify')),
        CONSTRAINT fk_external_accounts_user FOREIGN KEY (user_id) REFERENCES dbo.users(id)
    );
END;

IF OBJECT_ID('dbo.social_auth_flows', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.social_auth_flows (
        id UNIQUEIDENTIFIER NOT NULL CONSTRAINT df_social_auth_flows_id DEFAULT NEWID(),
        provider NVARCHAR(20) NOT NULL,
        flow_token_hash NVARCHAR(64) NOT NULL,
        status NVARCHAR(20) NOT NULL CONSTRAINT df_social_auth_flows_status DEFAULT 'pending',
        requested_user_id UNIQUEIDENTIFIER NULL,
        user_id UNIQUEIDENTIFIER NULL,
        error_code NVARCHAR(80) NULL,
        expires_at DATETIME2 NOT NULL,
        consumed_at DATETIME2 NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT df_social_auth_flows_created DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_social_auth_flows PRIMARY KEY (id),
        CONSTRAINT uq_social_auth_flows_token UNIQUE (flow_token_hash),
        CONSTRAINT ck_social_auth_flows_provider CHECK (provider IN ('google', 'spotify')),
        CONSTRAINT ck_social_auth_flows_status CHECK (status IN ('pending', 'completed', 'failed', 'consumed')),
        CONSTRAINT fk_social_auth_flows_requested_user FOREIGN KEY (requested_user_id) REFERENCES dbo.users(id),
        CONSTRAINT fk_social_auth_flows_user FOREIGN KEY (user_id) REFERENCES dbo.users(id)
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'ix_external_accounts_user'
      AND object_id = OBJECT_ID('dbo.external_accounts')
)
BEGIN
    CREATE INDEX ix_external_accounts_user ON dbo.external_accounts(user_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'ix_social_auth_flows_expires'
      AND object_id = OBJECT_ID('dbo.social_auth_flows')
)
BEGIN
    CREATE INDEX ix_social_auth_flows_expires ON dbo.social_auth_flows(expires_at);
END;

COMMIT TRANSACTION;
GO
