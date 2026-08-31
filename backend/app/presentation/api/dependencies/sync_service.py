"""
Sync Application Service — مشروع «مُعين» (Mouin)
Coordinates Sync Push, Idempotency Verification, Pull Streaming, and Snapshot Bootstrapping.
Supports PostgreSQL persistent storage with seamless memory fallback.
"""

import hashlib
import json
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
from backend.app.application.exceptions import IdempotencyConflictError
from backend.app.application.ports.repositories import IItemRepository, IDebtRepository
from backend.app.application.ports.unit_of_work import IUnitOfWork
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId

class SyncApplicationService:
    def __init__(
        self,
        item_repo: IItemRepository,
        debt_repo: IDebtRepository,
        uow: IUnitOfWork,
        sync_repo: Optional[Any] = None
    ):
        self.item_repo = item_repo
        self.debt_repo = debt_repo
        self.uow = uow
        self.sync_repo = sync_repo
        # In-memory replication stream simulation for server sync
        self._sync_changes: List[Dict[str, Any]] = []
        self._idempotency_store: Dict[str, str] = {}  # op_id -> payload_hash

    def handle_push(self, workspace_id: str, operations: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        ws_id = WorkspaceId(workspace_id)
        acks = []

        with self.uow:
            for op in operations:
                op_id = op['operation_id']
                payload_str = json.dumps(op.get('payload', {}), sort_keys=True)
                p_hash = hashlib.sha256(payload_str.encode('utf-8')).hexdigest()

                # Persistent PostgreSQL Idempotency Check
                if self.sync_repo is not None:
                    cached = self.sync_repo.check_idempotency(op_id)
                    if cached:
                        if cached.get("payload_hash_sha256") == p_hash:
                            acks.append({
                                "operation_id": op_id,
                                "status": "duplicate_idempotent",
                                "server_sequence": cached.get("server_sequence", 1),
                                "new_entity_version": op.get('base_version', 1)
                            })
                            continue
                        else:
                            raise IdempotencyConflictError(f"HTTP 409 Conflict: Operation ID {op_id} already used with a different payload.")

                # In-Memory Idempotency Gate
                if op_id in self._idempotency_store:
                    if self._idempotency_store[op_id] == p_hash:
                        # Idempotent return
                        acks.append({
                            "operation_id": op_id,
                            "status": "duplicate_idempotent",
                            "server_sequence": len(self._sync_changes),
                            "new_entity_version": op.get('base_version', 1)
                        })
                        continue
                    else:
                        raise IdempotencyConflictError(f"HTTP 409 Conflict: Operation ID {op_id} already used with a different payload.")

                # Record idempotency in memory
                self._idempotency_store[op_id] = p_hash

                new_ver = op.get('base_version', 1) + 1

                # If sync repository is present, record in PostgreSQL
                if self.sync_repo is not None:
                    new_seq = self.sync_repo.record_sync_change(
                        workspace_id=ws_id,
                        entity_type=op['entity_type'],
                        entity_id=EntityId(op['entity_id']),
                        change_type=op['operation_type'],
                        payload=op.get('payload', {}),
                        entity_version=new_ver
                    )
                    self.sync_repo.record_idempotency(op_id, p_hash, new_seq)
                else:
                    new_seq = len(self._sync_changes) + 1

                # Record sync change
                change_record = {
                    "server_sequence": new_seq,
                    "workspace_id": workspace_id,
                    "entity_type": op['entity_type'],
                    "entity_id": op['entity_id'],
                    "change_type": op['operation_type'],
                    "payload": op.get('payload', {}),
                    "entity_version": new_ver,
                    "committed_at": datetime.now(timezone.utc).isoformat()
                }
                self._sync_changes.append(change_record)

                acks.append({
                    "operation_id": op_id,
                    "status": "success",
                    "server_sequence": new_seq,
                    "new_entity_version": new_ver
                })

            self.uow.commit()

        return acks

    def handle_pull(self, workspace_id: str, since_sequence: int = 0, limit: int = 50) -> Dict[str, Any]:
        ws_id = WorkspaceId(workspace_id)
        if self.sync_repo is not None:
            changes = self.sync_repo.fetch_stream_since(ws_id, since_sequence, limit)
            max_seq = self.sync_repo.get_current_max_sequence(ws_id)
            next_cursor = changes[-1]["server_sequence"] if changes else since_sequence
            has_more = next_cursor < max_seq
            return {
                "changes": changes,
                "has_more": has_more,
                "next_cursor": next_cursor
            }

        matched = [
            c for c in self._sync_changes
            if c['workspace_id'] == workspace_id and c['server_sequence'] > since_sequence
        ]
        subset = matched[:limit]
        has_more = len(matched) > limit
        next_cursor = subset[-1]['server_sequence'] if subset else since_sequence

        return {
            "changes": subset,
            "has_more": has_more,
            "next_cursor": next_cursor
        }

    def handle_bootstrap(self, workspace_id: str) -> Dict[str, Any]:
        ws_id = WorkspaceId(workspace_id)
        items = self.item_repo.list_by_workspace(ws_id)
        
        if self.sync_repo is not None:
            current_cursor = self.sync_repo.get_current_max_sequence(ws_id)
        else:
            current_cursor = len(self._sync_changes)

        return {
            "items": items,
            "initial_cursor": current_cursor,
            "snapshot_at": datetime.now(timezone.utc).isoformat()
        }
