// Login & Authentication Page — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/core/theme/app_colors.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';
import 'package:mouin/presentation/pages/home_page.dart';
import 'package:mouin/presentation/widgets/brand/mouin_logo.dart';

class LoginPage extends StatefulWidget {
  final TaskBloc taskBloc;
  final DebtBloc debtBloc;
  final SyncBloc syncBloc;

  const LoginPage({
    super.key,
    required this.taskBloc,
    required this.debtBloc,
    required this.syncBloc,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'user@mouin.app');
  final _passwordController = TextEditingController(text: 'Password123!');
  final String _workspaceId = '018e3a2b-0002-7000-8000-000000000002';

  void _proceedToHome() {
    widget.taskBloc.loadTasks(_workspaceId);
    widget.debtBloc.loadDebts(_workspaceId);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: HomePage(
            taskBloc: widget.taskBloc,
            debtBloc: widget.debtBloc,
            syncBloc: widget.syncBloc,
            workspaceId: _workspaceId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Branded Card
                  Card(
                    elevation: 1,
                    shadowColor: AppColors.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App Branded Logo
                          const MouinLogo(
                            size: MouinLogoSize.large,
                            showText: true,
                            showSubtitle: true,
                            customSubtitle: 'المساعد الشخصي الذكي لإدارة المهام والديون',
                          ),
                          const SizedBox(height: 24),

                          // Form Inputs
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              hintText: 'example@domain.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Main Login Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.login_rounded, size: 20),
                            label: const Text('دخول حسابي (أحمد)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            onPressed: _proceedToHome,
                          ),
                          const SizedBox(height: 10),

                          // Offline Mode Button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.cloud_off_rounded, size: 18),
                            label: const Text('دخول محلي (Offline)', style: TextStyle(fontWeight: FontWeight.w600)),
                            onPressed: _proceedToHome,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footer version & brand stamp
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.financeMint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Text(
                        'مُعين v1.0.0 — رفيقك اليومي للإنجاز',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
