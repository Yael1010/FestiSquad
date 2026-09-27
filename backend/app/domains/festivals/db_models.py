from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import CHAR, CheckConstraint, ForeignKey, Index, Unicode, UnicodeText, text
from sqlalchemy.dialects.mssql import DATETIME2, UNIQUEIDENTIFIER
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Festival(Base):
    __tablename__ = "festivals"
    __table_args__ = (
        CheckConstraint(
            "status IN ('draft', 'published', 'archived')",
            name="ck_festivals_status",
        ),
        Index("ix_festivals_status_starts", "status", "starts_at"),
    )

    id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER,
        primary_key=True,
        default=uuid4,
        server_default=text("NEWID()"),
    )
    name: Mapped[str] = mapped_column(Unicode(160), nullable=False)
    venue_name: Mapped[str] = mapped_column(Unicode(160), nullable=False)
    city: Mapped[str] = mapped_column(Unicode(120), nullable=False)
    country_code: Mapped[str] = mapped_column(CHAR(2), nullable=False, default="MX")
    timezone: Mapped[str] = mapped_column(
        Unicode(64), nullable=False, default="America/Mexico_City"
    )
    starts_at: Mapped[datetime] = mapped_column(DATETIME2, nullable=False)
    ends_at: Mapped[datetime] = mapped_column(DATETIME2, nullable=False)
    boundary_geojson: Mapped[str] = mapped_column(UnicodeText, nullable=False)
    image_url: Mapped[str | None] = mapped_column(Unicode(1000))
    official_url: Mapped[str | None] = mapped_column(Unicode(1000))
    status: Mapped[str] = mapped_column(Unicode(20), nullable=False, default="draft")
    updated_at: Mapped[datetime] = mapped_column(
        DATETIME2,
        server_default=text("SYSUTCDATETIME()"),
        onupdate=datetime.utcnow,
    )


class Stage(Base):
    __tablename__ = "stages"
    __table_args__ = (
        Index("ix_stages_festival", "festival_id", "name"),
    )

    id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER,
        primary_key=True,
        default=uuid4,
        server_default=text("NEWID()"),
    )
    festival_id: Mapped[UUID] = mapped_column(
        ForeignKey("festivals.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(Unicode(120), nullable=False)
    polygon_geojson: Mapped[str] = mapped_column(UnicodeText, nullable=False)
