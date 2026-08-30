// SQLite Local In-Memory & Persistence Store — مشروع «مُعين» (Mouin)

class LocalSqliteDb {
  // Tables replicating mobile/database/sqlite_schema.sql
  final Map<String, Map<String, dynamic>> items = {};
  final Map<String, Map<String, dynamic>> tasks = {};
  final Map<String, Map<String, dynamic>> debts = {};
  final Map<String, Map<String, dynamic>> debtTransactions = {};
  final Map<String, Map<String, dynamic>> reminderRules = {};
  final Map<String, Map<String, dynamic>> reminderInstances = {};
  final Map<String, Map<String, dynamic>> outbox = {};
  final Map<String, int> syncState = {}; // workspace_id -> last_server_sequence

  void clear() {
    items.clear();
    tasks.clear();
    debts.clear();
    debtTransactions.clear();
    reminderRules.clear();
    reminderInstances.clear();
    outbox.clear();
    syncState.clear();
  }
}
