import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_flutter/features/notifications/data/notification_item.dart';
import 'package:mobile_pos_flutter/features/notifications/providers/notification_provider.dart';
import 'package:mobile_pos_flutter/features/transactions/data/transaction.dart';
import 'package:mobile_pos_flutter/features/reports/data/report_local_repository.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
      ],
    );
    addTearDown(() {
      container.read(localDatabaseServiceProvider).close();
      container.dispose();
    });
    return container;
  }

  test('addNotification prepends new notification to the list', () {
    final container = createContainer();
    final notifier = container.read(notificationNotifierProvider.notifier);

    notifier.addNotification(
      title: 'Stok Habis',
      message: 'Kopi Susu habis',
      type: NotificationType.alert,
      targetRoute: '/products',
    );

    final notifications = container.read(notificationNotifierProvider);
    expect(notifications.first.title, 'Stok Habis');
    expect(notifications.first.type, NotificationType.alert);
    expect(notifications.first.isRead, false);
  });

  test('addTransactionNotification adds transaction notification with formatted amount', () {
    final container = createContainer();
    final notifier = container.read(notificationNotifierProvider.notifier);

    final txn = Transaction(
      id: 'txn_test_12345',
      shiftId: 'shift_1',
      totalAmount: 150000,
      paymentMethod: 'cash',
      createdAt: DateTime.now().toIso8601String(),
    );

    notifier.addTransactionNotification(txn);

    final notifications = container.read(notificationNotifierProvider);
    expect(notifications.first.title, 'Transaksi Selesai');
    expect(notifications.first.message.contains('Rp 150.000'), true);
    expect(notifications.first.type, NotificationType.success);
    expect(notifications.first.targetRoute, '/reports');
  });

  test('addShiftClosedNotification adds shift summary notification', () {
    final container = createContainer();
    final notifier = container.read(notificationNotifierProvider.notifier);

    const shiftSummary = ShiftSummary(
      shiftId: '101',
      userId: 'user_1',
      username: 'Kasir Utama',
      startTime: '2026-08-13 08:00:00',
      startingCash: 500000,
      endingCash: 1200000,
      totalSalesCash: 700000,
      totalSalesNonCash: 0,
      totalSalesVoid: 0,
      expectedDrawerCash: 1200000,
      discrepancy: 0,
      totalTransactions: 5,
      status: 'closed',
      shiftNumber: 1,
    );

    notifier.addShiftClosedNotification(shiftSummary, 1200000);

    final notifications = container.read(notificationNotifierProvider);
    expect(notifications.first.title, 'Rekap Shift #101 Selesai');
    expect(notifications.first.message.contains('Shift ke-1 (Kasir Utama) telah ditutup'), true);
    expect(notifications.first.type, NotificationType.info);
    expect(notifications.first.targetRoute, '/settings');
  });

  test('markAsRead updates specific notification isRead status to true', () {
    final container = createContainer();
    final notifier = container.read(notificationNotifierProvider.notifier);

    notifier.addNotification(title: 'Test', message: 'Message');
    final notifId = container.read(notificationNotifierProvider).first.id;

    notifier.markAsRead(notifId);

    final notifications = container.read(notificationNotifierProvider);
    expect(notifications.first.isRead, true);
  });

  test('markAllAsRead sets all notifications isRead status to true', () {
    final container = createContainer();
    final notifier = container.read(notificationNotifierProvider.notifier);

    notifier.addNotification(title: 'Notif 1', message: 'Message 1');
    notifier.addNotification(title: 'Notif 2', message: 'Message 2');

    notifier.markAllAsRead();

    final unreadCount = container.read(unreadNotificationCountProvider);
    expect(unreadCount, 0);
  });

  test('deleteNotification removes notification from list', () {
    final container = createContainer();
    final notifier = container.read(notificationNotifierProvider.notifier);

    notifier.addNotification(title: 'Notif To Delete', message: 'Delete Me');
    final notifId = container.read(notificationNotifierProvider).first.id;

    notifier.deleteNotification(notifId);

    final notifications = container.read(notificationNotifierProvider);
    expect(notifications.any((n) => n.id == notifId), false);
  });

  test('clearAll clears all notifications', () {
    final container = createContainer();
    final notifier = container.read(notificationNotifierProvider.notifier);

    notifier.addNotification(title: 'Notif 1', message: 'Message 1');
    notifier.clearAll();

    expect(container.read(notificationNotifierProvider).isEmpty, true);
    expect(container.read(unreadNotificationCountProvider), 0);
  });
}
