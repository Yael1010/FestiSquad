-- Referencia Fondo Comun: ejecutar SOLO en una base de pruebas vacia.
-- En el repositorio completo, usar las migraciones versionadas 001 a 009.

CREATE TABLE users (
	id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(), 
	name NVARCHAR(120) NOT NULL, 
	email NVARCHAR(255) NOT NULL, 
	password_hash NVARCHAR(255) NOT NULL, 
	created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), 
	PRIMARY KEY (id), 
	UNIQUE (email)
);

CREATE TABLE squads (
	id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(), 
	name NVARCHAR(120) NOT NULL, 
	code CHAR(6) NOT NULL, 
	owner_user_id UNIQUEIDENTIFIER NOT NULL, 
	created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), 
	PRIMARY KEY (id), 
	UNIQUE (code), 
	FOREIGN KEY(owner_user_id) REFERENCES users (id)
);

CREATE TABLE expenses (
	id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(), 
	squad_id UNIQUEIDENTIFIER NOT NULL, 
	client_request_id UNIQUEIDENTIFIER NOT NULL,
	paid_by_user_id UNIQUEIDENTIFIER NOT NULL, 
	description NVARCHAR(180) NOT NULL, 
	amount DECIMAL(18, 2) NOT NULL, 
	created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), 
	PRIMARY KEY (id), 
	CONSTRAINT uq_expenses_client_request UNIQUE (client_request_id),
	CONSTRAINT ck_expenses_amount CHECK (amount > 0), 
	FOREIGN KEY(squad_id) REFERENCES squads (id), 
	FOREIGN KEY(paid_by_user_id) REFERENCES users (id)
);

CREATE INDEX ix_expenses_squad_created ON expenses (squad_id, created_at DESC);

CREATE TABLE squad_members (
	squad_id UNIQUEIDENTIFIER NOT NULL, 
	user_id UNIQUEIDENTIFIER NOT NULL, 
	role NVARCHAR(20) NOT NULL, 
	joined_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), 
	PRIMARY KEY (squad_id, user_id), 
	CONSTRAINT ck_squad_members_role CHECK (role IN ('admin', 'member')), 
	FOREIGN KEY(squad_id) REFERENCES squads (id), 
	FOREIGN KEY(user_id) REFERENCES users (id)
);

CREATE TABLE expense_participants (
	expense_id UNIQUEIDENTIFIER NOT NULL, 
	user_id UNIQUEIDENTIFIER NOT NULL, 
	share_amount DECIMAL(18, 2) NOT NULL, 
	PRIMARY KEY (expense_id, user_id), 
	CONSTRAINT ck_expense_participants_share CHECK (share_amount > 0), 
	FOREIGN KEY(expense_id) REFERENCES expenses (id), 
	FOREIGN KEY(user_id) REFERENCES users (id)
);

CREATE TABLE settlements (
	id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
	squad_id UNIQUEIDENTIFIER NOT NULL,
	client_request_id UNIQUEIDENTIFIER NOT NULL,
	from_user_id UNIQUEIDENTIFIER NOT NULL,
	to_user_id UNIQUEIDENTIFIER NOT NULL,
	amount DECIMAL(18, 2) NOT NULL,
	note NVARCHAR(180) NULL,
	created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
	PRIMARY KEY (id),
	CONSTRAINT uq_settlements_client_request UNIQUE (client_request_id),
	CONSTRAINT ck_settlements_amount CHECK (amount > 0),
	CONSTRAINT ck_settlements_distinct_users CHECK (from_user_id <> to_user_id),
	FOREIGN KEY(squad_id) REFERENCES squads (id),
	FOREIGN KEY(from_user_id) REFERENCES users (id),
	FOREIGN KEY(to_user_id) REFERENCES users (id)
);

CREATE INDEX ix_settlements_squad_created
	ON settlements (squad_id, created_at DESC);

GO

CREATE VIEW fund_balances AS
WITH movements AS (
	SELECT squad_id, paid_by_user_id AS user_id, amount AS delta
	FROM expenses
	UNION ALL
	SELECT e.squad_id, p.user_id, -p.share_amount AS delta
	FROM expense_participants AS p
	JOIN expenses AS e ON e.id = p.expense_id
	UNION ALL
	SELECT squad_id, from_user_id AS user_id, amount AS delta
	FROM settlements
	UNION ALL
	SELECT squad_id, to_user_id AS user_id, -amount AS delta
	FROM settlements
)
SELECT squad_id, user_id, SUM(delta) AS balance
FROM movements
GROUP BY squad_id, user_id;
