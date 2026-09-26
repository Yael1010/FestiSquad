USE FestiSquad;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('dbo.artists', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.artists (
        id INT IDENTITY(1,1) NOT NULL,
        name NVARCHAR(160) NOT NULL,
        CONSTRAINT pk_artists PRIMARY KEY (id),
        CONSTRAINT uq_artists_name UNIQUE (name)
    );
END;

IF OBJECT_ID('dbo.music_artist_preferences', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.music_artist_preferences (
        user_id UNIQUEIDENTIFIER NOT NULL,
        artist_id INT NOT NULL,
        source NVARCHAR(20) NOT NULL,
        weight DECIMAL(5,2) NOT NULL CONSTRAINT df_music_artist_preferences_weight DEFAULT 1.00,
        CONSTRAINT pk_music_artist_preferences PRIMARY KEY (user_id, artist_id, source),
        CONSTRAINT ck_music_artist_preferences_source CHECK (source IN ('manual', 'spotify')),
        CONSTRAINT fk_music_artist_preferences_user FOREIGN KEY (user_id) REFERENCES dbo.users(id),
        CONSTRAINT fk_music_artist_preferences_artist FOREIGN KEY (artist_id) REFERENCES dbo.artists(id)
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'ix_music_artist_preferences_artist'
      AND object_id = OBJECT_ID('dbo.music_artist_preferences')
)
BEGIN
    CREATE INDEX ix_music_artist_preferences_artist
        ON dbo.music_artist_preferences(artist_id, user_id);
END;

COMMIT TRANSACTION;
GO
