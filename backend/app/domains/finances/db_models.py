"""Mapeo del subconjunto Fondo Común de database/001_initial_schema.sql.

No ejecutar create_all al iniciar la API. El SQL versionado administra el esquema.
Un ticket es Expense; cada cuota es ExpenseParticipant. Moneda MVP: MXN.
"""
from datetime import datetime
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import DECIMAL, CheckConstraint, ForeignKey, Index, Unicode, text
from sqlalchemy.dialects.mssql import DATETIME2, UNIQUEIDENTIFIER
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.domains.auth.db_models import User  # noqa: F401 - registers FK metadata
from app.domains.squads.db_models import Squad, SquadMember  # noqa: F401


class Expense(Base):
    __tablename__ = 'expenses'
    __table_args__ = (
        CheckConstraint('amount > 0', name='ck_expenses_amount'),
        Index('ix_expenses_squad_created', 'squad_id', text('created_at DESC')),
    )
    id: Mapped[UUID] = mapped_column(UNIQUEIDENTIFIER, primary_key=True, default=uuid4, server_default=text('NEWID()'))
    squad_id: Mapped[UUID] = mapped_column(ForeignKey('squads.id'))
    paid_by_user_id: Mapped[UUID] = mapped_column(ForeignKey('users.id'))
    description: Mapped[str] = mapped_column(Unicode(180))
    amount: Mapped[Decimal] = mapped_column(DECIMAL(18, 2, asdecimal=True))
    created_at: Mapped[datetime] = mapped_column(DATETIME2, server_default=text('SYSUTCDATETIME()'))


class ExpenseParticipant(Base):
    __tablename__ = 'expense_participants'
    __table_args__ = (CheckConstraint('share_amount > 0', name='ck_expense_participants_share'),)
    expense_id: Mapped[UUID] = mapped_column(ForeignKey('expenses.id'), primary_key=True)
    user_id: Mapped[UUID] = mapped_column(ForeignKey('users.id'), primary_key=True)
    share_amount: Mapped[Decimal] = mapped_column(DECIMAL(18, 2, asdecimal=True))
