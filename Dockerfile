# ==============================================================================
# Mouin (مُعين) — Production Multi-Stage Dockerfile
# ==============================================================================

FROM python:3.12-slim AS builder

WORKDIR /app

# Install system build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Final minimal runtime image
FROM python:3.12-slim AS runner

WORKDIR /app

# Install runtime PostgreSQL client library
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder stage
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONPATH=/app

# Create non-root system user for security
RUN useradd -m -u 10001 mouin_user
USER mouin_user

# Copy application source code
COPY --chown=mouin_user:mouin_user backend /app/backend
COPY --chown=mouin_user:mouin_user migrations /app/migrations
COPY --chown=mouin_user:mouin_user alembic.ini /app/alembic.ini

EXPOSE 8000

# Health check probe
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health/live || exit 1

ENTRYPOINT ["uvicorn", "backend.app.presentation.api.app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
