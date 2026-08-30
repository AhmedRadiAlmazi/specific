"""
Global Exception Handlers & Unified Error Taxonomy — مشروع «مُعين» (Mouin)
"""

from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from datetime import datetime, timezone

from backend.app.domain.exceptions import (
    DomainException, InvariantViolationError, InvalidStateTransitionError,
    CurrencyMismatchError, OccurrenceAlreadyExistsError, ImmutableTransactionError
)
from backend.app.application.exceptions import (
    ApplicationException, NotFoundError, UnauthorizedWorkspaceAccessError,
    IdempotencyConflictError, ConcurrencyConflictError
)
from backend.app.presentation.api.schemas.common import ErrorResponse, ErrorBody, ErrorDetail

def create_error_response(status_code: int, code: str, message: str, category: str, details=None) -> JSONResponse:
    body = ErrorBody(
        code=code,
        message=message,
        category=category,
        timestamp=datetime.now(timezone.utc).isoformat(),
        details=details or []
    )
    return JSONResponse(status_code=status_code, content=ErrorResponse(error=body).model_dump())

async def domain_exception_handler(request: Request, exc: DomainException):
    code = "DOMAIN_INVARIANT_VIOLATION"
    status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
    if isinstance(exc, OccurrenceAlreadyExistsError):
        code = "OCCURRENCE_DUPLICATE"
        status_code = status.HTTP_409_CONFLICT
    elif isinstance(exc, ImmutableTransactionError):
        code = "IMMUTABLE_TRANSACTION_VIOLATION"
        status_code = status.HTTP_400_BAD_REQUEST
    elif isinstance(exc, InvalidStateTransitionError):
        code = "INVALID_STATE_TRANSITION"
        status_code = status.HTTP_400_BAD_REQUEST

    return create_error_response(
        status_code=status_code,
        code=code,
        message=str(exc),
        category="DOMAIN_ERROR"
    )

async def application_exception_handler(request: Request, exc: ApplicationException):
    if isinstance(exc, NotFoundError):
        return create_error_response(
            status_code=status.HTTP_404_NOT_FOUND,
            code="RESOURCE_NOT_FOUND",
            message=str(exc),
            category="NOT_FOUND"
        )
    elif isinstance(exc, UnauthorizedWorkspaceAccessError):
        return create_error_response(
            status_code=status.HTTP_403_FORBIDDEN,
            code="UNAUTHORIZED_WORKSPACE_ACCESS",
            message=str(exc),
            category="AUTHORIZATION_ERROR"
        )
    elif isinstance(exc, IdempotencyConflictError):
        return create_error_response(
            status_code=status.HTTP_409_CONFLICT,
            code="IDEMPOTENCY_CONFLICT",
            message=str(exc),
            category="CONFLICT"
        )
    elif isinstance(exc, ConcurrencyConflictError):
        return create_error_response(
            status_code=status.HTTP_409_CONFLICT,
            code="CONCURRENCY_CONFLICT",
            message=str(exc),
            category="CONFLICT"
        )
    return create_error_response(
        status_code=status.HTTP_400_BAD_REQUEST,
        code="APPLICATION_ERROR",
        message=str(exc),
        category="APPLICATION_ERROR"
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError):
    details = []
    for err in exc.errors():
        field_name = " -> ".join([str(loc) for loc in err.get("loc", [])])
        details.append(ErrorDetail(field=field_name, issue=err.get("msg", "Invalid input")))
    
    return create_error_response(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        code="VALIDATION_ERROR",
        message="Request validation failed. Check input details.",
        category="VALIDATION_ERROR",
        details=details
    )

async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    code_map = {
        400: "BAD_REQUEST",
        401: "UNAUTHORIZED",
        403: "WORKSPACE_FORBIDDEN",
        404: "NOT_FOUND",
        409: "CONFLICT",
        422: "UNPROCESSABLE_ENTITY",
        500: "INTERNAL_SERVER_ERROR",
    }
    code = code_map.get(exc.status_code, f"HTTP_{exc.status_code}")
    category = "SECURITY_ERROR" if exc.status_code in (401, 403) else ("NOT_FOUND" if exc.status_code == 404 else "CLIENT_ERROR")
    return create_error_response(
        status_code=exc.status_code,
        code=code,
        message=str(exc.detail),
        category=category
    )
