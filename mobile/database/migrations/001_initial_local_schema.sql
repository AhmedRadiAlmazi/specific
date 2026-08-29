-- =============================================================================
-- SQLite Local Schema Implementation v1.0 — مشروع «مُعين» (Mouin)
-- Strictly derived from DATA_API_SYNC_CONTRACT v1.0 FINAL & ERD_FINAL v1.0
-- Compatible with Flutter Local Persistence (Drift / sqflite)
-- =============================================================================

PRAGMA foreign_keys = ON;

-- -----------------------------------------------------------------------------
-- 1. Client Session & Sync Infrastructure
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS local_session (
    key TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    device_id TEXT NOT NULL,
    installation_id TEXT NOT NULL,
    active_workspace_id TEXT NOT NULL,
    auth_token_exp TEXT NULL
);

CREATE TABLE IF NOT EXISTS local_sync_state (
    workspace_id TEXT PRIMARY KEY,
    last_synced_server_sequence INTEGER NOT NULL DEFAULT 0,
    last_synced_at TEXT NULL,
    sync_status TEXT NOT NULL DEFAULT 'idle' CHECK (sync_status IN ('idle', 'syncing', 'error', 'requires_bootstrap')),
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS outbox (
    operation_id TEXT PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('insert', 'update', 'delete')),
    payload TEXT NOT NULL,
    base_version INTEGER NOT NULL,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_flight', 'failed')),
    last_error TEXT NULL,
    next_retry_at TEXT NULL,
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_outbox_queue ON outbox(status, created_at);

CREATE TABLE IF NOT EXISTS local_sync_conflicts (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    client_version INTEGER NOT NULL,
    server_version INTEGER NOT NULL,
    client_payload TEXT NOT NULL,
    server_payload TEXT NOT NULL,
    resolution_strategy TEXT NOT NULL,
    resolved_payload TEXT NULL,
    resolved_at TEXT NULL,
    created_at TEXT NOT NULL
);

-- -----------------------------------------------------------------------------
-- 2. Local Domain Master Data
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS local_categories (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    name TEXT NOT NULL,
    color TEXT NOT NULL DEFAULT '#6750A4',
    icon TEXT NOT NULL DEFAULT 'folder',
    parent_id TEXT NULL REFERENCES local_categories(id) ON DELETE SET NULL,
    entity_version INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_local_categories_ws ON local_categories(workspace_id);

CREATE TABLE IF NOT EXISTS local_people (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT NULL,
    email TEXT NULL,
    relationship_type TEXT NULL,
    notes TEXT NULL,
    entity_version INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_local_people_ws ON local_people(workspace_id);

-- -----------------------------------------------------------------------------
-- 3. Local Item Aggregate Root & Subtypes
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS local_items (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    item_type TEXT NOT NULL CHECK (item_type IN ('task', 'appointment', 'note', 'document', 'debt', 'shopping')),
    title TEXT NOT NULL,
    summary TEXT NULL,
    category_id TEXT NULL REFERENCES local_categories(id) ON DELETE SET NULL,
    privacy_classification TEXT NOT NULL DEFAULT 'private' CHECK (privacy_classification IN ('private', 'sensitive')),
    temporal_original_expression TEXT NULL,
    temporal_resolved_at TEXT NULL,
    temporal_timezone TEXT NULL,
    temporal_locale TEXT NULL DEFAULT 'ar',
    temporal_calendar TEXT NULL DEFAULT 'gregorian',
    created_by_installation_id TEXT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT NULL,
    entity_version INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_local_items_ws_type ON local_items(workspace_id, item_type);
CREATE INDEX IF NOT EXISTS idx_local_items_created ON local_items(workspace_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_local_items_deleted ON local_items(deleted_at);

CREATE TABLE IF NOT EXISTS local_tasks (
    item_id TEXT PRIMARY KEY REFERENCES local_items(id) ON DELETE CASCADE,
    due_date TEXT NULL,
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    completed_at TEXT NULL,
    estimated_duration_minutes INTEGER NULL CHECK (estimated_duration_minutes IS NULL OR estimated_duration_minutes > 0)
);

CREATE INDEX IF NOT EXISTS idx_local_tasks_status_due ON local_tasks(status, due_date);

CREATE TABLE IF NOT EXISTS local_appointments (
    item_id TEXT PRIMARY KEY REFERENCES local_items(id) ON DELETE CASCADE,
    start_time TEXT NOT NULL,
    end_time TEXT NULL,
    location TEXT NULL,
    all_day INTEGER NOT NULL DEFAULT 0 CHECK (all_day IN (0, 1)),
    timezone TEXT NOT NULL DEFAULT 'Asia/Aden'
);

CREATE INDEX IF NOT EXISTS idx_local_appointments_start ON local_appointments(start_time);

CREATE TABLE IF NOT EXISTS local_notes (
    item_id TEXT PRIMARY KEY REFERENCES local_items(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    content_format TEXT NOT NULL DEFAULT 'plain_text' CHECK (content_format IN ('plain_text', 'markdown'))
);

CREATE TABLE IF NOT EXISTS local_documents (
    item_id TEXT PRIMARY KEY REFERENCES local_items(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    issue_date TEXT NULL,
    expiry_date TEXT NULL,
    document_number TEXT NULL,
    issuing_authority TEXT NULL
);

CREATE TABLE IF NOT EXISTS local_debts (
    item_id TEXT PRIMARY KEY REFERENCES local_items(id) ON DELETE CASCADE,
    debt_type TEXT NOT NULL CHECK (debt_type IN ('payable', 'receivable')),
    person_id TEXT NOT NULL REFERENCES local_people(id) ON DELETE RESTRICT,
    total_amount TEXT NOT NULL,
    currency TEXT NOT NULL DEFAULT 'YER',
    due_date TEXT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'settled', 'defaulted', 'cancelled'))
);

CREATE TABLE IF NOT EXISTS local_debt_transactions (
    id TEXT PRIMARY KEY,
    debt_id TEXT NOT NULL REFERENCES local_debts(item_id) ON DELETE CASCADE,
    workspace_id TEXT NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('payment', 'reversal', 'adjustment')),
    amount TEXT NOT NULL,
    transaction_date TEXT NOT NULL,
    notes TEXT NULL,
    reference_transaction_id TEXT NULL REFERENCES local_debt_transactions(id) ON DELETE RESTRICT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT NULL,
    entity_version INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_local_debt_tx_debt ON local_debt_transactions(debt_id);

CREATE TABLE IF NOT EXISTS local_shopping_lists (
    item_id TEXT PRIMARY KEY REFERENCES local_items(id) ON DELETE CASCADE,
    is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1))
);

CREATE TABLE IF NOT EXISTS local_shopping_entries (
    id TEXT PRIMARY KEY,
    shopping_list_id TEXT NOT NULL REFERENCES local_shopping_lists(item_id) ON DELETE CASCADE,
    workspace_id TEXT NOT NULL,
    item_name TEXT NOT NULL,
    quantity TEXT NOT NULL DEFAULT '1.00',
    unit TEXT NULL,
    is_checked INTEGER NOT NULL DEFAULT 0 CHECK (is_checked IN (0, 1)),
    checked_at TEXT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT NULL,
    entity_version INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_local_shopping_entries_list ON local_shopping_entries(shopping_list_id, is_checked, sort_order);

-- -----------------------------------------------------------------------------
-- 4. Local Reminders & Notifications
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS local_reminder_rules (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    item_id TEXT NOT NULL REFERENCES local_items(id) ON DELETE CASCADE,
    trigger_type TEXT NOT NULL CHECK (trigger_type IN ('relative', 'absolute', 'recurring')),
    trigger_time TEXT NULL,
    offset_minutes INTEGER NULL,
    rrule TEXT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT NULL,
    entity_version INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_local_reminder_rules_item ON local_reminder_rules(item_id);

CREATE TABLE IF NOT EXISTS local_reminder_instances (
    id TEXT PRIMARY KEY,
    rule_id TEXT NOT NULL REFERENCES local_reminder_rules(id) ON DELETE CASCADE,
    item_id TEXT NOT NULL REFERENCES local_items(id) ON DELETE CASCADE,
    workspace_id TEXT NOT NULL,
    occurrence_key TEXT NOT NULL,
    scheduled_time TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'triggered', 'snoozed', 'dismissed', 'cancelled')),
    snoozed_until TEXT NULL,
    fired_at TEXT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    entity_version INTEGER NOT NULL DEFAULT 1,
    UNIQUE(rule_id, occurrence_key)
);

CREATE INDEX IF NOT EXISTS idx_local_reminder_inst_sched ON local_reminder_instances(status, scheduled_time);

CREATE TABLE IF NOT EXISTS local_notifications (
    id TEXT PRIMARY KEY,
    instance_id TEXT NOT NULL REFERENCES local_reminder_instances(id) ON DELETE CASCADE,
    installation_id TEXT NOT NULL,
    workspace_id TEXT NOT NULL,
    delivery_channel TEXT NOT NULL DEFAULT 'local_push' CHECK (delivery_channel IN ('local_push', 'system_tray')),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    scheduled_for TEXT NOT NULL,
    sent_at TEXT NULL,
    delivery_status TEXT NOT NULL DEFAULT 'scheduled' CHECK (delivery_status IN ('scheduled', 'delivered', 'failed', 'dismissed')),
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS local_notification_actions (
    id TEXT PRIMARY KEY,
    notification_id TEXT NOT NULL REFERENCES local_notifications(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL CHECK (action_type IN ('dismiss', 'snooze_5m', 'snooze_15m', 'snooze_1h', 'mark_done', 'view_item')),
    acted_at TEXT NOT NULL,
    payload TEXT NULL
);

-- -----------------------------------------------------------------------------
-- 5. Local Attachments
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS local_attachments (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size_bytes INTEGER NOT NULL CHECK (file_size_bytes >= 0),
    mime_type TEXT NOT NULL,
    local_file_path TEXT NULL,
    remote_storage_path TEXT NULL,
    checksum_sha256 TEXT NOT NULL,
    privacy_classification TEXT NOT NULL DEFAULT 'private' CHECK (privacy_classification IN ('private', 'sensitive')),
    upload_status TEXT NOT NULL DEFAULT 'synced' CHECK (upload_status IN ('pending_upload', 'synced', 'error')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT NULL,
    entity_version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS local_item_attachments (
    item_id TEXT NOT NULL REFERENCES local_items(id) ON DELETE CASCADE,
    attachment_id TEXT NOT NULL REFERENCES local_attachments(id) ON DELETE CASCADE,
    caption TEXT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    PRIMARY KEY (item_id, attachment_id)
);

CREATE TABLE IF NOT EXISTS local_debt_transaction_attachments (
    transaction_id TEXT NOT NULL REFERENCES local_debt_transactions(id) ON DELETE CASCADE,
    attachment_id TEXT NOT NULL REFERENCES local_attachments(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    PRIMARY KEY (transaction_id, attachment_id)
);

-- -----------------------------------------------------------------------------
-- 6. Local Inbox & AI Suggestions
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS local_inbox_items (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    raw_text TEXT NOT NULL,
    source_type TEXT NOT NULL CHECK (source_type IN ('voice_transcription', 'manual_quick_note', 'share_intent', 'image_scan')),
    processing_status TEXT NOT NULL DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'processed', 'rejected', 'error')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT NULL,
    entity_version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS local_inbox_attachments (
    inbox_item_id TEXT NOT NULL REFERENCES local_inbox_items(id) ON DELETE CASCADE,
    attachment_id TEXT NOT NULL REFERENCES local_attachments(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    PRIMARY KEY (inbox_item_id, attachment_id)
);

CREATE TABLE IF NOT EXISTS local_ai_suggestions (
    id TEXT PRIMARY KEY,
    inbox_item_id TEXT NOT NULL REFERENCES local_inbox_items(id) ON DELETE CASCADE,
    workspace_id TEXT NOT NULL,
    intent TEXT NOT NULL,
    suggested_payload TEXT NOT NULL,
    confidence_score TEXT NOT NULL,
    validation_status TEXT NOT NULL DEFAULT 'pending_review' CHECK (validation_status IN ('pending_review', 'accepted', 'rejected', 'edited')),
    ai_schema_version TEXT NOT NULL DEFAULT '1.0',
    model_name TEXT NOT NULL,
    model_version TEXT NOT NULL,
    prompt_version TEXT NOT NULL,
    reviewed_at TEXT NULL,
    created_at TEXT NOT NULL
);

-- -----------------------------------------------------------------------------
-- 7. Full Text Search (FTS5) for Arabic Search
-- -----------------------------------------------------------------------------

CREATE VIRTUAL TABLE IF NOT EXISTS items_fts USING fts5(
    title,
    summary,
    temporal_original_expression,
    content='local_items',
    content_rowid='rowid'
);

-- Triggers for FTS synchronization
CREATE TRIGGER IF NOT EXISTS trg_items_fts_insert AFTER INSERT ON local_items BEGIN
    INSERT INTO items_fts(rowid, title, summary, temporal_original_expression)
    VALUES (new.rowid, new.title, coalesce(new.summary, ''), coalesce(new.temporal_original_expression, ''));
END;

CREATE TRIGGER IF NOT EXISTS trg_items_fts_delete AFTER DELETE ON local_items BEGIN
    INSERT INTO items_fts(items_fts, rowid, title, summary, temporal_original_expression)
    VALUES ('delete', old.rowid, old.title, coalesce(old.summary, ''), coalesce(old.temporal_original_expression, ''));
END;

CREATE TRIGGER IF NOT EXISTS trg_items_fts_update AFTER UPDATE ON local_items BEGIN
    INSERT INTO items_fts(items_fts, rowid, title, summary, temporal_original_expression)
    VALUES ('delete', old.rowid, old.title, coalesce(old.summary, ''), coalesce(old.temporal_original_expression, ''));
    INSERT INTO items_fts(rowid, title, summary, temporal_original_expression)
    VALUES (new.rowid, new.title, coalesce(new.summary, ''), coalesce(new.temporal_original_expression, ''));
END;
