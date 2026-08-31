// Session Manager — مشروع «مُعين» (Mouin)
// Secure in-memory & persistent session abstraction

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  String? token = 'mouin_jwt_018e3a2b_initial';
  String userId = '018e3a2b-0001-7000-8000-000000000001';
  String userEmail = 'admin@mouin.app';
  String userName = 'مدير النظام (Admin)';
  String userRole = 'admin';
  String activeWorkspaceId = '018e3a2b-0002-7000-8000-000000000002';
  List<Map<String, dynamic>> workspaces = [
    {'id': '018e3a2b-0002-7000-8000-000000000002', 'name': 'مساحة العمل الشخصية', 'role': 'owner'},
    {'id': '018e3a2b-0003-7000-8000-000000000003', 'name': 'مساحة عمل الفريق', 'role': 'admin'}
  ];

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  void setSession({
    required String newToken,
    required String newUserId,
    required String newEmail,
    required String newName,
    required String newRole,
    required List<Map<String, dynamic>> newWorkspaces,
  }) {
    token = newToken;
    userId = newUserId;
    userEmail = newEmail;
    userName = newName;
    userRole = newRole;
    workspaces = newWorkspaces;
    if (newWorkspaces.isNotEmpty) {
      activeWorkspaceId = newWorkspaces.first['id'] as String;
    }
  }

  void switchWorkspace(String newWorkspaceId) {
    activeWorkspaceId = newWorkspaceId;
  }

  void clearSession() {
    token = null;
    userId = '';
    userEmail = '';
    userName = '';
    userRole = '';
    workspaces = [];
  }

  Map<String, String> getAuthHeaders([String? workspaceId]) {
    final ws = workspaceId ?? activeWorkspaceId;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'x-user-id': userId,
      'x-workspace-id': ws,
    };
  }
}
