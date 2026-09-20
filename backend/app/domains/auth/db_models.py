from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import Unicode, text
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
    created_at: Mapped[datetime] = mapped_column(
        DATETIME2,
        server_default=text("SYSUTCDATETIME()"),
    )
