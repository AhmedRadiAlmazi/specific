"""
Domain Exceptions — مشروع «مُعين» (Mouin)
Pure domain exceptions hierarchy without framework dependencies.
"""

class DomainException(Exception):
    """Base exception for all domain business rule violations."""
    pass

class InvariantViolationError(DomainException):
    """Raised when a domain aggregate or value object invariant is violated."""
    pass

class InvalidStateTransitionError(DomainException):
    """Raised when attempting an invalid state transition on a domain entity."""
    pass

class CurrencyMismatchError(DomainException):
    """Raised when performing arithmetic on Money objects with different currencies."""
    pass

class OccurrenceAlreadyExistsError(DomainException):
    """Raised when an attempt is made to generate a duplicate reminder occurrence."""
    pass

class ImmutableTransactionError(DomainException):
    """Raised when an attempt is made to edit an approved financial transaction."""
    pass
