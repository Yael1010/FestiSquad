from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, Unicode, UniqueConstraint, text
from sqlalchemy.dialects.mssql import DATETIME2, UNIQUEIDENTIFIER
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER,
        primary_key=True,
        default=uuid4,
        server_default=text("NEWID()"),
    )
    name: Mapped[str] = mapped_column(Unicode(120))
    email: Mapped[str] = mapped_column(Unicode(255), unique=True)
    password_hash: Mapped[str] = mapped_column(Unicode(255))
    is_platform_admin: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
        server_default=text("0"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DATETIME2,
        server_default=text("SYSUTCDATETIME()"),
    )


class ExternalAccount(Base):
    __tablename__ = "external_accounts"
    __table_args__ = (
        UniqueConstraint(
            "provider",
            "provider_user_id",
            name="uq_external_accounts_provider_user",
        ),
        UniqueConstraint(
            "user_id",
            "provider",
            name="uq_external_accounts_user_provider",
        ),
        CheckConstraint(
            "provider IN ('google', 'spotify')",
            name="ck_external_accounts_provider",
        ),
        Index("ix_external_accounts_user", "user_id"),
    )

    id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER,
        primary_key=True,
        default=uuid4,
        server_default=text("NEWID()"),
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
    )
    provider: Mapped[str] = mapped_column(Unicode(20), nullable=False)
    provider_user_id: Mapped[str] = mapped_column(Unicode(255), nullable=False)
    provider_email: Mapped[str | None] = mapped_column(Unicode(255))
    avatar_url: Mapped[str | None] = mapped_column(Unicode(1000))
    created_at: Mapped[datetime] = mapped_column(
        DATETIME2,
        server_default=text("SYSUTCDATETIME()"),
    )


class SocialAuthFlow(Base):
    __tablename__ = "social_auth_flows"
    __table_args__ = (
        CheckConstraint(
            "provider IN ('google', 'spotify')",
            name="ck_social_auth_flows_provider",
        ),
        CheckConstraint(
            "status IN ('pending', 'completed', 'failed', 'consumed')",
            name="ck_social_auth_flows_status",
        ),
        Index("ix_social_auth_flows_expires", "expires_at"),
    )

    id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER,
        primary_key=True,
        default=uuid4,
        server_default=text("NEWID()"),
    )
    provider: Mapped[str] = mapped_column(Unicode(20), nullable=False)
    flow_token_hash: Mapped[str] = mapped_column(Unicode(64), unique=True)
    status: Mapped[str] = mapped_column(Unicode(20), default="pending")
    requested_user_id: Mapped[UUID | None] = mapped_column(ForeignKey("users.id"))
    user_id: Mapped[UUID | None] = mapped_column(ForeignKey("users.id"))
    error_code: Mapped[str | None] = mapped_column(Unicode(80))
    expires_at: Mapped[datetime] = mapped_column(DATETIME2, nullable=False)
    consumed_at: Mapped[datetime | None] = mapped_column(DATETIME2)
    created_at: Mapped[datetime] = mapped_column(
        DATETIME2,
        server_default=text("SYSUTCDATETIME()"),
    )
