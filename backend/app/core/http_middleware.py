import logging
from time import perf_counter
from uuid import uuid4

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import JSONResponse, Response

from app.core.settings import Settings

logger = logging.getLogger("festisquad.http")


class QualityMiddleware(BaseHTTPMiddleware):
    """Aplica controles transversales sin acoplarlos a los dominios."""

    def __init__(self, app, *, settings: Settings):
        super().__init__(app)
        self.settings = settings

    async def dispatch(
        self,
        request: Request,
        call_next: RequestResponseEndpoint,
    ) -> Response:
        request_id = self._request_id(request.headers.get("X-Request-ID"))
        content_length = self._content_length(request.headers.get("Content-Length"))
        if (
            content_length is not None
            and content_length > self.settings.max_request_body_bytes
        ):
            return self._finalize(
                JSONResponse(
                    status_code=413,
                    content={"detail": "request_body_too_large", "request_id": request_id},
                ),
                request_id=request_id,
                elapsed_ms=0,
            )

        if self.settings.environment in ("staging", "production"):
            forwarded_proto = request.headers.get(
                "X-Forwarded-Proto",
                request.url.scheme,
            )
            if forwarded_proto.lower() != "https":
                return self._finalize(
                    JSONResponse(
                        status_code=400,
                        content={"detail": "https_required", "request_id": request_id},
                    ),
                    request_id=request_id,
                    elapsed_ms=0,
                )

        started = perf_counter()
        try:
            response = await call_next(request)
        except Exception:
            elapsed_ms = (perf_counter() - started) * 1000
            logger.exception("Unhandled request error request_id=%s", request_id)
            return self._finalize(
                JSONResponse(
                    status_code=500,
                    content={"detail": "internal_server_error", "request_id": request_id},
                ),
                request_id=request_id,
                elapsed_ms=elapsed_ms,
            )

        elapsed_ms = (perf_counter() - started) * 1000
        if elapsed_ms > self.settings.performance_target_ms:
            logger.warning(
                "Slow request method=%s path=%s duration_ms=%.2f request_id=%s",
                request.method,
                request.url.path,
                elapsed_ms,
                request_id,
            )
        return self._finalize(
            response,
            request_id=request_id,
            elapsed_ms=elapsed_ms,
        )

    def _finalize(
        self,
        response: Response,
        *,
        request_id: str,
        elapsed_ms: float,
    ) -> Response:
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Process-Time-Ms"] = f"{elapsed_ms:.2f}"
        response.headers["Server-Timing"] = f"app;dur={elapsed_ms:.2f}"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Permissions-Policy"] = "geolocation=(), camera=(), microphone=()"
        response.headers["Cache-Control"] = "no-store"
        if self.settings.environment in ("staging", "production"):
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains"
            )
        return response

    @staticmethod
    def _request_id(candidate: str | None) -> str:
        if candidate and 1 <= len(candidate) <= 64 and all(
            char.isalnum() or char in "-_." for char in candidate
        ):
            return candidate
        return str(uuid4())

    @staticmethod
    def _content_length(value: str | None) -> int | None:
        if value is None:
            return None
        try:
            return max(0, int(value))
        except ValueError:
            return None
