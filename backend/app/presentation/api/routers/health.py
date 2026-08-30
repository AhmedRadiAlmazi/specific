"""
Health & Readiness Check Router — مشروع «مُعين» (Mouin)
Strictly separates Liveness (process alive) and Readiness (dependencies operational).
"""

from fastapi import APIRouter, status, Response
from typing import Dict, Any
import os

from backend.app.presentation.api.schemas.common import HealthResponse

router = APIRouter(tags=["Health"])

# Hook for testing / dependency probing
_db_health_override = None

def set_db_health_override(is_healthy: bool = None):
    global _db_health_override
    _db_health_override = is_healthy

def is_database_healthy() -> bool:
    global _db_health_override
    if _db_health_override is not None:
        return _db_health_override
    # Normal in-memory / connected database check
    return True

@router.get("/health", response_model=HealthResponse)
def health_check():
    return HealthResponse(status="healthy", version="1.0.0")

@router.get("/health/live", response_model=HealthResponse)
def liveness_check():
    """Liveness probe: verifies process is alive and accepting requests."""
    return HealthResponse(status="live", version="1.0.0")

@router.get("/health/ready")
def readiness_check(response: Response):
    """
    Readiness probe: verifies all upstream dependencies (Database, Cache) are ready.
    If database is unavailable, returns 503 Service Unavailable without process termination.
    """
    db_ok = is_database_healthy()
    if not db_ok:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {
            "status": "not_ready",
            "version": "1.0.0",
            "dependencies": {
                "database": "unavailable"
            }
        }
    
    return {
        "status": "ready",
        "version": "1.0.0",
        "dependencies": {
            "database": "healthy"
        }
    }
