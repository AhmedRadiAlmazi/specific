// Today Greeting Header Widget — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/core/session/session_manager.dart';
import '../../theme/tokens/mouin_colors.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../common/mouin_icon_button.dart';

class TodayHeader extends StatelessWidget {
  final VoidCallback? onSearchPressed;
  final VoidCallback? onLogoutPressed;
  final VoidCallback? onSyncPressed;

  const TodayHeader({
    super.key,
    this.onSearchPressed,
    this.onLogoutPressed,
    this.onSyncPressed,
  });

  static String getGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 4 && hour < 12) {
      return '☀️ صباح الخير';
    } else if (hour >= 12 && hour < 18) {
      return '🌤️ مساء الخير';
    } else {
      return '🌙 مساء الخير';
    }
  }

  static String formatArabicDate(DateTime date) {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName، ${date.day} $monthName ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final userName = session.userName.isNotEmpty ? session.userName : 'مستخدم مُعين';
    final now = DateTime.now();
    final greeting = getGreeting(now);
    final formattedDate = formatArabicDate(now);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: MouinSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting، $userName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (onSyncPressed != null)
                      MouinIconButton(
                        icon: Icons.sync,
                        color: Colors.white,
                        semanticLabel: 'مزامنة السيرفر',
                        tooltip: 'مزامنة حية',
                        onPressed: onSyncPressed,
                      ),
                    if (onSearchPressed != null)
                      MouinIconButton(
                        icon: Icons.search,
                        color: Colors.white,
                        semanticLabel: 'بحث في العناصر',
                        tooltip: 'بحث',
                        onPressed: onSearchPressed,
                      ),
                    if (onLogoutPressed != null)
                      MouinIconButton(
                        icon: Icons.logout,
                        color: Colors.white,
                        semanticLabel: 'تسجيل الخروج',
                        tooltip: 'خروج',
                        onPressed: onLogoutPressed,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: MouinSpacing.xs),
          ],
        ),
      ),
    );
  }
}
