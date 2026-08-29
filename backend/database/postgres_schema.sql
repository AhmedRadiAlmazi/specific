-- =============================================================================
-- PostgreSQL Schema Implementation v1.0 — مشروع «مُعين» (Mouin)
-- Strictly derived from DATA_API_SYNC_CONTRACT v1.0 FINAL & ERD_FINAL v1.0
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. Identity & Organization
-- -----------------------------------------------------------------------------

CREATE TABLE users (
    id UUID NOT NULL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(32) NULL UNIQUE,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(128) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone_number) WHERE phone_number IS NOT NULL;
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NOT NULL;

CREATE TABLE devices (
    id UUID NOT NULL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_fingerprint VARCHAR(128) NOT NULL,
    device_name VARCHAR(128) NOT NULL,
    device_type VARCHAR(32) NOT NULL CHECK (device_type IN ('android', 'ios', 'windows', 'macos', 'web')),
    os_version VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_devices_user_fingerprint UNIQUE (user_id, device_fingerprint)
);

CREATE INDEX idx_devices_user_id ON devices(user_id);

CREATE TABLE installations (
    id UUID NOT NULL PRIMARY KEY,
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    app_version VARCHAR(32) NOT NULL,
    push_token TEXT NULL,
    sync_protocol_version INT NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    installed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_installations_device_id ON installations(device_id);
CREATE INDEX idx_installations_user_id ON installations(user_id);

CREATE TABLE workspaces (
    id UUID NOT NULL PRIMARY KEY,
    owner_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    name VARCHAR(128) NOT NULL,
    type VARCHAR(32) NOT NULL DEFAULT 'personal' CHECK (type IN ('personal', 'family', 'team')),
    settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    entity_version INT NOT NULL DEFAULT 1
);

CREATE INDEX idx_workspaces_owner ON workspaces(owner_user_id);
CREATE INDEX idx_workspaces_deleted_at ON workspaces(deleted_at) WHERE deleted_at IS NOT NULL;

CREATE TABLE workspace_members (
    id UUID NOT NULL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(32) NOT NULL DEFAULT 'owner' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    CONSTRAINT uq_workspace_members_ws_user UNIQUE (workspace_id, user_id)
);

CREATE INDEX idx_workspace_members_lookup ON workspace_members(workspace_id, user_id);

-- -----------------------------------------------------------------------------
-- 2. Master Data
-- -----------------------------------------------------------------------------

CREATE TABLE categories (
    id UUID NOT NULL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(64) NOT NULL,
    color VARCHAR(16) NOT NULL DEFAULT '#6750A4',
    icon VARCHAR(64) NOT NULL DEFAULT 'folder',
    parent_id UUID NULL REFERENCES categories(id) ON DELETE SET NULL,
    entity_version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL
);

CREATE INDEX idx_categories_workspace ON categories(workspace_id);
CREATE INDEX idx_categories_parent ON categories(parent_id);

CREATE TABLE people (
    id UUID NOT NULL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    phone VARCHAR(32) NULL,
    email VARCHAR(255) NULL,
    relationship_type VARCHAR(64) NULL,
    notes TEXT NULL,
    entity_version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL
);

CREATE INDEX idx_people_workspace ON people(workspace_id);
CREATE INDEX idx_people_name ON people(workspace_id, name);

-- -----------------------------------------------------------------------------
-- 3. Item Aggregate Root & Subtypes
-- -----------------------------------------------------------------------------

CREATE TABLE items (
    id UUID NOT NULL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    item_type VARCHAR(32) NOT NULL CHECK (item_type IN ('task', 'appointment', 'note', 'document', 'debt', 'shopping')),
    title VARCHAR(255) NOT NULL,
    summary TEXT NULL,
    category_id UUID NULL REFERENCES categories(id) ON DELETE SET NULL,
    privacy_classification VARCHAR(32) NOT NULL DEFAULT 'private' CHECK (privacy_classification IN ('private', 'sensitive')),
    temporal_original_expression TEXT NULL,
    temporal_resolved_at TIMESTAMPTZ NULL,
    temporal_timezone VARCHAR(64) NULL,
    temporal_locale VARCHAR(16) NULL DEFAULT 'ar',
    temporal_calendar VARCHAR(16) NULL DEFAULT 'gregorian',
    created_by_installation_id UUID NULL REFERENCES installations(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    entity_version INT NOT NULL DEFAULT 1
);

CREATE INDEX idx_items_ws_type ON items(workspace_id, item_type);
CREATE INDEX idx_items_created_at ON items(workspace_id, created_at DESC);
CREATE INDEX idx_items_deleted_at ON items(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX idx_items_category ON items(category_id) WHERE category_id IS NOT NULL;

CREATE TABLE tasks (
    item_id UUID NOT NULL PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
    due_date TIMESTAMPTZ NULL,
    priority VARCHAR(16) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status VARCHAR(16) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    completed_at TIMESTAMPTZ NULL,
    estimated_duration_minutes INT NULL CHECK (estimated_duration_minutes IS NULL OR estimated_duration_minutes > 0)
);

CREATE INDEX idx_tasks_status_due ON tasks(status, due_date);

CREATE TABLE appointments (
    item_id UUID NOT NULL PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NULL,
    location TEXT NULL,
    all_day BOOLEAN NOT NULL DEFAULT FALSE,
    timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Aden',
    CONSTRAINT chk_appointments_time_order CHECK (end_time IS NULL OR end_time >= start_time)
);

CREATE INDEX idx_appointments_start_time ON appointments(start_time);

CREATE TABLE notes (
    item_id UUID NOT NULL PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    content_format VARCHAR(32) NOT NULL DEFAULT 'plain_text' CHECK (content_format IN ('plain_text', 'markdown'))
);

CREATE TABLE documents (
    item_id UUID NOT NULL PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
    document_type VARCHAR(64) NOT NULL,
    issue_date DATE NULL,
    expiry_date DATE NULL,
    document_number VARCHAR(128) NULL,
    issuing_authority VARCHAR(128) NULL,
    CONSTRAINT chk_documents_dates CHECK (expiry_date IS NULL OR issue_date IS NULL OR expiry_date >= issue_date)
);

CREATE INDEX idx_documents_expiry_date ON documents(expiry_date);

CREATE TABLE debts (
    item_id UUID NOT NULL PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
    debt_type VARCHAR(16) NOT NULL CHECK (debt_type IN ('payable', 'receivable')),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE RESTRICT,
    total_amount NUMERIC(14, 2) NOT NULL CHECK (total_amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'YER',
    due_date DATE NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'settled', 'defaulted', 'cancelled'))
);

CREATE INDEX idx_debts_person ON debts(person_id);
CREATE INDEX idx_debts_status ON debts(status);

CREATE TABLE debt_transactions (
    id UUID NOT NULL PRIMARY KEY,
    debt_id UUID NOT NULL REFERENCES debts(item_id) ON DELETE CASCADE,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    transaction_type VARCHAR(16) NOT NULL CHECK (transaction_type IN ('payment', 'reversal', 'adjustment')),
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    transaction_date DATE NOT NULL,
    notes TEXT NULL,
    reference_transaction_id UUID NULL REFERENCES debt_transactions(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    entity_version INT NOT NULL DEFAULT 1
);

CREATE INDEX idx_debt_tx_debt_id ON debt_transactions(debt_id);
CREATE INDEX idx_debt_tx_workspace_id ON debt_transactions(workspace_id);
CREATE INDEX idx_debt_tx_ref ON debt_transactions(reference_transaction_id) WHERE reference_transaction_id IS NOT NULL;

CREATE TABLE shopping_lists (
    item_id UUID NOT NULL PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE shopping_entries (
    id UUID NOT NULL PRIMARY KEY,
    shopping_list_id UUID NOT NULL REFERENCES shopping_lists(item_id) ON DELETE CASCADE,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 1.00 CHECK (quantity > 0),
    unit VARCHAR(32) NULL,
    is_checked BOOLEAN NOT NULL DEFAULT FALSE,
    checked_at TIMESTAMPTZ NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    entity_version INT NOT NULL DEFAULT 1
);

CREATE INDEX idx_shopping_entries_list ON shopping_entries(shopping_list_id, is_checked, sort_order);

-- -----------------------------------------------------------------------------
-- 4. Reminders & Notifications Subsystem
-- -----------------------------------------------------------------------------

CREATE TABLE reminder_rules (
    id UUID NOT NULL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    trigger_type VARCHAR(16) NOT NULL CHECK (trigger_type IN ('relative', 'absolute', 'recurring')),
    trigger_time TIMESTAMPTZ NULL,
    offset_minutes INT NULL,
    rrule TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    entity_version INT NOT NULL DEFAULT 1
);

CREATE INDEX idx_reminder_rules_item_id ON reminder_rules(item_id);
CREATE INDEX idx_reminder_rules_active ON reminder_rules(workspace_id, is_active) WHERE is_active = TRUE;

CREATE TABLE reminder_instances (
    id UUID NOT NULL PRIMARY KEY,
    rule_id UUID NOT NULL REFERENCES reminder_rules(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    occurrence_key VARCHAR(128) NOT NULL,
    scheduled_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'triggered', 'snoozed', 'dismissed', 'cancelled')),
    snoozed_until TIMESTAMPTZ NULL,
    fired_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    entity_version INT NOT NULL DEFAULT 1,
    CONSTRAINT uq_reminder_instance_rule_occ UNIQUE (rule_id, occurrence_key)
);

CREATE INDEX idx_reminder_instances_scheduled ON reminder_instances(status, scheduled_time);
CREATE INDEX idx_reminder_instances_item ON reminder_instances(item_id);

CREATE TABLE notifications (
    id UUID NOT NULL PRIMARY KEY,
    instance_id UUID NOT NULL REFERENCES reminder_instances(id) ON DELETE CASCADE,
    installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    delivery_channel VARCHAR(32) NOT NULL DEFAULT 'local_push' CHECK (delivery_channel IN ('local_push', 'system_tray')),
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    scheduled_for TIMESTAMPTZ NOT NULL,
    sent_at TIMESTAMPTZ NULL,
    delivery_status VARCHAR(16) NOT NULL DEFAULT 'scheduled' CHECK (delivery_status IN ('scheduled', 'delivered', 'failed', 'dismissed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_delivery ON notifications(installation_id, delivery_status, scheduled_for);

CREATE TABLE notification_actions (
    id UUID NOT NULL PRIMARY KEY,
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    action_type VARCHAR(32) NOT NULL CHECK (action_type IN ('dismiss', 'snooze_5m', 'snooze_15m', 'snooze_1h', 'mark_done', 'view_item')),
    acted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payload JSONB NULL
);

CREATE INDEX idx_notif_actions_notif ON notification_actions(notification_id);

-- -----------------------------------------------------------------------------
-- 5. Attachments & Explicit Associations
-- -----------------------------------------------------------------------------

CREATE TABLE attachments (
    id UUID NOT NULL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_size_bytes BIGINT NOT NULL CHECK (file_size_bytes >= 0),
    mime_type VARCHAR(128) NOT NULL,
    storage_path TEXT NOT NULL,
    checksum_sha256 VARCHAR(64) NOT NULL,
    privacy_classification VARCHAR(32) NOT NULL DEFAULT 'private' CHECK (privacy_classification IN ('private', 'sensitive')),
    created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    entity_version INT NOT NULL DEFAULT 1
);

CREATE INDEX idx_attachments_workspace_id ON attachments(workspace_id);
CREATE INDEX idx_attachments_sha256 ON attachments(checksum_sha256);

CREATE TABLE item_attachments (
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    attachment_id UUID NOT NULL REFERENCES attachments(id) ON DELETE CASCADE,
    caption TEXT NULL,
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (item_id, attachment_id)
);

CREATE TABLE debt_transaction_attachments (
    transaction_id UUID NOT NULL REFERENCES debt_transactions(id) ON DELETE CASCADE,
    attachment_id UUID NOT NULL REFERENCES attachments(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (transaction_id, attachment_id)
);

-- -----------------------------------------------------------------------------
-- 6. Inbox & AI Processing Pipeline
-- -----------------------------------------------------------------------------

CREATE TABLE inbox_items (
    id UUID NOT NULL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    raw_text TEXT NOT NULL,
    source_type VARCHAR(32) NOT NULL CHECK (source_type IN ('voice_transcription', 'manual_quick_note', 'share_intent', 'image_scan')),
    processing_status VARCHAR(32) NOT NULL DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'processed', 'rejected', 'error')),
    created_by_installation_id UUID NULL REFERENCES installations(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    entity_version INT NOT NULL DEFAULT 1
);

CREATE INDEX idx_inbox_workspace_status ON inbox_items(workspace_id, processing_status);

CREATE TABLE inbox_attachments (
    inbox_item_id UUID NOT NULL REFERENCES inbox_items(id) ON DELETE CASCADE,
    attachment_id UUID NOT NULL REFERENCES attachments(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (inbox_item_id, attachment_id)
);

CREATE TABLE ai_suggestions (
    id UUID NOT NULL PRIMARY KEY,
    inbox_item_id UUID NOT NULL REFERENCES inbox_items(id) ON DELETE CASCADE,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    intent VARCHAR(64) NOT NULL,
    suggested_payload JSONB NOT NULL,
    confidence_score NUMERIC(4, 3) NOT NULL CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0),
    validation_status VARCHAR(32) NOT NULL DEFAULT 'pending_review' CHECK (validation_status IN ('pending_review', 'accepted', 'rejected', 'edited')),
    ai_schema_version VARCHAR(32) NOT NULL DEFAULT '1.0',
    model_name VARCHAR(64) NOT NULL,
    model_version VARCHAR(64) NOT NULL,
    prompt_version VARCHAR(32) NOT NULL,
    reviewed_by_user_id UUID NULL REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_suggestions_inbox_id ON ai_suggestions(inbox_item_id);
CREATE INDEX idx_ai_suggestions_status ON ai_suggestions(workspace_id, validation_status);

-- -----------------------------------------------------------------------------
-- 7. Events (Audit & Observability Log — NOT Sync)
-- -----------------------------------------------------------------------------

CREATE TABLE events (
    id UUID NOT NULL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NULL REFERENCES users(id) ON DELETE SET NULL,
    installation_id UUID NULL REFERENCES installations(id) ON DELETE SET NULL,
    event_type VARCHAR(128) NOT NULL,
    aggregate_type VARCHAR(64) NOT NULL,
    aggregate_id UUID NOT NULL,
    payload JSONB NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_events_ws_time ON events(workspace_id, occurred_at);
CREATE INDEX idx_events_aggregate ON events(aggregate_type, aggregate_id);

-- -----------------------------------------------------------------------------
-- 8. Sync Infrastructure (Replication Stream & Idempotency)
-- -----------------------------------------------------------------------------

CREATE TABLE sync_changes (
    server_sequence BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    entity_type VARCHAR(64) NOT NULL,
    entity_id UUID NOT NULL,
    operation VARCHAR(16) NOT NULL CHECK (operation IN ('insert', 'update', 'delete')),
    entity_version INT NOT NULL,
    source_installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE RESTRICT,
    operation_id UUID NOT NULL,
    change_payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_changes_stream ON sync_changes(workspace_id, server_sequence);
CREATE INDEX idx_sync_changes_entity ON sync_changes(entity_type, entity_id, entity_version);

CREATE TABLE sync_idempotency (
    operation_id UUID NOT NULL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
    entity_type VARCHAR(64) NOT NULL,
    entity_id UUID NOT NULL,
    payload_hash_sha256 VARCHAR(64) NOT NULL,
    first_received_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(32) NOT NULL CHECK (status IN ('processed', 'failed')),
    response_summary JSONB NULL
);

CREATE INDEX idx_sync_idempotency_ws ON sync_idempotency(workspace_id, first_received_at);

CREATE TABLE sync_conflicts (
    id UUID NOT NULL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    entity_type VARCHAR(64) NOT NULL,
    entity_id UUID NOT NULL,
    source_installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
    client_version INT NOT NULL,
    server_version INT NOT NULL,
    client_payload JSONB NOT NULL,
    server_payload JSONB NOT NULL,
    resolution_strategy VARCHAR(32) NOT NULL CHECK (resolution_strategy IN ('auto_merged', 'domain_resolved', 'pending_user_action', 'user_resolved')),
    resolved_payload JSONB NULL,
    resolved_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_conflicts_ws ON sync_conflicts(workspace_id, created_at DESC);
