import secrets
from uuid import UUID, uuid4

from sqlalchemy import delete, func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.domains.auth.db_models import ExternalAccount, User
from app.domains.finances.db_models import Expense, ExpenseParticipant
from app.domains.locations.db_models import Location, MeetingPoint
from app.domains.squads.db_models import Squad, SquadMember
from app.domains.squads.schemas import (
    SquadCreateRequest,
    SquadJoinRequest,
    SquadMemberResponse,
    SquadResponse,
)


class SquadService:
    def create(
        self,
        db: Session,
        payload: SquadCreateRequest,
        owner: User,
    ) -> SquadResponse:
        squad = Squad(
            id=uuid4(),
            name=payload.name.strip(),
            code=self._unique_code(db),
            owner_user_id=owner.id,
        )
        try:
            db.add(squad)
            db.flush()
            db.add(
                SquadMember(
                    squad_id=squad.id,
                    user_id=owner.id,
                    role="admin",
                )
            )
            db.commit()
        except IntegrityError as exc:
            db.rollback()
            raise ValueError("squad_code_collision") from exc
        return self._response(db, squad, owner.id)

    def join(
        self,
        db: Session,
        payload: SquadJoinRequest,
        user: User,
    ) -> SquadResponse:
        squad = db.scalar(select(Squad).where(Squad.code == payload.code))
        if squad is None:
            raise ValueError("squad_not_found")

        membership = db.get(SquadMember, (squad.id, user.id))
        if membership is None:
            db.add(
                SquadMember(
                    squad_id=squad.id,
                    user_id=user.id,
                    role="member",
                )
            )
            db.commit()
        return self._response(db, squad, user.id)

    def get(self, db: Session, squad_id: UUID, user: User) -> SquadResponse:
        squad = db.get(Squad, squad_id)
        if squad is None:
            raise ValueError("squad_not_found")
        self.require_member(db, squad.id, user.id)
        return self._response(db, squad, user.id)

    def list_for_user(self, db: Session, user: User) -> list[SquadResponse]:
        squads = list(
            db.scalars(
                select(Squad)
                .join(SquadMember, SquadMember.squad_id == Squad.id)
                .where(SquadMember.user_id == user.id)
                .order_by(Squad.created_at.desc())
            )
        )
        return [self._response(db, squad, user.id) for squad in squads]

    def require_member(
        self,
        db: Session,
        squad_id: UUID,
        user_id: UUID,
    ) -> SquadMember:
        membership = db.get(SquadMember, (squad_id, user_id))
        if membership is None:
            raise PermissionError("not_a_squad_member")
        return membership

    def members(
        self,
        db: Session,
        squad_id: UUID,
        current_user: User,
    ) -> list[SquadMemberResponse]:
        squad = self._squad_for_member(db, squad_id, current_user.id)
        rows = list(
            db.execute(
                select(SquadMember, User)
                .join(User, User.id == SquadMember.user_id)
                .where(SquadMember.squad_id == squad_id)
                .order_by(SquadMember.joined_at, User.name)
            ).all()
        )
        user_ids = [membership.user_id for membership, _ in rows]
        avatars: dict[UUID, str] = {}
        if user_ids:
            for user_id, avatar_url in db.execute(
                select(ExternalAccount.user_id, ExternalAccount.avatar_url).where(
                    ExternalAccount.user_id.in_(user_ids),
                    ExternalAccount.avatar_url.is_not(None),
                )
            ):
                avatars.setdefault(user_id, avatar_url)
        latest_locations = dict(
            db.execute(
                select(Location.user_id, func.max(Location.recorded_at))
                .where(Location.squad_id == squad_id)
                .group_by(Location.user_id)
            ).all()
        )
        return [
            SquadMemberResponse(
                user_id=str(user.id),
                name=user.name,
                avatar_url=avatars.get(user.id),
                role=membership.role,
                joined_at=membership.joined_at,
                last_location_at=latest_locations.get(user.id),
                is_owner=user.id == squad.owner_user_id,
                is_current_user=user.id == current_user.id,
            )
            for membership, user in rows
        ]

    def update_role(
        self,
        db: Session,
        squad_id: UUID,
        target_user_id: UUID,
        role: str,
        actor: User,
    ) -> None:
        squad = self._squad_for_member(db, squad_id, actor.id)
        self._require_admin(db, squad_id, actor.id)
        target = self.require_member(db, squad_id, target_user_id)
        if target_user_id == squad.owner_user_id:
            raise ValueError("owner_role_locked")
        target.role = role
        db.commit()

    def remove_member(
        self,
        db: Session,
        squad_id: UUID,
        target_user_id: UUID,
        actor: User,
    ) -> None:
        squad = self._squad_for_member(db, squad_id, actor.id)
        if target_user_id == squad.owner_user_id:
            raise ValueError("owner_cannot_leave")
        if target_user_id != actor.id:
            self._require_admin(db, squad_id, actor.id)
        target = self.require_member(db, squad_id, target_user_id)
        db.delete(target)
        db.commit()

    def transfer_ownership(
        self,
        db: Session,
        squad_id: UUID,
        target_user_id: UUID,
        actor: User,
    ) -> None:
        squad = self._squad_for_member(db, squad_id, actor.id)
        if squad.owner_user_id != actor.id:
            raise PermissionError("owner_required")
        if target_user_id == actor.id:
            raise ValueError("already_owner")
        target = self.require_member(db, squad_id, target_user_id)
        current = self.require_member(db, squad_id, actor.id)
        target.role = "admin"
        current.role = "admin"
        squad.owner_user_id = target_user_id
        db.commit()

    def delete_squad(self, db: Session, squad_id: UUID, actor: User) -> None:
        squad = self._squad_for_member(db, squad_id, actor.id)
        if squad.owner_user_id != actor.id:
            raise PermissionError("owner_required")
        expense_ids = select(Expense.id).where(Expense.squad_id == squad_id)
        db.execute(
            delete(ExpenseParticipant).where(
                ExpenseParticipant.expense_id.in_(expense_ids)
            )
        )
        db.execute(delete(Expense).where(Expense.squad_id == squad_id))
        db.execute(delete(Location).where(Location.squad_id == squad_id))
        db.execute(delete(MeetingPoint).where(MeetingPoint.squad_id == squad_id))
        db.execute(delete(SquadMember).where(SquadMember.squad_id == squad_id))
        db.delete(squad)
        db.commit()

    def _squad_for_member(
        self,
        db: Session,
        squad_id: UUID,
        user_id: UUID,
    ) -> Squad:
        squad = db.get(Squad, squad_id)
        if squad is None:
            raise ValueError("squad_not_found")
        self.require_member(db, squad_id, user_id)
        return squad

    def _require_admin(
        self,
        db: Session,
        squad_id: UUID,
        user_id: UUID,
    ) -> SquadMember:
        membership = self.require_member(db, squad_id, user_id)
        if membership.role != "admin":
            raise PermissionError("admin_required")
        return membership

    def _response(
        self,
        db: Session,
        squad: Squad,
        current_user_id: UUID,
    ) -> SquadResponse:
        memberships = list(
            db.scalars(
                select(SquadMember).where(SquadMember.squad_id == squad.id)
            )
        )
        role = next(
            membership.role
            for membership in memberships
            if membership.user_id == current_user_id
        )
        return SquadResponse(
            id=str(squad.id),
            name=squad.name,
            code=squad.code.strip(),
            owner_id=str(squad.owner_user_id),
            member_ids=[str(membership.user_id) for membership in memberships],
            current_user_role=role,
        )

    def _unique_code(self, db: Session) -> str:
        for _ in range(10):
            code = secrets.token_hex(3).upper()
            exists = db.scalar(select(Squad.id).where(Squad.code == code))
            if exists is None:
                return code
        raise RuntimeError("unable_to_allocate_squad_code")


squad_service = SquadService()
