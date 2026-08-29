"""
Identity Value Objects & UUIDv7 Generator — مشروع «مُعين» (Mouin)
"""

from dataclasses import dataclass
from datetime import datetime, timezone
import os
import uuid
from backend.app.domain.exceptions import InvariantViolationError

def generate_uuidv7() -> str:
    """Generate an RFC 9562 compliant canonical UUIDv7 string."""
    ms = int(datetime.now(timezone.utc).timestamp() * 1000)
    rand_bytes = os.urandom(10)
    
    b0 = (ms >> 40) & 0xFF
    b1 = (ms >> 32) & 0xFF
    b2 = (ms >> 24) & 0xFF
    b3 = (ms >> 16) & 0xFF
    b4 = (ms >> 8) & 0xFF
    b5 = ms & 0xFF
    
    b6 = 0x70 | (rand_bytes[0] & 0x0F)
    b7 = rand_bytes[1]
    b8 = 0x80 | (rand_bytes[2] & 0x3F)
    b9_15 = rand_bytes[3:10]
    
    raw = bytes([b0, b1, b2, b3, b4, b5, b6, b7, b8]) + b9_15
    return str(uuid.UUID(bytes=raw))

@dataclass(frozen=True)
class EntityId:
    value: str

    def __post_init__(self):
        if not self.value or not isinstance(self.value, str):
            raise InvariantViolationError("EntityId cannot be empty and must be a string.")
        try:
            parsed = uuid.UUID(self.value)
            # Normalize to lowercase string
            object.__setattr__(self, "value", str(parsed))
        except (ValueError, AttributeError):
            raise InvariantViolationError(f"Invalid UUID string format: {self.value}")

    @classmethod
    def new(cls) -> "EntityId":
        return cls(generate_uuidv7())

    def __str__(self) -> str:
        return self.value

@dataclass(frozen=True)
class WorkspaceId(EntityId):
    pass

@dataclass(frozen=True)
class UserId(EntityId):
    pass

@dataclass(frozen=True)
class InstallationId(EntityId):
    pass
