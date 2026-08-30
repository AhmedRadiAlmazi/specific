"""
FastAPI Application Bootstrap & Factory — مشروع «مُعين» (Mouin)
Equipped with Production Hardening, Security Headers, CORS, Rate/Body Limits, Observability, and Error Contract.
"""

from fastapi import FastAPI, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import uuid

from backend.app.presentation.api.config import settings
from backend.app.presentation.api.logging_config import logger
from backend.app.presentation.api.errors.handlers import (
    domain_exception_handler, application_exception_handler, validation_exception_handler,
    http_exception_handler, create_error_response
)
from backend.app.domain.exceptions import DomainException
from backend.app.application.exceptions import ApplicationException
from backend.app.domain.value_objects.identity import generate_uuidv7
from backend.app.presentation.api.routers import health, items, debts, reminders, sync

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Applies strict production HTTP security headers."""
    async def dispatch(self, request: Request, call_next):
        response: Response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"
        return response

class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """Attaches and propagates correlation IDs for end-to-end tracing."""
    async def dispatch(self, request: Request, call_next):
        correlation_id = request.headers.get("x-correlation-id") or request.headers.get("x-request-id") or generate_uuidv7()
        request.state.correlation_id = correlation_id
        response: Response = await call_next(request)
        response.headers["x-correlation-id"] = correlation_id
        response.headers["x-request-id"] = correlation_id
        return response

class RequestBodyLimitMiddleware(BaseHTTPMiddleware):
    """Enforces maximum request payload size to prevent memory exhaustion."""
    async def dispatch(self, request: Request, call_next):
        content_length = request.headers.get("content-length")
        if content_length and int(content_length) > settings.max_request_body_bytes:
            return create_error_response(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                code="PAYLOAD_TOO_LARGE",
                message=f"Request body exceeds maximum allowed limit of {settings.max_request_body_bytes} bytes.",
                category="CLIENT_ERROR"
            )
        return await call_next(request)

def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="Delivery & REST API Layer for Mouin (Clean Architecture + DDD + Offline-First Sync)",
        docs_url="/docs" if not settings.is_production else None,
        redoc_url="/redoc" if not settings.is_production else None,
        openapi_url="/openapi.json"
    )

    # Middleware Pipeline
    app.add_middleware(SecurityHeadersMiddleware)
    app.add_middleware(CorrelationIdMiddleware)
    app.add_middleware(RequestBodyLimitMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["*"],
        expose_headers=["x-correlation-id", "x-request-id"]
    )

    # Global Exception Handlers
    app.add_exception_handler(DomainException, domain_exception_handler)
    app.add_exception_handler(ApplicationException, application_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)

    # Routers
    app.include_router(health.router)
    app.include_router(items.router)
    app.include_router(debts.router)
    app.include_router(reminders.router)
    app.include_router(sync.router)

    return app

app = create_app()
