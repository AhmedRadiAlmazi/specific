// Login Page — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/core/session/session_manager.dart';
import 'package:mouin/infrastructure/network/remote_sync_api.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';
import 'package:mouin/presentation/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  final TaskBloc taskBloc;
  final DebtBloc debtBloc;
  final SyncBloc syncBloc;
  final RemoteSyncApi remoteSyncApi;

  const LoginPage({
    super.key,
    required this.taskBloc,
    required this.debtBloc,
    required this.syncBloc,
    required this.remoteSyncApi,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController(text: 'user@mouin.app');
  final _passwordController = TextEditingController(text: 'Password123!');
  bool _isLoading = false;
  String? _errorMessage;

  void _proceedToHome(String email, String name, String role, String token, List<Map<String, dynamic>> workspaces) {
    SessionManager().setSession(
      newToken: token,
      newUserId: '018e3a2b-0005-7000-8000-000000000005',
      newEmail: email,
      newName: name,
      newRole: 'user',
      newWorkspaces: workspaces.isNotEmpty
          ? workspaces
          : [
              {'id': '018e3a2b-0002-7000-8000-000000000002', 'name': 'مساحتي الشخصية', 'role': 'owner'},
            ],
    );

    final wsId = SessionManager().activeWorkspaceId;
    widget.taskBloc.loadTasks(wsId);
    widget.debtBloc.loadDebts(wsId);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: HomePage(
            taskBloc: widget.taskBloc,
            debtBloc: widget.debtBloc,
            syncBloc: widget.syncBloc,
            remoteSyncApi: widget.remoteSyncApi,
            workspaceId: wsId,
          ),
        ),
      ),
    );
  }

  Future<void> _performLogin([String? customEmail, String? customPass]) async {
    final email = customEmail ?? _usernameController.text.trim();
    final pass = customPass ?? _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await widget.remoteSyncApi.login(email, pass);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (res.isSuccess) {
      final data = res.value;
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final workspaces = (data['workspaces'] as List<dynamic>? ?? [])
          .map((w) => w as Map<String, dynamic>)
          .toList();

      _proceedToHome(
        email,
        user['name'] ?? 'أحمد',
        'user',
        data['access_token'] ?? 'offline_jwt_token',
        workspaces,
      );
    } else {
      setState(() => _errorMessage = res.failure.message);
    }
  }

  void _loginOffline() {
    final email = _usernameController.text.trim().isNotEmpty ? _usernameController.text.trim() : 'user@mouin.app';
    _proceedToHome(
      email,
      'أحمد',
      'user',
      'local_offline_token',
      [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.person_pin, size: 52, color: Colors.teal),
                    const SizedBox(height: 10),
                    const Text(
                      'مُعين — مرحباً بك',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'مساعدك الشخصي الذكي لإدارة المهام والديون',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _loginOffline,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'المتابعة في الوضع المحلي (Offline) ←',
                                  style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : () => _performLogin(),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('دخول حسابي الشخصي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.offline_bolt_outlined, size: 18, color: Colors.teal),
                      label: const Text('دخول محلي بدون اتصال (Offline)', style: TextStyle(color: Colors.teal, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _loginOffline,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'أو دخول سريع تجريبي:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person, size: 18),
                      label: const Text('دخول سريع بحساب أحمد', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : () => _performLogin('user@mouin.app', 'Password123!'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
