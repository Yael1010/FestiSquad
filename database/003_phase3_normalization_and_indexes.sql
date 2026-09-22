USE FestiSquad;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('dbo.genres', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.genres (
        id INT IDENTITY(1,1) NOT NULL,
        name NVARCHAR(80) NOT NULL,
        CONSTRAINT pk_genres PRIMARY KEY (id),
        CONSTRAINT uq_genres_name UNIQUE (name)
    );
END;

IF OBJECT_ID('dbo.schedule_item_genres', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.schedule_item_genres (
        schedule_item_id UNIQUEIDENTIFIER NOT NULL,
        genre_id INT NOT NULL,
        CONSTRAINT pk_schedule_item_genres PRIMARY KEY (schedule_item_id, genre_id),
        CONSTRAINT fk_schedule_item_genres_item
            FOREIGN KEY (schedule_item_id) REFERENCES dbo.schedule_items(id),
        CONSTRAINT fk_schedule_item_genres_genre
            FOREIGN KEY (genre_id) REFERENCES dbo.genres(id)
    );
END;

IF COL_LENGTH('dbo.schedule_items', 'genres_csv') IS NOT NULL
BEGIN
    EXEC sys.sp_executesql N'
        INSERT INTO dbo.genres (name)
        SELECT DISTINCT LTRIM(RTRIM(parts.value))
        FROM dbo.schedule_items AS item
        CROSS APPLY STRING_SPLIT(item.genres_csv, '','') AS parts
        WHERE LTRIM(RTRIM(parts.value)) <> ''''
          AND NOT EXISTS (
              SELECT 1 FROM dbo.genres AS genre
              WHERE genre.name = LTRIM(RTRIM(parts.value))
          );

        INSERT INTO dbo.schedule_item_genres (schedule_item_id, genre_id)
        SELECT DISTINCT item.id, genre.id
        FROM dbo.schedule_items AS item
        CROSS APPLY STRING_SPLIT(item.genres_csv, '','') AS parts
        JOIN dbo.genres AS genre
          ON genre.name = LTRIM(RTRIM(parts.value))
        WHERE LTRIM(RTRIM(parts.value)) <> ''''
          AND NOT EXISTS (
              SELECT 1 FROM dbo.schedule_item_genres AS existing
              WHERE existing.schedule_item_id = item.id
                AND existing.genre_id = genre.id
          );';

    DECLARE @genres_default NVARCHAR(128);
    SELECT @genres_default = constraint_object.name
    FROM sys.default_constraints AS constraint_object
    JOIN sys.columns AS column_object
      ON column_object.default_object_id = constraint_object.object_id
    WHERE constraint_object.parent_object_id = OBJECT_ID('dbo.schedule_items')
      AND column_object.name = 'genres_csv';

    IF @genres_default IS NOT NULL
    BEGIN
        DECLARE @drop_default_sql NVARCHAR(500);
        SET @drop_default_sql =
            N'ALTER TABLE dbo.schedule_items DROP CONSTRAINT '
            + QUOTENAME(@genres_default);
        EXEC sys.sp_executesql @drop_default_sql;
    END;

    EXEC sys.sp_executesql
        N'ALTER TABLE dbo.schedule_items DROP COLUMN genres_csv;';
END;

IF COL_LENGTH('dbo.schedule_items', 'festival_id') IS NOT NULL
BEGIN
    DECLARE @festival_mismatches INT;
    EXEC sys.sp_executesql N'
        SELECT @count = COUNT(*)
        FROM dbo.schedule_items AS item
        JOIN dbo.stages AS stage ON stage.id = item.stage_id
        WHERE item.festival_id <> stage.festival_id;',
        N'@count INT OUTPUT',
        @count = @festival_mismatches OUTPUT;

    IF @festival_mismatches > 0
        THROW 51000, 'Hay horarios cuyo festival no coincide con el festival del escenario.', 1;

    IF EXISTS (
        SELECT 1 FROM sys.foreign_keys
        WHERE name = 'fk_schedule_items_festival'
          AND parent_object_id = OBJECT_ID('dbo.schedule_items')
    )
        ALTER TABLE dbo.schedule_items DROP CONSTRAINT fk_schedule_items_festival;

    IF EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = 'ix_schedule_items_festival_time'
          AND object_id = OBJECT_ID('dbo.schedule_items')
    )
        DROP INDEX ix_schedule_items_festival_time ON dbo.schedule_items;

    EXEC sys.sp_executesql
        N'ALTER TABLE dbo.schedule_items DROP COLUMN festival_id;';
END;

IF COL_LENGTH('dbo.music_preferences', 'genre') IS NOT NULL
BEGIN
    EXEC sys.sp_executesql N'
        INSERT INTO dbo.genres (name)
        SELECT DISTINCT LTRIM(RTRIM(preference.genre))
        FROM dbo.music_preferences AS preference
        WHERE LTRIM(RTRIM(preference.genre)) <> ''''
          AND NOT EXISTS (
              SELECT 1 FROM dbo.genres AS genre
              WHERE genre.name = LTRIM(RTRIM(preference.genre))
          );';

    CREATE TABLE dbo.music_preferences_phase3 (
        user_id UNIQUEIDENTIFIER NOT NULL,
        genre_id INT NOT NULL,
        source NVARCHAR(20) NOT NULL,
        weight DECIMAL(5,2) NOT NULL CONSTRAINT df_music_preferences_weight DEFAULT 1.00,
        CONSTRAINT pk_music_preferences_phase3 PRIMARY KEY (user_id, genre_id, source),
        CONSTRAINT ck_music_preferences_phase3_source CHECK (source IN ('manual', 'spotify')),
        CONSTRAINT fk_music_preferences_phase3_user FOREIGN KEY (user_id) REFERENCES dbo.users(id),
        CONSTRAINT fk_music_preferences_phase3_genre FOREIGN KEY (genre_id) REFERENCES dbo.genres(id)
    );

    EXEC sys.sp_executesql N'
        INSERT INTO dbo.music_preferences_phase3
            (user_id, genre_id, source, weight)
        SELECT preference.user_id, genre.id,
               preference.source, MAX(preference.weight)
        FROM dbo.music_preferences AS preference
        JOIN dbo.genres AS genre
          ON genre.name = LTRIM(RTRIM(preference.genre))
        GROUP BY preference.user_id, genre.id, preference.source;';

    DROP TABLE dbo.music_preferences;
    EXEC sp_rename 'dbo.music_preferences_phase3', 'music_preferences';
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_locations_squad_user_recorded')
    CREATE INDEX ix_locations_squad_user_recorded
        ON dbo.locations(squad_id, user_id, recorded_at DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_expenses_squad_created')
    CREATE INDEX ix_expenses_squad_created
        ON dbo.expenses(squad_id, created_at DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_schedule_items_stage_time')
    CREATE INDEX ix_schedule_items_stage_time
        ON dbo.schedule_items(stage_id, starts_at, ends_at);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_squad_members_user')
    CREATE INDEX ix_squad_members_user ON dbo.squad_members(user_id, squad_id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_stages_festival')
    CREATE INDEX ix_stages_festival ON dbo.stages(festival_id, name);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_meeting_points_squad_created')
    CREATE INDEX ix_meeting_points_squad_created
        ON dbo.meeting_points(squad_id, created_at DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_expense_participants_user')
    CREATE INDEX ix_expense_participants_user
        ON dbo.expense_participants(user_id, expense_id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_music_preferences_genre')
    CREATE INDEX ix_music_preferences_genre
        ON dbo.music_preferences(genre_id, user_id);

COMMIT TRANSACTION;
GO
