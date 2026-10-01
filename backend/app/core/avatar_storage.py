from pathlib import Path
from uuid import UUID, uuid4


class AvatarValidationError(ValueError):
    """La imagen recibida no cumple las reglas de perfil."""


class AvatarStorage:
    max_bytes = 5 * 1024 * 1024

    def __init__(self, root: Path | None = None) -> None:
        self.root = root or Path(__file__).resolve().parents[2] / "storage"
        self.avatars_root = self.root / "avatars"
        self.avatars_root.mkdir(parents=True, exist_ok=True)

    def save(self, user_id: UUID, content: bytes) -> str:
        if not content:
            raise AvatarValidationError("La imagen está vacía.")
        if len(content) > self.max_bytes:
            raise AvatarValidationError("La imagen no puede superar 5 MB.")

        extension = self._extension_for(content)
        if extension is None:
            raise AvatarValidationError("Selecciona una imagen JPEG, PNG o WebP válida.")

        filename = f"{user_id}-{uuid4().hex}{extension}"
        destination = self.avatars_root / filename
        destination.write_bytes(content)
        return f"/media/avatars/{filename}"

    def delete(self, relative_url: str | None) -> None:
        if not relative_url or not relative_url.startswith("/media/avatars/"):
            return
        candidate = self.avatars_root / Path(relative_url).name
        if candidate.parent == self.avatars_root and candidate.is_file():
            candidate.unlink()

    @staticmethod
    def _extension_for(content: bytes) -> str | None:
        if content.startswith(b"\xff\xd8\xff"):
            return ".jpg"
        if content.startswith(b"\x89PNG\r\n\x1a\n"):
            return ".png"
        if len(content) >= 12 and content.startswith(b"RIFF") and content[8:12] == b"WEBP":
            return ".webp"
        return None


avatar_storage = AvatarStorage()
