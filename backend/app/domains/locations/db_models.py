from datetime import datetime
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import ForeignKey, Numeric, Unicode, text
from sqlalchemy.dialects.mssql import DATETIME2, UNIQUEIDENTIFIER
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.domains.auth.db_models import User  # noqa: F401
from app.domains.squads.db_models import Squad  # noqa: F401


class Location(Base):
    __tablename__ = "locations"

    id: Mapped[UUID] = mapped_column(UNIQUEIDENTIFIER, primary_key=True, default=uuid4)
    squad_id: Mapped[UUID] = mapped_column(ForeignKey("squads.id"))
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    latitude: Mapped[Decimal] = mapped_column(Numeric(9, 6))
    longitude: Mapped[Decimal] = mapped_column(Numeric(9, 6))
    accuracy_meters: Mapped[Decimal | None] = mapped_column(Numeric(8, 2))
    recorded_at: Mapped[datetime] = mapped_column(DATETIME2)
    created_at: Mapped[datetime] = mapped_column(
        DATETIME2, server_default=text("SYSUTCDATETIME()")
    )


class MeetingPoint(Base):
    __tablename__ = "meeting_points"

    id: Mapped[UUID] = mapped_column(UNIQUEIDENTIFIER, primary_key=True, default=uuid4)
    squad_id: Mapped[UUID] = mapped_column(ForeignKey("squads.id"))
    title: Mapped[str] = mapped_column(Unicode(120))
    latitude: Mapped[Decimal] = mapped_column(Numeric(9, 6))
    longitude: Mapped[Decimal] = mapped_column(Numeric(9, 6))
    created_by_user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(
        DATETIME2, server_default=text("SYSUTCDATETIME()")
    )
