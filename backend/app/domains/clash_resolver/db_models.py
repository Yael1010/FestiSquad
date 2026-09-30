from decimal import Decimal
from uuid import UUID

from datetime import datetime

from sqlalchemy import CheckConstraint, ForeignKey, Index, Integer, Unicode, text
from sqlalchemy.dialects.mssql import DATETIME2, DECIMAL, UNIQUEIDENTIFIER
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.domains.auth.db_models import User  # noqa: F401 - registers FK metadata
from app.domains.festivals.db_models import ScheduleItem  # noqa: F401
from app.domains.squads.db_models import Squad  # noqa: F401


class Genre(Base):
    __tablename__ = "genres"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(Unicode(80), unique=True)


class Artist(Base):
    __tablename__ = "artists"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(Unicode(160), unique=True)


class MusicPreference(Base):
    __tablename__ = "music_preferences"
    __table_args__ = (
        CheckConstraint("source IN ('manual', 'spotify')", name="ck_music_preferences_source"),
        Index("ix_music_preferences_genre", "genre_id", "user_id"),
    )

    user_id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER, ForeignKey("users.id"), primary_key=True
    )
    genre_id: Mapped[int] = mapped_column(
        ForeignKey("genres.id"), primary_key=True
    )
    source: Mapped[str] = mapped_column(Unicode(20), primary_key=True)
    weight: Mapped[Decimal] = mapped_column(DECIMAL(5, 2), default=Decimal("1.00"))


class MusicArtistPreference(Base):
    __tablename__ = "music_artist_preferences"
    __table_args__ = (
        CheckConstraint(
            "source IN ('manual', 'spotify')",
            name="ck_music_artist_preferences_source",
        ),
        Index("ix_music_artist_preferences_artist", "artist_id", "user_id"),
    )

    user_id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER, ForeignKey("users.id"), primary_key=True
    )
    artist_id: Mapped[int] = mapped_column(
        ForeignKey("artists.id"), primary_key=True
    )
    source: Mapped[str] = mapped_column(Unicode(20), primary_key=True)
    weight: Mapped[Decimal] = mapped_column(DECIMAL(5, 2), default=Decimal("1.00"))


class ClashVote(Base):
    __tablename__ = "clash_votes"
    __table_args__ = (
        Index("ix_clash_votes_squad_item", "squad_id", "schedule_item_id"),
    )

    squad_id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER, ForeignKey("squads.id"), primary_key=True
    )
    schedule_item_id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER, ForeignKey("schedule_items.id"), primary_key=True
    )
    user_id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER, ForeignKey("users.id"), primary_key=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DATETIME2, server_default=text("SYSUTCDATETIME()")
    )


class ClashDecision(Base):
    __tablename__ = "clash_decisions"

    squad_id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER, ForeignKey("squads.id"), primary_key=True
    )
    conflict_id: Mapped[str] = mapped_column(Unicode(64), primary_key=True)
    schedule_item_id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER, ForeignKey("schedule_items.id"), nullable=False
    )
    decided_by_user_id: Mapped[UUID] = mapped_column(
        UNIQUEIDENTIFIER, ForeignKey("users.id"), nullable=False
    )
    decided_at: Mapped[datetime] = mapped_column(
        DATETIME2, server_default=text("SYSUTCDATETIME()")
    )
