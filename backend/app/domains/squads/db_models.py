from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import CHAR, CheckConstraint, ForeignKey, Unicode, text
from sqlalchemy.dialects.mssql import DATETIME2, UNIQUEIDENTIFIER
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.domains.auth.db_models import User  # noqa: F401 - registers FK metadata


class Squad(Base):
    __tablename__ = "squads"

    id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER,
        primary_key=True,
        default=uuid4,
        server_default=text("NEWID()"),
    )
    name: Mapped[str] = mapped_column(Unicode(120))
    code: Mapped[str] = mapped_column(CHAR(6), unique=True)
    owner_user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(
        DATETIME2,
        server_default=text("SYSUTCDATETIME()"),
    )


class SquadMember(Base):
    __tablename__ = "squad_members"
    __table_args__ = (
        CheckConstraint(
            "role IN ('admin', 'member')",
            name="ck_squad_members_role",
        ),
    )

    squad_id: Mapped[UUID] = mapped_column(
        ForeignKey("squads.id"),
        primary_key=True,
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id"),
        primary_key=True,
    )
    role: Mapped[str] = mapped_column(Unicode(20))
    joined_at: Mapped[datetime] = mapped_column(
        DATETIME2,
        server_default=text("SYSUTCDATETIME()"),
    )
