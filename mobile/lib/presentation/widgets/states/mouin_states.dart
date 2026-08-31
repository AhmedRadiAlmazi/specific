// Reusable Screen State & Feedback Widgets — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import '../../theme/tokens/mouin_colors.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../common/mouin_button.dart';

class MouinLoadingState extends StatelessWidget {
  final String message;
  const MouinLoadingState({super.key, this.message = 'جاري التحميل...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: MouinSpacing.md),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class MouinEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MouinEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: MouinSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.secondary),
            const SizedBox(height: MouinSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: MouinSpacing.xs),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: MouinSpacing.lg),
              MouinButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class MouinErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  const MouinErrorState({
    super.key,
    this.title = 'حدث خطأ غير متوقع',
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: MouinSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: MouinColors.error),
            const SizedBox(height: MouinSpacing.md),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (message != null) ...[
              const SizedBox(height: MouinSpacing.xs),
              Text(message!, textAlign: TextAlign.center),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: MouinSpacing.lg),
              MouinButton(label: 'إعادة المحاولة', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

class MouinOfflineBanner extends StatelessWidget {
  final int pendingCount;
  const MouinOfflineBanner({super.key, this.pendingCount = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: MouinColors.warningContainer,
      padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: MouinSpacing.xs),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 16, color: MouinColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pendingCount > 0
                  ? 'وضع غير متصل — $pendingCount تغييرات محفوظة محلياً بانتظار المزامنة'
                  : 'أنت تعمل بدون اتصال — بياناتك محفوظة ومحمية محلياً',
              style: const TextStyle(fontSize: 12, color: MouinColors.warning, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
