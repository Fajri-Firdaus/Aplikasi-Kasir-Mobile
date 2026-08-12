import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/notification_item.dart';
import '../providers/notification_provider.dart';

class NotificationPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const NotificationPanel({
    super.key,
    required this.onClose,
  });

  @override
  ConsumerState<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<NotificationPanel> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Belum Dibaca

  @override
  Widget build(BuildContext context) {
    final allNotifications = ref.watch(notificationNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final filteredNotifications = _selectedFilterIndex == 1
        ? allNotifications.where((n) => !n.isRead).toList()
        : allNotifications;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (allNotifications.isNotEmpty)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                      onSelected: (value) {
                        if (value == 'read_all') {
                          ref
                              .read(notificationNotifierProvider.notifier)
                              .markAllAsRead();
                        } else if (value == 'clear_all') {
                          ref
                              .read(notificationNotifierProvider.notifier)
                              .clearAll();
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (unreadCount > 0)
                          const PopupMenuItem(
                            value: 'read_all',
                            child: Row(
                              children: [
                                Icon(Icons.done_all, size: 18, color: Color(0xFF2563EB)),
                                SizedBox(width: 8),
                                Text('Tandai semua dibaca'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'clear_all',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                              SizedBox(width: 8),
                              Text('Hapus semua'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                    onPressed: widget.onClose,
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),

            // Sub-header Row: Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Semua',
                    count: allNotifications.length,
                    isSelected: _selectedFilterIndex == 0,
                    onTap: () => setState(() => _selectedFilterIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Belum Dibaca',
                    count: unreadCount,
                    isSelected: _selectedFilterIndex == 1,
                    onTap: () => setState(() => _selectedFilterIndex = 1),
                  ),
                ],
              ),
            ),

            // Action Row: Tandai Dibaca Semua Button (underneath title & filter chips)
            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      ref
                          .read(notificationNotifierProvider.notifier)
                          .markAllAsRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Semua notifikasi ditandai sebagai sudah dibaca'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.done_all,
                              size: 15, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Text(
                            'Tandai Dibaca Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Notification List or Empty State
            Expanded(
              child: filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredNotifications.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (context, index) {
                        final notif = filteredNotifications[index];
                        return _buildNotificationItem(context, notif);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationItem notif) {
    final style = _getStyleForType(notif.type);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref
            .read(notificationNotifierProvider.notifier)
            .deleteNotification(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi dihapus'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        color: const Color(0xFFFEE2E2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
      ),
      child: Material(
        color: notif.isRead ? Colors.transparent : const Color(0xFFF0F7FF),
        child: InkWell(
          onTap: () {
            ref
                .read(notificationNotifierProvider.notifier)
                .markAsRead(notif.id);
            if (notif.targetRoute != null && notif.targetRoute!.isNotEmpty) {
              widget.onClose();
              context.go(notif.targetRoute!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Icon Container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: style.iconColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: notif.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          Text(
                            _formatRelativeTime(notif.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: notif.isRead
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),

                // Unread Dot
                if (!notif.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 32,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada notifikasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedFilterIndex == 1
                  ? 'Semua notifikasi sudah dibaca.'
                  : 'Belum ada notifikasi masuk saat ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NotifStyle _getStyleForType(NotificationType type) {
    switch (type) {
      case NotificationType.warning:
        return const _NotifStyle(
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFEA580C),
          bgColor: Color(0xFFFFEDD5),
        );
      case NotificationType.success:
        return const _NotifStyle(
          icon: Icons.check_circle_outline,
          iconColor: Color(0xFF16A34A),
          bgColor: Color(0xFFDCFCE7),
        );
      case NotificationType.alert:
        return const _NotifStyle(
          icon: Icons.error_outline,
          iconColor: Color(0xFFDC2626),
          bgColor: Color(0xFFFEE2E2),
        );
      case NotificationType.info:
        return const _NotifStyle(
          icon: Icons.info_outline,
          iconColor: Color(0xFF2563EB),
          bgColor: Color(0xFFDBEAFE),
        );
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mnt lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hr lalu';
    }
  }
}

class _NotifStyle {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _NotifStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
