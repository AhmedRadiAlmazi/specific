"""
Application Configuration Layer — مشروع «مُعين» (Mouin)
Includes strict Production Hardening, validation, and security boundaries.
"""

import os
from typing import List
from pydantic import BaseModel, Field

class ApiSettings(BaseModel):
    app_name: str = "مُعين (Mouin) API"
    app_version: str = "1.0.0"
    api_prefix: str = "/api/v1"
    environment: str = Field(default_factory=lambda: os.getenv("APP_ENV", "development"))
    database_url: str = Field(default_factory=lambda: os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/mouin_db"))
    jwt_secret_key: str = Field(default_factory=lambda: os.getenv("JWT_SECRET_KEY", "mouin-secret-key-dev-environment-only"))
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 60 * 24 * 7  # 7 days
    
    # Production Hardening & Limits
    allowed_origins: List[str] = Field(default_factory=lambda: [
        o.strip() for o in os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000,http://localhost:8080").split(",") if o.strip()
    ])
    max_request_body_bytes: int = 10 * 1024 * 1024  # 10 MB limit
    default_page_limit: int = 50
    max_page_limit: int = 100
    max_sync_batch_size: int = 100
    log_level: str = Field(default_factory=lambda: os.getenv("LOG_LEVEL", "INFO"))

    @property
    def is_production(self) -> bool:
        return self.environment.lower() in ("production", "prod")

    def validate_production(self) -> None:
        """Enforces zero-tolerance production safety checks."""
        if self.is_production:
            if "dev-environment" in self.jwt_secret_key or len(self.jwt_secret_key) < 32:
                raise ValueError("PRODUCTION SECURITY ERROR: JWT_SECRET_KEY must be a secure random secret of at least 32 characters in production.")
            if "*" in self.allowed_origins:
                raise ValueError("PRODUCTION SECURITY ERROR: Wildcard '*' is forbidden in ALLOWED_ORIGINS in production.")
            if "localhost" in self.database_url and not os.getenv("ALLOW_LOCALHOST_DB_IN_PROD"):
                raise ValueError("PRODUCTION SECURITY ERROR: Localhost database URLs are forbidden in production without explicit override.")

settings = ApiSettings()
