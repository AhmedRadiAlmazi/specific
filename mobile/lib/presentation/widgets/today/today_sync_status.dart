// Today Sync Status Bar Widget — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';
import '../../theme/tokens/mouin_colors.dart';
import '../../theme/tokens/mouin_spacing.dart';

class TodaySyncStatus extends StatelessWidget {
  final SyncBloc syncBloc;
  final VoidCallback? onTriggerSync;

  const TodaySyncStatus({
    super.key,
    required this.syncBloc,
    this.onTriggerSync,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncState>(
      stream: syncBloc.state,
      initialData: syncBloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        Widget statusContent;

        if (state is SyncInProgress) {
          statusContent = Row(
            children: const [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: MouinColors.primary),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'جاري المزامنة الحية مع السحاب...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: MouinColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        } else if (state is SyncFailed) {
          statusContent = Row(
            children: [
              const Icon(Icons.cloud_off, size: 16, color: MouinColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أنت تعمل بدون اتصال — بياناتك محفوظة محلياً',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                ),
              ),
              if (onTriggerSync != null)
                GestureDetector(
                  onTap: onTriggerSync,
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontSize: 12, color: MouinColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          );
        } else {
          // Synced / Initial
          statusContent = Row(
            children: const [
              Icon(Icons.check_circle, size: 15, color: MouinColors.success),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'متصل ومحدث بالكامل محلياً وسحابياً',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: MouinColors.success, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: 6),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          child: statusContent,
        );
      },
    );
  }
}
