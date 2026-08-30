"""
Common Standard HTTP DTOs & Error Contract — مشروع «مُعين» (Mouin)
"""

from pydantic import BaseModel, Field
from typing import List, Optional, Any
from datetime import datetime, timezone

class ErrorDetail(BaseModel):
    field: Optional[str] = None
    issue: str

class ErrorBody(BaseModel):
    code: str
    message: str
    category: str
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    details: List[ErrorDetail] = Field(default_factory=list)

class ErrorResponse(BaseModel):
    error: ErrorBody

class HealthResponse(BaseModel):
    status: str = "healthy"
    version: str = "1.0.0"
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

class PaginationMeta(BaseModel):
    limit: int
    offset: int
    count: int
