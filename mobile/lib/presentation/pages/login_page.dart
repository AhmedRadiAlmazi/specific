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
  final _usernameController = TextEditingController(text: 'admin@mouin.app');
  final _passwordController = TextEditingController(text: 'Password123!');
  bool _isLoading = false;
  String? _errorMessage;

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

      SessionManager().setSession(
        newToken: data['access_token'] ?? '',
        newUserId: user['id'] ?? '',
        newEmail: user['email'] ?? email,
        newName: user['name'] ?? 'مستخدم',
        newRole: user['role'] ?? 'user',
        newWorkspaces: workspaces,
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
    } else {
      setState(() => _errorMessage = res.failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.shield_outlined, size: 56, color: Colors.teal),
                    const SizedBox(height: 12),
                    const Text(
                      'مُعين — تسجيل الدخول',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'الوصول الآمن إلى مساحة العمل والمزامنة السحابية',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                        ),
                      ),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : () => _performLogin(),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'أو تسجيل سريع بنقرة واحدة:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => _performLogin('admin@mouin.app', 'Password123!'),
                            child: const Text('مدير (Admin)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => _performLogin('user@mouin.app', 'Password123!'),
                            child: const Text('مستخدم (User)'),
                          ),
                        ),
                      ],
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
