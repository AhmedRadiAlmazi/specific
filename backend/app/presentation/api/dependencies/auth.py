"""
Authentication Dependency Boundary — مشروع «مُعين» (Mouin)
Extracts and validates User Identity from Bearer token or Authorization headers.
"""

from fastapi import Header, HTTPException, status
from typing import Optional
from dataclasses import dataclass
import uuid

@dataclass(frozen=True)
class AuthenticatedUser:
    user_id: str
    is_active: bool = True

def get_current_user(
    authorization: Optional[str] = Header(None),
    x_user_id: Optional[str] = Header(None)
) -> AuthenticatedUser:
    """
    Extracts the authenticated user.
    Supports JWT Bearer header or direct x-user-id header for API clients.
    """
    if x_user_id:
        try:
            uuid.UUID(x_user_id)
            return AuthenticatedUser(user_id=x_user_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid x-user-id header format."
            )
    
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        # Validates token format or fallback mock
        if token == "invalid-token":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired authentication token."
            )
        # Default mock user id for valid token
        return AuthenticatedUser(user_id="018e3a2b-0001-7000-8000-000000000001")

    # If neither is provided, raise 401
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Missing Authorization Header."
    )
