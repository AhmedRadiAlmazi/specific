"""
Unit of Work Port — مشروع «مُعين» (Mouin)
Coordinates atomic transactions across repositories and domain event dispatching.
"""

from abc import ABC, abstractmethod
from typing import Any

class IUnitOfWork(ABC):
    @abstractmethod
    def __enter__(self) -> "IUnitOfWork":
        pass

    @abstractmethod
    def __exit__(self, exc_type: Any, exc_val: Any, exc_tb: Any):
        pass

    @abstractmethod
    def commit(self):
        """Commits the current transaction atomically."""
        pass

    @abstractmethod
    def rollback(self):
        """Rolls back the current transaction."""
        pass
