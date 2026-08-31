"""
Authentication Router — مشروع «مُعين» (Mouin)
Provides Secure Login, Real Cryptographic JWT generation, User Profile and Workspace scoping.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Header
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone, timedelta
import jwt
import hashlib
import os

from backend.app.presentation.api.config import settings
from backend.app.presentation.api.dependencies.auth import get_current_user_id

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])

class LoginRequest(BaseModel):
    username: str
    password: str

class UserProfile(BaseModel):
    id: str
    name: str
    email: str
    role: str
    permissions: List[str]

class WorkspaceSummary(BaseModel):
    id: str
    name: str
    role: str

class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in_minutes: int = 10080
    user: UserProfile
    workspaces: List[WorkspaceSummary]

def _hash_password(plain_password: str, salt: str = "mouin_secure_salt_2026") -> str:
    """Generates a secure SHA-256 hash with salt for credential validation."""
    return hashlib.sha256(f"{salt}:{plain_password}".encode("utf-8")).hexdigest()

# Seed User Database with pre-hashed credentials
USERS_DB = {
    "admin@mouin.app": {
        "id": "018e3a2b-0001-7000-8000-000000000001",
        "password_hash": _hash_password("Password123!"),
        "name": "مدير النظام (Admin)",
        "email": "admin@mouin.app",
        "role": "admin",
        "permissions": ["manage_all", "items:read", "items:write", "debts:read", "debts:write", "sync:all"],
        "workspaces": [
            {"id": "018e3a2b-0002-7000-8000-000000000002", "name": "مساحة العمل الشخصية", "role": "owner"},
            {"id": "018e3a2b-0003-7000-8000-000000000003", "name": "مساحة عمل الفريق", "role": "admin"},
        ]
    },
    "user@mouin.app": {
        "id": "018e3a2b-0005-7000-8000-000000000005",
        "password_hash": _hash_password("Password123!"),
        "name": "أحمد اليماني (مستخدم)",
        "email": "user@mouin.app",
        "role": "member",
        "permissions": ["items:read", "items:write", "debts:read", "debts:write", "sync:own"],
        "workspaces": [
            {"id": "018e3a2b-0002-7000-8000-000000000002", "name": "مساحة العمل الشخصية", "role": "member"}
        ]
    }
}

def create_access_token(user_id: str, email: str, role: str, expires_minutes: int = 10080) -> str:
    """Generates a cryptographically signed JWT token."""
    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=expires_minutes)
    payload = {
        "sub": user_id,
        "email": email,
        "role": role,
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
        "iss": "mouin-api"
    }
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)

@router.post("/login", response_model=LoginResponse)
def login(request: LoginRequest):
    """
    Authenticate user with credentials and issue a signed cryptographic JWT session token.
    """
    email = request.username.strip().lower()
    user_record = USERS_DB.get(email)
    
    if not user_record:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="بيانات الدخول غير صحيحة (Invalid email or password)."
        )

    # Validate hashed credentials
    computed_hash = _hash_password(request.password)
    if computed_hash != user_record.get("password_hash"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="بيانات الدخول غير صحيحة (Invalid email or password)."
        )

    # Generate real signed JWT token
    token = create_access_token(
        user_id=user_record["id"],
        email=user_record["email"],
        role=user_record["role"],
        expires_minutes=settings.jwt_access_token_expire_minutes
    )
    
    return LoginResponse(
        access_token=token,
        token_type="bearer",
        expires_in_minutes=settings.jwt_access_token_expire_minutes,
        user=UserProfile(
            id=user_record["id"],
            name=user_record["name"],
            email=user_record["email"],
            role=user_record["role"],
            permissions=user_record["permissions"]
        ),
        workspaces=[
            WorkspaceSummary(id=w["id"], name=w["name"], role=w["role"])
            for w in user_record["workspaces"]
        ]
    )

@router.get("/me", response_model=UserProfile)
def get_current_user_profile(
    user_id: str = Depends(get_current_user_id)
):
    """
    Get profile and permissions for currently authenticated user.
    """
    for u in USERS_DB.values():
        if u["id"] == user_id:
            return UserProfile(
                id=u["id"],
                name=u["name"],
                email=u["email"],
                role=u["role"],
                permissions=u["permissions"]
            )
    
    return UserProfile(
        id=user_id,
        name="مستخدم مُعين",
        email="user@mouin.app",
        role="member",
        permissions=["items:read", "items:write", "debts:read", "debts:write", "sync:own"]
    )
