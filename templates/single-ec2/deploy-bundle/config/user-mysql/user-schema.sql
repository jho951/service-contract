-- User-service baseline schema.
-- UUID identifiers are stored as canonical CHAR(36) strings with hyphens.

CREATE TABLE IF NOT EXISTS users (
	user_id CHAR(36) NOT NULL,
	email VARCHAR(191) NOT NULL,
	role VARCHAR(20) NOT NULL,
	status CHAR(1) NOT NULL,
	version BIGINT NOT NULL DEFAULT 0,
	created_at DATETIME(6) NOT NULL,
	modified_at DATETIME(6) NOT NULL,
	PRIMARY KEY (user_id),
	UNIQUE KEY uk_users_email (email)
);

CREATE TABLE IF NOT EXISTS user_social_accounts (
	user_social_id CHAR(36) NOT NULL,
	social_type VARCHAR(3) NOT NULL,
	provider_id VARCHAR(150) NOT NULL,
	email VARCHAR(191) NULL,
	user_id CHAR(36) NOT NULL,
	version BIGINT NOT NULL DEFAULT 0,
	created_at DATETIME(6) NOT NULL,
	modified_at DATETIME(6) NOT NULL,
	PRIMARY KEY (user_social_id),
	UNIQUE KEY uk_user_social_provider_key (social_type, provider_id),
	KEY ix_user_social_accounts_user_id (user_id),
	CONSTRAINT fk_user_social_accounts_user
		FOREIGN KEY (user_id) REFERENCES users (user_id)
);
