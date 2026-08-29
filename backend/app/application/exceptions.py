"""
Application Layer Exceptions — مشروع «مُعين» (Mouin)
"""

class ApplicationException(Exception):
    """Base exception for all application layer errors."""
    pass

class NotFoundError(ApplicationException):
    """Raised when a requested resource is not found in the workspace."""
    pass

class UnauthorizedWorkspaceAccessError(ApplicationException):
    """Raised when an operation attempts to access a resource in a different workspace."""
    pass

class IdempotencyConflictError(ApplicationException):
    """Raised when an operation ID is reused with a different payload hash."""
    pass

class ConcurrencyConflictError(ApplicationException):
    """Raised when an entity version conflict is detected during optimistic locking."""
    pass
