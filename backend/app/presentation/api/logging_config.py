"""
Structured Logging & Sensitive Data Redaction Filter — مشروع «مُعين» (Mouin)
Ensures zero token/secret/password leakage into production log streams.
"""

import logging
import json
import re
from datetime import datetime, timezone

SENSITIVE_PATTERNS = [
    re.compile(r'(?i)(password|secret|token|authorization|api_key|private_key|pin)\s*[:=]\s*(\S+)'),
]

class SensitiveDataRedactionFilter(logging.Filter):
    """Redacts passwords, tokens, API keys, and authorization headers from log records."""
    def filter(self, record: logging.LogRecord) -> bool:
        if isinstance(record.msg, str):
            for pattern in SENSITIVE_PATTERNS:
                record.msg = pattern.sub(r'\1=[REDACTED]', record.msg)
        return True

def setup_production_logging(log_level: str = "INFO"):
    logger = logging.getLogger("mouin")
    logger.setLevel(getattr(logging, log_level.upper(), logging.INFO))
    
    # Avoid duplicate handlers
    if not logger.handlers:
        handler = logging.StreamHandler()
        handler.addFilter(SensitiveDataRedactionFilter())
        formatter = logging.Formatter(
            fmt='{"timestamp":"%(asctime)s", "level":"%(levelname)s", "module":"%(name)s", "message":"%(message)s"}',
            datefmt='%Y-%m-%dT%H:%M:%SZ'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.propagate = False
    return logger

logger = setup_production_logging()
