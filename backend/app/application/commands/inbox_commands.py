"""
Inbox Application Commands — مشروع «مُعين» (Mouin)
"""

from dataclasses import dataclass
from typing import Optional

@dataclass(frozen=True)
class CreateInboxItemCommand:
    workspace_id: str
    raw_text: str
    source_type: str = "manual_quick_note"
    inbox_id: Optional[str] = None
    installation_id: Optional[str] = None

@dataclass(frozen=True)
class ConfirmAISuggestionCommand:
    workspace_id: str
    suggestion_id: str
    user_id: str
    accepted: bool
