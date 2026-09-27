from unittest.mock import MagicMock
from uuid import UUID

import pytest
from jose import JWTError
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.domains.auth.db_models import User
from app.domains.auth.schemas import LoginRequest
from app.domains.auth.service import AuthService, password_context
from app.domains.squads.db_models import Squad, SquadMember
from app.domains.squads.schemas import (
    SquadCreateRequest,
    SquadJoinRequest,
    SquadRoleUpdateRequest,
)
from app.domains.squads.service import SquadService

USER_ID = UUID("00000000-0000-0000-0000-000000000001")
SQUAD_ID = UUID("00000000-0000-0000-0000-000000000002")
MEMBER_ID = UUID("00000000-0000-0000-0000-000000000003")


def make_user() -> User:
    return User(
        id=USER_ID,
        name="Yael",
        email="yael@example.com",
        password_hash=password_context.hash("correct-password"),
    )


def test_login_issues_access_and_refresh_tokens():
    db = MagicMock(spec=Session)
    user = make_user()
    db.scalar.return_value = user
    db.get.return_value = user
    service = AuthService()

    session = service.login(
        db,
        LoginRequest(email="YAEL@example.com", password="correct-password"),
    )

    assert session.user_id == str(USER_ID)
    assert service.authenticate(db, session.access_token).id == USER_ID
    assert service.refresh(db, session.refresh_token).user_id == str(USER_ID)


def test_refresh_rejects_access_token():
    service = AuthService()
    access_token = service._issue_session(str(USER_ID)).access_token

    with pytest.raises((JWTError, ValueError)):
        service.refresh(MagicMock(spec=Session), access_token)


def test_squad_requests_cannot_spoof_identity():
    with pytest.raises(ValidationError):
        SquadCreateRequest(name="Amigos", owner_id=str(USER_ID))
    with pytest.raises(ValidationError):
        SquadJoinRequest(code="A1B2C3", user_id=str(USER_ID))


def test_creator_becomes_admin(monkeypatch):
    db = MagicMock(spec=Session)
    owner = make_user()
    membership = SquadMember(
        squad_id=SQUAD_ID,
        user_id=USER_ID,
        role="admin",
    )
    db.scalar.return_value = None
    db.scalars.return_value = [membership]
    monkeypatch.setattr("app.domains.squads.service.uuid4", lambda: SQUAD_ID)
    monkeypatch.setattr("app.domains.squads.service.secrets.token_hex", lambda _: "a1b2c3")

    result = SquadService().create(
        db,
        SquadCreateRequest(name="  Headliners  "),
        owner,
    )

    assert result.name == "Headliners"
    assert result.code == "A1B2C3"
    assert result.current_user_role == "admin"
    assert result.member_ids == [str(USER_ID)]
    db.commit.assert_called_once()


def test_join_is_idempotent_for_existing_member():
    db = MagicMock(spec=Session)
    user = make_user()
    squad = Squad(
        id=SQUAD_ID,
        name="Headliners",
        code="A1B2C3",
        owner_user_id=USER_ID,
    )
    membership = SquadMember(
        squad_id=SQUAD_ID,
        user_id=USER_ID,
        role="admin",
    )
    db.scalar.return_value = squad
    db.get.return_value = membership
    db.scalars.return_value = [membership]

    result = SquadService().join(
        db,
        SquadJoinRequest(code="a1b2c3"),
        user,
    )

    assert result.current_user_role == "admin"
    db.commit.assert_not_called()


def test_list_only_returns_current_user_squads():
    db = MagicMock(spec=Session)
    user = make_user()
    squad = Squad(
        id=SQUAD_ID,
        name="Headliners",
        code="A1B2C3",
        owner_user_id=USER_ID,
    )
    membership = SquadMember(
        squad_id=SQUAD_ID,
        user_id=USER_ID,
        role="admin",
    )
    db.scalars.side_effect = [[squad], [membership]]

    result = SquadService().list_for_user(db, user)

    assert [item.id for item in result] == [str(SQUAD_ID)]
    assert result[0].member_ids == [str(USER_ID)]


def _membership_lookup(squad: Squad, memberships: dict[UUID, SquadMember]):
    def lookup(model, key):
        if model is Squad:
            return squad
        if model is SquadMember:
            return memberships.get(key[1])
        return None

    return lookup


def test_regular_member_cannot_change_roles():
    db = MagicMock(spec=Session)
    actor = make_user()
    squad = Squad(
        id=SQUAD_ID,
        name="Headliners",
        code="A1B2C3",
        owner_user_id=MEMBER_ID,
    )
    memberships = {
        USER_ID: SquadMember(squad_id=SQUAD_ID, user_id=USER_ID, role="member"),
        MEMBER_ID: SquadMember(squad_id=SQUAD_ID, user_id=MEMBER_ID, role="admin"),
    }
    db.get.side_effect = _membership_lookup(squad, memberships)

    with pytest.raises(PermissionError):
        SquadService().update_role(db, SQUAD_ID, MEMBER_ID, "member", actor)

    db.commit.assert_not_called()


def test_owner_role_cannot_be_demoted():
    db = MagicMock(spec=Session)
    owner = make_user()
    squad = Squad(
        id=SQUAD_ID,
        name="Headliners",
        code="A1B2C3",
        owner_user_id=USER_ID,
    )
    memberships = {
        USER_ID: SquadMember(squad_id=SQUAD_ID, user_id=USER_ID, role="admin"),
    }
    db.get.side_effect = _membership_lookup(squad, memberships)

    with pytest.raises(ValueError, match="owner_role_locked"):
        SquadService().update_role(db, SQUAD_ID, USER_ID, "member", owner)

    db.commit.assert_not_called()


def test_owner_can_transfer_ownership_to_another_member():
    db = MagicMock(spec=Session)
    owner = make_user()
    squad = Squad(
        id=SQUAD_ID,
        name="Headliners",
        code="A1B2C3",
        owner_user_id=USER_ID,
    )
    old_owner = SquadMember(squad_id=SQUAD_ID, user_id=USER_ID, role="admin")
    new_owner = SquadMember(squad_id=SQUAD_ID, user_id=MEMBER_ID, role="member")
    db.get.side_effect = _membership_lookup(
        squad,
        {USER_ID: old_owner, MEMBER_ID: new_owner},
    )

    SquadService().transfer_ownership(db, SQUAD_ID, MEMBER_ID, owner)

    assert squad.owner_user_id == MEMBER_ID
    assert new_owner.role == "admin"
    assert old_owner.role == "admin"
    db.commit.assert_called_once()


def test_non_owner_member_can_leave_squad():
    db = MagicMock(spec=Session)
    member = make_user()
    squad = Squad(
        id=SQUAD_ID,
        name="Headliners",
        code="A1B2C3",
        owner_user_id=MEMBER_ID,
    )
    membership = SquadMember(
        squad_id=SQUAD_ID,
        user_id=USER_ID,
        role="member",
    )
    db.get.side_effect = _membership_lookup(squad, {USER_ID: membership})

    SquadService().remove_member(db, SQUAD_ID, USER_ID, member)

    db.delete.assert_called_once_with(membership)
    db.commit.assert_called_once()


def test_role_update_rejects_unknown_roles():
    with pytest.raises(ValidationError):
        SquadRoleUpdateRequest(role="owner")
