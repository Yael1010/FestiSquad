import secrets
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.domains.auth.db_models import User
from app.domains.squads.db_models import Squad, SquadMember
from app.domains.squads.schemas import (
    SquadCreateRequest,
    SquadJoinRequest,
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
