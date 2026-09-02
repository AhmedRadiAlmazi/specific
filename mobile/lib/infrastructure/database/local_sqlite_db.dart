// Local SQLite Database In-Memory & File Store — مشروع «مُعين» (Mouin)
class LocalSqliteDb {
  final Map<String, Map<String, dynamic>> items = {};
  final Map<String, Map<String, dynamic>> tasks = {};
  final Map<String, Map<String, dynamic>> notes = {};
  final Map<String, Map<String, dynamic>> appointments = {};
  final Map<String, Map<String, dynamic>> documents = {};
  final Map<String, Map<String, dynamic>> debts = {};
  final Map<String, Map<String, dynamic>> reminders = {};
  final Map<String, int> syncState = {};

  void clear() {
    items.clear();
    tasks.clear();
    notes.clear();
    appointments.clear();
    documents.clear();
    debts.clear();
    reminders.clear();
    syncState.clear();
  }
}
