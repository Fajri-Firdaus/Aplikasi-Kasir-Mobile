import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),
              _SettingsGroup(
                items: [
                  _SettingsItem(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFDBEAFE),
                    title: 'Profil Pengguna',
                    subtitle: 'Kelola informasi akun Anda',
                    onTap: () => context.go('/settings/profile'),
                  ),
                  _SettingsItem(
                    icon: Icons.people_outline,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFEDE9FE),
                    title: 'Manajemen User',
                    subtitle: 'Kelola akun kasir dan admin',
                    onTap: () => context.go('/settings/users'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsGroup(
                items: [
                  _SettingsItem(
                    icon: Icons.store_outlined,
                    iconColor: const Color(0xFF16A34A),
                    iconBg: const Color(0xFFDCFCE7),
                    title: 'Pengaturan Toko',
                    subtitle: 'Nama toko, alamat, kontak',
                    onTap: () => context.go('/settings/store'),
                  ),
                  _SettingsItem(
                    icon: Icons.print_outlined,
                    iconColor: const Color(0xFFF97316),
                    iconBg: const Color(0xFFFFEDD5),
                    title: 'Printer & Hardware',
                    subtitle: 'Konfigurasi perangkat',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF6B7280),
                    iconBg: const Color(0xFFF3F4F6),
                    title: 'Tentang Aplikasi',
                    subtitle: 'Versi 1.0.0',
                    onTap: () {},
                    showChevron: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4183D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4183D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(authProvider.notifier).logout();
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (index > 0) const Divider(height: 1, indent: 56, color: Color(0xFFE5E7EB)),
              _buildRow(item),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRow(_SettingsItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  Text(item.subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            if (item.showChevron)
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });
}
