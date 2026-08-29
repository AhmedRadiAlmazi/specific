"""
Attachment Domain Models — مشروع «مُعين» (Mouin)
Explicit Associations without loose polymorphic Foreign Keys.
"""

from dataclasses import dataclass
from typing import Optional
from backend.app.domain.entities.base import AggregateRoot, BaseEntity
from backend.app.domain.value_objects.identity import EntityId, UserId
from backend.app.domain.value_objects.types import PrivacyClassification
from backend.app.domain.exceptions import InvariantViolationError

@dataclass
class Attachment(AggregateRoot):
    file_name: str = ""
    file_size_bytes: int = 0
    mime_type: str = ""
    storage_path: str = ""
    checksum_sha256: str = ""
    privacy_classification: PrivacyClassification = PrivacyClassification.PRIVATE
    created_by_user_id: Optional[UserId] = None

    def __post_init__(self):
        if not self.file_name:
            raise InvariantViolationError("Attachment file_name is required.")
        if self.file_size_bytes < 0:
            raise InvariantViolationError("Attachment file_size_bytes cannot be negative.")
        if not self.checksum_sha256:
            raise InvariantViolationError("Attachment checksum_sha256 is required.")

@dataclass
class ItemAttachment(BaseEntity):
    item_id: EntityId = None
    attachment_id: EntityId = None
    caption: Optional[str] = None
    display_order: int = 0

@dataclass
class DebtTransactionAttachment(BaseEntity):
    transaction_id: EntityId = None
    attachment_id: EntityId = None
