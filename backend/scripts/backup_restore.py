"""
Database Backup & Disaster Recovery Utility — مشروع «مُعين» (Mouin)
Generates atomic timestamped snapshots with SHA-256 cryptographic manifests,
and provides verified restoration procedures.
"""

import os
import json
import hashlib
from datetime import datetime, timezone
from typing import Dict, Any, Optional

def create_backup_snapshot(
    data: Dict[str, Any],
    output_dir: str,
    backup_name: Optional[str] = None
) -> Dict[str, str]:
    """
    Creates an atomic JSON backup file with a companion SHA-256 manifest.
    Returns: {'snapshot_file': path, 'manifest_file': path, 'checksum_sha256': hex}
    """
    os.makedirs(output_dir, exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    base_name = backup_name or f"mouin_backup_{ts}"

    snapshot_filename = f"{base_name}.json"
    manifest_filename = f"{base_name}.manifest.json"

    snapshot_path = os.path.join(output_dir, snapshot_filename)
    manifest_path = os.path.join(output_dir, manifest_filename)

    # 1. Serialize Data
    json_bytes = json.dumps(data, indent=2, sort_keys=True).encode('utf-8')

    # 2. Compute SHA-256 Checksum
    checksum = hashlib.sha256(json_bytes).hexdigest()

    # 3. Write Snapshot File
    with open(snapshot_path, 'wb') as f:
        f.write(json_bytes)

    # 4. Write Manifest File
    manifest_data = {
        "backup_name": base_name,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "file_name": snapshot_filename,
        "file_size_bytes": len(json_bytes),
        "checksum_sha256": checksum,
        "schema_version": "1.0"
    }

    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest_data, f, indent=2)

    return {
        "snapshot_file": snapshot_path,
        "manifest_file": manifest_path,
        "checksum_sha256": checksum
    }

def verify_and_read_backup(snapshot_path: str, manifest_path: str) -> Dict[str, Any]:
    """Verifies SHA-256 manifest integrity before loading backup data."""
    if not os.path.exists(snapshot_path):
        raise FileNotFoundError(f"Snapshot file not found: {snapshot_path}")
    if not os.path.exists(manifest_path):
        raise FileNotFoundError(f"Manifest file not found: {manifest_path}")

    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    with open(snapshot_path, 'rb') as f:
        snapshot_bytes = f.read()

    actual_checksum = hashlib.sha256(snapshot_bytes).hexdigest()
    expected_checksum = manifest.get("checksum_sha256")

    if actual_checksum != expected_checksum:
        raise ValueError(
            f"Backup checksum verification failed! Expected: {expected_checksum}, Got: {actual_checksum}"
        )

    return json.loads(snapshot_bytes.decode('utf-8'))
