import 'package:flutter/foundation.dart';

import '../models/cash_advance.dart';
import '../services/api_services.dart';

/// Menyimpan feed notifikasi + jumlah belum dibaca (dipakai badge di app bar).
class NotificationState extends ChangeNotifier {
  NotificationState(this.services);

  final ApiServices services;

  List<AppNotification> items = const [];
  int unread = 0;
  bool loading = false;
  String? error;

  Future<void> refresh() async {
    loading = items.isEmpty;
    error = null;
    notifyListeners();

    try {
      final result = await services.notifications();
      items = result.items;
      unread = result.unread;
    } catch (e) {
      error = '$e';
    }

    loading = false;
    notifyListeners();
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      unread = await services.markNotificationRead(notification.id);
      items = [
        for (final item in items)
          if (item.id == notification.id)
            AppNotification(
              id: item.id,
              title: item.title,
              body: item.body,
              type: item.type,
              isRead: true,
              payrollId: item.payrollId,
              createdAt: item.createdAt,
            )
          else
            item,
      ];
      notifyListeners();
    } catch (_) {
      // Diamkan: badge akan diperbarui saat refresh berikutnya.
    }
  }

  Future<void> markAllRead() async {
    try {
      await services.markAllNotificationsRead();
      unread = 0;
      items = [
        for (final item in items)
          AppNotification(
            id: item.id,
            title: item.title,
            body: item.body,
            type: item.type,
            isRead: true,
            payrollId: item.payrollId,
            createdAt: item.createdAt,
          ),
      ];
      notifyListeners();
    } catch (_) {}
  }
}
