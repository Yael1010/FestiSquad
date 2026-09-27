USE FestiSquad;
CREATE TABLE users (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    name NVARCHAR(120) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    is_platform_admin BIT NOT NULL DEFAULT 0,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email)
);

CREATE TABLE squads (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    name NVARCHAR(120) NOT NULL,
    code CHAR(6) NOT NULL,
    owner_user_id UNIQUEIDENTIFIER NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_squads PRIMARY KEY (id),
    CONSTRAINT uq_squads_code UNIQUE (code),
    CONSTRAINT fk_squads_owner FOREIGN KEY (owner_user_id) REFERENCES users(id)
);

CREATE TABLE squad_members (
    squad_id UNIQUEIDENTIFIER NOT NULL,
    user_id UNIQUEIDENTIFIER NOT NULL,
    role NVARCHAR(20) NOT NULL,
    joined_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_squad_members PRIMARY KEY (squad_id, user_id),
    CONSTRAINT ck_squad_members_role CHECK (role IN ('admin', 'member')),
    CONSTRAINT fk_squad_members_squad FOREIGN KEY (squad_id) REFERENCES squads(id),
    CONSTRAINT fk_squad_members_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE festivals (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    name NVARCHAR(160) NOT NULL,
    venue_name NVARCHAR(160) NOT NULL,
    city NVARCHAR(120) NOT NULL,
    country_code CHAR(2) NOT NULL DEFAULT 'MX',
    timezone NVARCHAR(64) NOT NULL DEFAULT 'America/Mexico_City',
    starts_at DATETIME2 NOT NULL,
    ends_at DATETIME2 NOT NULL,
    boundary_geojson NVARCHAR(MAX) NOT NULL,
    image_url NVARCHAR(1000) NULL,
    official_url NVARCHAR(1000) NULL,
    status NVARCHAR(20) NOT NULL DEFAULT 'draft',
    updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_festivals PRIMARY KEY (id),
    CONSTRAINT ck_festivals_dates CHECK (ends_at > starts_at),
    CONSTRAINT ck_festivals_status CHECK (status IN ('draft', 'published', 'archived'))
);

CREATE TABLE stages (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    festival_id UNIQUEIDENTIFIER NOT NULL,
    name NVARCHAR(120) NOT NULL,
    polygon_geojson NVARCHAR(MAX) NOT NULL,
    CONSTRAINT pk_stages PRIMARY KEY (id),
    CONSTRAINT fk_stages_festival FOREIGN KEY (festival_id) REFERENCES festivals(id)
);

CREATE TABLE genres (
    id INT IDENTITY(1,1) NOT NULL,
    name NVARCHAR(80) NOT NULL,
    CONSTRAINT pk_genres PRIMARY KEY (id),
    CONSTRAINT uq_genres_name UNIQUE (name)
);

CREATE TABLE artists (
    id INT IDENTITY(1,1) NOT NULL,
    name NVARCHAR(160) NOT NULL,
    CONSTRAINT pk_artists PRIMARY KEY (id),
    CONSTRAINT uq_artists_name UNIQUE (name)
);

CREATE TABLE schedule_items (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    stage_id UNIQUEIDENTIFIER NOT NULL,
    artist_name NVARCHAR(160) NOT NULL,
    starts_at DATETIME2 NOT NULL,
    ends_at DATETIME2 NOT NULL,
    CONSTRAINT pk_schedule_items PRIMARY KEY (id),
    CONSTRAINT fk_schedule_items_stage FOREIGN KEY (stage_id) REFERENCES stages(id)
);

CREATE TABLE schedule_item_genres (
    schedule_item_id UNIQUEIDENTIFIER NOT NULL,
    genre_id INT NOT NULL,
    CONSTRAINT pk_schedule_item_genres PRIMARY KEY (schedule_item_id, genre_id),
    CONSTRAINT fk_schedule_item_genres_item FOREIGN KEY (schedule_item_id) REFERENCES schedule_items(id),
    CONSTRAINT fk_schedule_item_genres_genre FOREIGN KEY (genre_id) REFERENCES genres(id)
);

CREATE TABLE locations (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    squad_id UNIQUEIDENTIFIER NOT NULL,
    user_id UNIQUEIDENTIFIER NOT NULL,
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    accuracy_meters DECIMAL(8,2) NULL,
    recorded_at DATETIME2 NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_locations PRIMARY KEY (id),
    CONSTRAINT fk_locations_squad FOREIGN KEY (squad_id) REFERENCES squads(id),
    CONSTRAINT fk_locations_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE meeting_points (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    squad_id UNIQUEIDENTIFIER NOT NULL,
    title NVARCHAR(120) NOT NULL,
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    created_by_user_id UNIQUEIDENTIFIER NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_meeting_points PRIMARY KEY (id),
    CONSTRAINT fk_meeting_points_squad FOREIGN KEY (squad_id) REFERENCES squads(id),
    CONSTRAINT fk_meeting_points_user FOREIGN KEY (created_by_user_id) REFERENCES users(id)
);

CREATE TABLE expenses (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    squad_id UNIQUEIDENTIFIER NOT NULL,
    client_request_id UNIQUEIDENTIFIER NOT NULL,
    paid_by_user_id UNIQUEIDENTIFIER NOT NULL,
    description NVARCHAR(180) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_expenses PRIMARY KEY (id),
    CONSTRAINT uq_expenses_client_request UNIQUE (client_request_id),
    CONSTRAINT ck_expenses_amount CHECK (amount > 0),
    CONSTRAINT fk_expenses_squad FOREIGN KEY (squad_id) REFERENCES squads(id),
    CONSTRAINT fk_expenses_user FOREIGN KEY (paid_by_user_id) REFERENCES users(id)
);

CREATE TABLE expense_participants (
    expense_id UNIQUEIDENTIFIER NOT NULL,
    user_id UNIQUEIDENTIFIER NOT NULL,
    share_amount DECIMAL(18,2) NOT NULL,
    CONSTRAINT pk_expense_participants PRIMARY KEY (expense_id, user_id),
    CONSTRAINT ck_expense_participants_share CHECK (share_amount > 0),
    CONSTRAINT fk_expense_participants_expense FOREIGN KEY (expense_id) REFERENCES expenses(id),
    CONSTRAINT fk_expense_participants_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE music_preferences (
    user_id UNIQUEIDENTIFIER NOT NULL,
    genre_id INT NOT NULL,
    source NVARCHAR(20) NOT NULL,
    weight DECIMAL(5,2) NOT NULL DEFAULT 1.00,
    CONSTRAINT pk_music_preferences PRIMARY KEY (user_id, genre_id, source),
    CONSTRAINT ck_music_preferences_source CHECK (source IN ('manual', 'spotify')),
    CONSTRAINT fk_music_preferences_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_music_preferences_genre FOREIGN KEY (genre_id) REFERENCES genres(id)
);

CREATE TABLE music_artist_preferences (
    user_id UNIQUEIDENTIFIER NOT NULL,
    artist_id INT NOT NULL,
    source NVARCHAR(20) NOT NULL,
    weight DECIMAL(5,2) NOT NULL DEFAULT 1.00,
    CONSTRAINT pk_music_artist_preferences PRIMARY KEY (user_id, artist_id, source),
    CONSTRAINT ck_music_artist_preferences_source CHECK (source IN ('manual', 'spotify')),
    CONSTRAINT fk_music_artist_preferences_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_music_artist_preferences_artist FOREIGN KEY (artist_id) REFERENCES artists(id)
);

CREATE TABLE external_accounts (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    user_id UNIQUEIDENTIFIER NOT NULL,
    provider NVARCHAR(20) NOT NULL,
    provider_user_id NVARCHAR(255) NOT NULL,
    provider_email NVARCHAR(255) NULL,
    avatar_url NVARCHAR(1000) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_external_accounts PRIMARY KEY (id),
    CONSTRAINT uq_external_accounts_provider_user UNIQUE (provider, provider_user_id),
    CONSTRAINT uq_external_accounts_user_provider UNIQUE (user_id, provider),
    CONSTRAINT ck_external_accounts_provider CHECK (provider IN ('google', 'spotify')),
    CONSTRAINT fk_external_accounts_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE social_auth_flows (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    provider NVARCHAR(20) NOT NULL,
    flow_token_hash NVARCHAR(64) NOT NULL,
    status NVARCHAR(20) NOT NULL DEFAULT 'pending',
    requested_user_id UNIQUEIDENTIFIER NULL,
    user_id UNIQUEIDENTIFIER NULL,
    error_code NVARCHAR(80) NULL,
    expires_at DATETIME2 NOT NULL,
    consumed_at DATETIME2 NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_social_auth_flows PRIMARY KEY (id),
    CONSTRAINT uq_social_auth_flows_token UNIQUE (flow_token_hash),
    CONSTRAINT ck_social_auth_flows_provider CHECK (provider IN ('google', 'spotify')),
    CONSTRAINT ck_social_auth_flows_status CHECK (status IN ('pending', 'completed', 'failed', 'consumed')),
    CONSTRAINT fk_social_auth_flows_requested_user FOREIGN KEY (requested_user_id) REFERENCES users(id),
    CONSTRAINT fk_social_auth_flows_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX ix_locations_squad_user_recorded ON locations(squad_id, user_id, recorded_at DESC);
CREATE INDEX ix_expenses_squad_created ON expenses(squad_id, created_at DESC);
CREATE INDEX ix_schedule_items_stage_time ON schedule_items(stage_id, starts_at, ends_at);
CREATE INDEX ix_squad_members_user ON squad_members(user_id, squad_id);
CREATE INDEX ix_stages_festival ON stages(festival_id, name);
CREATE INDEX ix_festivals_status_starts ON festivals(status, starts_at);
CREATE INDEX ix_meeting_points_squad_created ON meeting_points(squad_id, created_at DESC);
CREATE INDEX ix_expense_participants_user ON expense_participants(user_id, expense_id);
CREATE INDEX ix_music_preferences_genre ON music_preferences(genre_id, user_id);
CREATE INDEX ix_music_artist_preferences_artist ON music_artist_preferences(artist_id, user_id);
CREATE INDEX ix_external_accounts_user ON external_accounts(user_id);
CREATE INDEX ix_social_auth_flows_expires ON social_auth_flows(expires_at);
