from uuid import UUID

import pytest

from app.core.avatar_storage import AvatarStorage, AvatarValidationError
from app.domains.auth.db_models import User


def test_avatar_storage_accepts_png_and_keeps_path_under_media(tmp_path):
    storage = AvatarStorage(tmp_path)
    user_id = UUID("00000000-0000-0000-0000-000000000001")

    relative_url = storage.save(user_id, b"\x89PNG\r\n\x1a\nimage-data")

    assert relative_url.startswith("/media/avatars/")
    assert (tmp_path / "avatars" / relative_url.rsplit("/", 1)[1]).is_file()


@pytest.mark.parametrize("content", [b"not-an-image", b""])
def test_avatar_storage_rejects_unrecognized_content(tmp_path, content):
    with pytest.raises(AvatarValidationError):
        AvatarStorage(tmp_path).save(
            UUID("00000000-0000-0000-0000-000000000001"), content
        )


def test_avatar_storage_rejects_oversized_content(tmp_path):
    storage = AvatarStorage(tmp_path)
    content = b"\xff\xd8\xff" + b"x" * storage.max_bytes

    with pytest.raises(AvatarValidationError, match="5 MB"):
        storage.save(UUID("00000000-0000-0000-0000-000000000001"), content)


def test_custom_avatar_value_is_available_on_the_user_model():
    user = User(
        id=UUID("00000000-0000-0000-0000-000000000001"),
        name="Yael",
        email="yael@example.com",
        password_hash="hash",
        avatar_url="/media/avatars/yael.png",
    )

    assert user.avatar_url == "/media/avatars/yael.png"
