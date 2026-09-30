SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'ck_schedule_items_dates'
      AND parent_object_id = OBJECT_ID('dbo.schedule_items')
)
BEGIN
    ALTER TABLE dbo.schedule_items WITH CHECK
        ADD CONSTRAINT ck_schedule_items_dates CHECK (ends_at > starts_at);
END;

IF OBJECT_ID('dbo.clash_votes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.clash_votes (
        squad_id UNIQUEIDENTIFIER NOT NULL,
        schedule_item_id UNIQUEIDENTIFIER NOT NULL,
        user_id UNIQUEIDENTIFIER NOT NULL,
        created_at DATETIME2 NOT NULL
            CONSTRAINT df_clash_votes_created_at DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_clash_votes
            PRIMARY KEY (squad_id, schedule_item_id, user_id),
        CONSTRAINT fk_clash_votes_squad
            FOREIGN KEY (squad_id) REFERENCES dbo.squads(id),
        CONSTRAINT fk_clash_votes_schedule_item
            FOREIGN KEY (schedule_item_id) REFERENCES dbo.schedule_items(id),
        CONSTRAINT fk_clash_votes_user
            FOREIGN KEY (user_id) REFERENCES dbo.users(id)
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'ix_clash_votes_squad_item'
      AND object_id = OBJECT_ID('dbo.clash_votes')
)
BEGIN
    CREATE INDEX ix_clash_votes_squad_item
        ON dbo.clash_votes(squad_id, schedule_item_id);
END;

IF OBJECT_ID('dbo.clash_decisions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.clash_decisions (
        squad_id UNIQUEIDENTIFIER NOT NULL,
        conflict_id NVARCHAR(64) NOT NULL,
        schedule_item_id UNIQUEIDENTIFIER NOT NULL,
        decided_by_user_id UNIQUEIDENTIFIER NOT NULL,
        decided_at DATETIME2 NOT NULL
            CONSTRAINT df_clash_decisions_decided_at DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_clash_decisions PRIMARY KEY (squad_id, conflict_id),
        CONSTRAINT fk_clash_decisions_squad
            FOREIGN KEY (squad_id) REFERENCES dbo.squads(id),
        CONSTRAINT fk_clash_decisions_schedule_item
            FOREIGN KEY (schedule_item_id) REFERENCES dbo.schedule_items(id),
        CONSTRAINT fk_clash_decisions_user
            FOREIGN KEY (decided_by_user_id) REFERENCES dbo.users(id)
    );
END;

COMMIT TRANSACTION;
