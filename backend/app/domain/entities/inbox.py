"""
Inbox & AI Suggestions Domain Model — مشروع «مُعين» (Mouin)
Strict isolation: AI Suggestion is Staging only, does not mutate domain directly.
"""

from dataclasses import dataclass, field
from datetime import datetime, timezone
from decimal import Decimal
from typing import Dict, Any, Optional
from backend.app.domain.entities.base import AggregateRoot, BaseEntity
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId, InstallationId, UserId
from backend.app.domain.value_objects.types import InboxSourceType, ProcessingStatus, AISuggestionValidationStatus
from backend.app.domain.exceptions import InvariantViolationError, InvalidStateTransitionError

@dataclass
class AISuggestion(BaseEntity):
    inbox_item_id: EntityId = field(default_factory=EntityId.new)
    intent: str = ""
    suggested_payload: Dict[str, Any] = field(default_factory=dict)
    confidence_score: Decimal = Decimal("1.000")
    validation_status: AISuggestionValidationStatus = AISuggestionValidationStatus.PENDING_REVIEW
    ai_schema_version: str = "1.0"
    model_name: str = "gemini-pro"
    model_version: str = "1.5"
    prompt_version: str = "1.0"
    reviewed_by_user_id: Optional[UserId] = None
    reviewed_at: Optional[datetime] = None

    def __post_init__(self):
        if not (Decimal("0.000") <= self.confidence_score <= Decimal("1.000")):
            raise InvariantViolationError("Confidence score must be between 0.0 and 1.0.")

    def accept(self, user_id: UserId):
        self.validation_status = AISuggestionValidationStatus.ACCEPTED
        self.reviewed_by_user_id = user_id
        self.reviewed_at = datetime.now(timezone.utc)
        self.touch()

    def reject(self, user_id: UserId):
        self.validation_status = AISuggestionValidationStatus.REJECTED
        self.reviewed_by_user_id = user_id
        self.reviewed_at = datetime.now(timezone.utc)
        self.touch()

@dataclass
class InboxItem(AggregateRoot):
    raw_text: str = ""
    source_type: InboxSourceType = InboxSourceType.MANUAL_QUICK_NOTE
    processing_status: ProcessingStatus = ProcessingStatus.PENDING
    created_by_installation_id: Optional[InstallationId] = None

    def __post_init__(self):
        if not self.raw_text or not self.raw_text.strip():
            raise InvariantViolationError("Inbox raw_text cannot be empty.")
