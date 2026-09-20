-- Referencia Fondo Comun: ejecutar SOLO en una base de pruebas vacia.
-- En el repositorio completo, usar 001_initial_schema.sql y luego 002_fund_balances.sql.

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
	paid_by_user_id UNIQUEIDENTIFIER NOT NULL, 
	description NVARCHAR(180) NOT NULL, 
	amount DECIMAL(18, 2) NOT NULL, 
	created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), 
	PRIMARY KEY (id), 
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
