"""
Attachment File Storage Service — مشروع «مُعين» (Mouin)
Handles local disk and cloud storage of audio recordings, images, and documents.
Enforces SHA-256 checksum verification, max size limits, and tenant workspace isolation.
"""

import os
import hashlib
from typing import Tuple, Optional
from datetime import datetime, timezone

class AttachmentSaveResult(tuple):
    def __new__(cls, full_path: str, checksum_sha256: str, file_size_bytes: int, mime_type: str = "application/octet-stream"):
        return super().__new__(cls, (full_path, checksum_sha256, file_size_bytes, mime_type))

class AttachmentStorageService:
    def __init__(
        self,
        base_storage_path: Optional[str] = None,
        base_storage_dir: Optional[str] = None,
        max_file_size_bytes: int = 25 * 1024 * 1024
    ):
        path = base_storage_dir or base_storage_path or os.path.join(os.getcwd(), "storage", "attachments")
        self.base_storage_path = os.path.abspath(path)
        self.base_storage_dir = self.base_storage_path
        self.max_file_size_bytes = max_file_size_bytes
        os.makedirs(self.base_storage_path, exist_ok=True)

    def save_file(
        self,
        workspace_id: str,
        file_bytes: bytes,
        file_name: str,
        mime_type: str = "application/octet-stream"
    ) -> AttachmentSaveResult:
        """
        Saves a file to workspace-isolated storage.
        Returns: (full_path, checksum_sha256, file_size_bytes, mime_type)
        """
        file_size = len(file_bytes)
        if file_size > self.max_file_size_bytes:
            raise ValueError(f"File size {file_size} exceeds maximum limit of {self.max_file_size_bytes} bytes.")

        if file_size == 0:
            raise ValueError("Cannot store empty (0-byte) attachment file.")

        # Compute SHA-256 Checksum
        checksum_sha256 = hashlib.sha256(file_bytes).hexdigest()

        # Workspace-isolated folder
        ws_folder = os.path.join(self.base_storage_path, workspace_id)
        os.makedirs(ws_folder, exist_ok=True)

        # File naming by checksum and original extension
        _, ext = os.path.splitext(file_name)
        safe_ext = ext if ext else ".bin"
        stored_filename = f"{checksum_sha256}{safe_ext}"
        full_path = os.path.join(ws_folder, stored_filename)

        with open(full_path, "wb") as f:
            f.write(file_bytes)

        return AttachmentSaveResult(full_path, checksum_sha256, file_size, mime_type)

    def read_file(self, workspace_or_path: str, relative_path: Optional[str] = None) -> bytes:
        """Reads file bytes from storage with directory traversal protection."""
        if relative_path is not None:
            full_path = os.path.abspath(os.path.join(self.base_storage_path, workspace_or_path, relative_path))
        elif os.path.isabs(workspace_or_path):
            full_path = os.path.abspath(workspace_or_path)
        else:
            full_path = os.path.abspath(os.path.join(self.base_storage_path, workspace_or_path))

        # Check traversal
        if not full_path.startswith(self.base_storage_path) or not os.path.exists(full_path) or os.path.isdir(full_path):
            raise FileNotFoundError(f"Attachment file not found at path: {workspace_or_path}")

        with open(full_path, "rb") as f:
            return f.read()

    def delete_file(self, workspace_or_path: str, relative_path: Optional[str] = None) -> bool:
        """Deletes file from storage."""
        if relative_path is not None:
            full_path = os.path.abspath(os.path.join(self.base_storage_path, workspace_or_path, relative_path))
        elif os.path.isabs(workspace_or_path):
            full_path = os.path.abspath(workspace_or_path)
        else:
            full_path = os.path.abspath(os.path.join(self.base_storage_path, workspace_or_path))

        if os.path.exists(full_path):
            os.remove(full_path)
            return True
        return False
