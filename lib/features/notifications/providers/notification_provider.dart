import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_item.dart';
import '../../reports/data/report_local_repository.dart';
import '../../transactions/data/transaction.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationNotifier extends Notifier<List<NotificationItem>> {
  bool _isSynced = false;

  @override
  List<NotificationItem> build() {
    return [];
  }

  Future<void> syncFromDatabase({bool force = false}) async {
    if (_isSynced && !force) return;
    _isSynced = true;
    try {
      if (!ref.mounted) return;
      final storeId = ref.read(activeStoreIdProvider);
      final reportRepo = ref.read(reportRepositoryProvider);
      final lowStockItems = await reportRepo.getLowStockProducts(storeId: storeId);

      if (!ref.mounted) return;
      final current = [...state];
      for (final item in lowStockItems) {
        final isCritical = item.stock <= 3;
        final title = isCritical ? 'Stok Habis / Kritis' : 'Stok Menipis';
        final message = isCritical
            ? 'Produk "${item.name}" tersisa ${item.stock} unit (kritis).'
            : 'Produk "${item.name}" tersisa ${item.stock} unit.';
        final type = isCritical ? NotificationType.alert : NotificationType.warning;

        final existingIndex = current.indexWhere((n) => n.title == title && n.message.contains(item.name));
        if (existingIndex == -1) {
          current.insert(
            0,
            NotificationItem(
              id: 'notif_stock_${item.name}_${DateTime.now().millisecondsSinceEpoch}',
              title: title,
              message: message,
              timestamp: DateTime.now(),
              type: type,
              isRead: false,
              targetRoute: '/products',
            ),
          );
        }
      }
      state = current;
    } catch (_) {}
  }

  void addTransactionNotification(Transaction txn) {
    final amountFormatted = _formatCurrency(txn.totalAmount.toInt());
    final idShort = txn.id.length > 8 ? txn.id.substring(0, 8) : txn.id;
    final newNotif = NotificationItem(
      id: 'notif_txn_${txn.id}',
      title: 'Transaksi Selesai',
      message: 'Transaksi #$idShort sebesar Rp $amountFormatted (${txn.paymentMethod.toUpperCase()}) berhasil diproses.',
      timestamp: DateTime.now(),
      type: NotificationType.success,
      isRead: false,
      targetRoute: '/reports',
    );
    state = [newNotif, ...state];

    // Trigger low stock check from DB after transaction completes
    syncFromDatabase(force: true);
  }

  void addShiftClosedNotification(ShiftSummary closedShift, double endingCash) {
    final cashFormatted = _formatCurrency(endingCash.toInt());
    final discFormatted = _formatCurrency(closedShift.discrepancy.toInt());
    final newNotif = NotificationItem(
      id: 'notif_shift_${closedShift.shiftId}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Rekap Shift #${closedShift.shiftId} Selesai',
      message: 'Shift ke-${closedShift.shiftNumber} (${closedShift.username}) telah ditutup. Setoran: Rp $cashFormatted, Selisih: Rp $discFormatted.',
      timestamp: DateTime.now(),
      type: NotificationType.info,
      isRead: false,
      targetRoute: '/settings',
    );
    state = [newNotif, ...state];
  }

  static String _formatCurrency(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    final prefix = amount < 0 ? '-' : '';
    return '$prefix$buffer';
  }

  void markAsRead(String id) {
    state = [
      for (final notif in state)
        if (notif.id == id) notif.copyWith(isRead: true) else notif
    ];
  }

  void markAllAsRead() {
    state = [
      for (final notif in state) notif.copyWith(isRead: true)
    ];
  }

  void deleteNotification(String id) {
    state = state.where((notif) => notif.id != id).toList();
  }

  void clearAll() {
    state = [];
  }

  void addNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? targetRoute,
  }) {
    final newNotif = NotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      targetRoute: targetRoute,
    );
    state = [newNotif, ...state];
  }
}

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, List<NotificationItem>>(
  NotificationNotifier.new,
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationNotifierProvider);
  return notifications.where((n) => !n.isRead).length;
});

