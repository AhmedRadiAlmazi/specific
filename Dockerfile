# =============================================================================
# Production Multi-Stage Dockerfile — مشروع «مُعين» (Mouin)
# Non-root secure execution, minimal attack surface
# =============================================================================

FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.12-slim AS runtime

WORKDIR /app

# Security: Create non-root user
RUN addgroup --system mouingroup && adduser --system --group mouinuser

# Copy installed dependencies from builder
COPY --from=builder /root/.local /home/mouinuser/.local
ENV PATH=/home/mouinuser/.local/bin:$PATH

# Copy application source code
COPY backend /app/backend

# Switch to non-root user
USER mouinuser

EXPOSE 8000

ENV APP_ENV=production
ENV PYTHONUNBUFFERED=1

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/ready')" || exit 1

CMD ["uvicorn", "backend.app.presentation.api.app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
