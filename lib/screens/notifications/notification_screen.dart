import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/cash_advance.dart';
import '../../state/notification_state.dart';
import '../../widgets/ui.dart';
import '../payroll/slip_detail_screen.dart';

/// Feed notifikasi (surface: operate) — fitur yang ditonjolkan di skripsi.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationState>().refresh());
  }

  IconData _iconFor(String type) => switch (type) {
        'payroll_paid' => Icons.check_circle_outline,
        'payroll_issued' => Icons.receipt_long_outlined,
        _ => Icons.notifications_none_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (state.unread > 0)
            TextButton(
              onPressed: () => state.markAllRead(),
              child: Text('Tandai dibaca',
                  style: appText(size: 12, weight: FontWeight.w600, color: AppColors.primary)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: AsyncContent(
        loading: state.loading,
        error: state.error,
        onRetry: state.refresh,
        isEmpty: state.items.isEmpty,
        emptyMessage: 'Belum ada notifikasi. Slip baru akan muncul di sini.',
        child: RefreshIndicator(
          onRefresh: state.refresh,
          child: ListView(
            padding: EdgeInsets.zero,
            children: _buildGroups(state.items),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroups(List<AppNotification> items) {
    final groups = <String, List<AppNotification>>{};

    for (final item in items) {
      groups.putIfAbsent(_groupLabel(item.createdAt), () => []).add(item);
    }

    return [
      for (final entry in groups.entries) ...[
        Container(
          width: double.infinity,
          color: AppColors.canvas,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(entry.key.toUpperCase(), style: labelText().copyWith(letterSpacing: 1)),
        ),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              for (var i = 0; i < entry.value.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                _NotificationRow(
                  notification: entry.value[i],
                  icon: _iconFor(entry.value[i].type),
                  onTap: () async {
                    final notifier = context.read<NotificationState>();
                    await notifier.markRead(entry.value[i]);

                    final payrollId = entry.value[i].payrollId;
                    if (payrollId != null && mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SlipDetailScreen(payrollId: payrollId)),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 24),
    ];
  }

  String _groupLabel(DateTime? time) {
    if (time == null) return 'Sebelumnya';

    final now = DateTime.now();
    final date = time.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;

    if (diff <= 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return 'Minggu ini';
    return 'Lebih lama';
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.icon, required this.onTap});

  final AppNotification notification;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: unread ? AppColors.primarySoft : AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: unread ? AppColors.primary : AppColors.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: appText(
                            size: 13.5,
                            weight: unread ? FontWeight.w700 : FontWeight.w500,
                            color: unread ? AppColors.ink : AppColors.inkMuted,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 5),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(notification.body, style: appText(size: 11.5, color: AppColors.muted, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(Formats.timeAgo(notification.createdAt), style: appText(size: 10.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
