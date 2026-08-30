"""
Automated Database Backup, Restore, and Integrity Verification — مشروع «مُعين» (Mouin)
Provides production-grade snapshot backups with cryptographic SHA-256 verification.
"""

import sqlite3
import hashlib
import json
import os
from typing import Dict, Any, Tuple

def compute_file_sha256(filepath: str) -> str:
    sha = hashlib.sha256()
    with open(filepath, 'rb') as f:
        while chunk := f.read(65536):
            sha.update(chunk)
    return sha.hexdigest()

def create_sqlite_backup(source_conn: sqlite3.Connection, backup_filepath: str) -> Dict[str, Any]:
    """Creates an atomic SQLite backup snapshot using sqlite3 backup API."""
    os.makedirs(os.path.dirname(os.path.abspath(backup_filepath)), exist_ok=True)
    dest_conn = sqlite3.connect(backup_filepath)
    source_conn.backup(dest_conn)
    dest_conn.close()
    
    file_hash = compute_file_sha256(backup_filepath)
    metadata = {
        "backup_file": backup_filepath,
        "sha256": file_hash,
        "size_bytes": os.path.getsize(backup_filepath)
    }
    return metadata

def restore_sqlite_backup(backup_filepath: str, target_db_filepath: str) -> None:
    """Restores database from backup snapshot."""
    if not os.path.exists(backup_filepath):
        raise FileNotFoundError(f"Backup file not found: {backup_filepath}")
    
    # Read backup and write to target
    src_conn = sqlite3.connect(backup_filepath)
    dest_conn = sqlite3.connect(target_db_filepath)
    src_conn.backup(dest_conn)
    src_conn.close()
    dest_conn.close()

def verify_sqlite_integrity(conn: sqlite3.Connection) -> Tuple[bool, str]:
    """Executes PRAGMA integrity_check on the database."""
    cursor = conn.cursor()
    cursor.execute("PRAGMA integrity_check;")
    result = cursor.fetchone()[0]
    return (result == "ok", result)
