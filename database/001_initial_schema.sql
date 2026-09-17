CREATE TABLE users (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    name NVARCHAR(120) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
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
    starts_at DATETIME2 NOT NULL,
    ends_at DATETIME2 NOT NULL,
    boundary_geojson NVARCHAR(MAX) NOT NULL,
    CONSTRAINT pk_festivals PRIMARY KEY (id)
);

CREATE TABLE stages (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    festival_id UNIQUEIDENTIFIER NOT NULL,
    name NVARCHAR(120) NOT NULL,
    polygon_geojson NVARCHAR(MAX) NOT NULL,
    CONSTRAINT pk_stages PRIMARY KEY (id),
    CONSTRAINT fk_stages_festival FOREIGN KEY (festival_id) REFERENCES festivals(id)
);

CREATE TABLE schedule_items (
    id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    festival_id UNIQUEIDENTIFIER NOT NULL,
    stage_id UNIQUEIDENTIFIER NOT NULL,
    artist_name NVARCHAR(160) NOT NULL,
    starts_at DATETIME2 NOT NULL,
    ends_at DATETIME2 NOT NULL,
    genres_csv NVARCHAR(400) NOT NULL DEFAULT '',
    CONSTRAINT pk_schedule_items PRIMARY KEY (id),
    CONSTRAINT fk_schedule_items_festival FOREIGN KEY (festival_id) REFERENCES festivals(id),
    CONSTRAINT fk_schedule_items_stage FOREIGN KEY (stage_id) REFERENCES stages(id)
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
    paid_by_user_id UNIQUEIDENTIFIER NOT NULL,
    description NVARCHAR(180) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_expenses PRIMARY KEY (id),
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
    genre NVARCHAR(80) NOT NULL,
    source NVARCHAR(20) NOT NULL,
    weight DECIMAL(5,2) NOT NULL DEFAULT 1.00,
    CONSTRAINT pk_music_preferences PRIMARY KEY (user_id, genre, source),
    CONSTRAINT ck_music_preferences_source CHECK (source IN ('manual', 'spotify')),
    CONSTRAINT fk_music_preferences_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX ix_locations_squad_user_recorded ON locations(squad_id, user_id, recorded_at DESC);
CREATE INDEX ix_expenses_squad_created ON expenses(squad_id, created_at DESC);
CREATE INDEX ix_schedule_items_festival_time ON schedule_items(festival_id, starts_at, ends_at);

