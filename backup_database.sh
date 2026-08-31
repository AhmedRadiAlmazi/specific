#!/bin/bash
# ==============================================================================
# Mouin (مُعين) — Production Automated PostgreSQL Backup Script
# ==============================================================================

set -eo pipefail

BACKUP_DIR="${BACKUP_STORAGE_PATH:-/var/backups/mouin}"
TIMESTAMP=$(date -u +%Y%m%d_%H%M%SZ)
BACKUP_FILE="${BACKUP_DIR}/mouin_db_backup_${TIMESTAMP}.sql.gz"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

mkdir -p "${BACKUP_DIR}"

echo "[$(date -u)] Starting database backup..."
pg_dump "${DATABASE_URL}" | gzip > "${BACKUP_FILE}"

echo "[$(date -u)] Backup successfully written to ${BACKUP_FILE}"
echo "[$(date -u)] Verifying backup integrity..."
gzip -t "${BACKUP_FILE}"

echo "[$(date -u)] Purging backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -type f -name "mouin_db_backup_*.sql.gz" -mtime +"${RETENTION_DAYS}" -delete

echo "[$(date -u)] Backup procedure completed successfully."
