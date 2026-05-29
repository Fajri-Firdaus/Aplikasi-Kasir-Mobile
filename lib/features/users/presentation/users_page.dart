import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/users_provider.dart';
import '../data/app_user.dart';
import '../../../core/theme/app_colors.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Manajemen User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                        Text('${users.length} akun terdaftar', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showUserForm(context, ref, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _UserCard(
                  user: users[i],
                  onEdit: () => _showUserForm(context, ref, users[i]),
                  onDelete: () => _confirmDelete(context, ref, users[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserForm(BuildContext context, WidgetRef ref, AppUser? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _UserFormSheet(user: user, onSave: (updated) {
        final notifier = ref.read(usersProvider.notifier);
        if (user == null) { notifier.addUser(updated); } else { notifier.updateUser(user.id, updated); }
        Navigator.pop(context);
      }),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus User?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('User "${user.name}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () { ref.read(usersProvider.notifier).deleteUser(user.id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _UserCard({required this.user, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == 'admin';
    final avatarBg = isAdmin ? const Color(0xFFEDE9FE) : const Color(0xFFDBEAFE);
    final avatarColor = isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF2563EB);
    final badgeBg = isAdmin ? const Color(0xFFEDE9FE) : const Color(0xFFDBEAFE);
    final badgeColor = isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF2563EB);
    final initials = user.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
            child: Center(
              child: isAdmin
                  ? Icon(Icons.shield_outlined, color: avatarColor, size: 24)
                  : Text(initials, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: avatarColor)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF111827)))),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(user.role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
                ),
              ]),
              const SizedBox(height: 2),
              Text('@${user.username}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              Text(user.email, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ]),
          ),
          Column(children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2563EB)), onPressed: onEdit, padding: EdgeInsets.zero),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)), onPressed: onDelete, padding: EdgeInsets.zero),
          ]),
        ],
      ),
    );
  }
}

class _UserFormSheet extends StatefulWidget {
  final AppUser? user;
  final void Function(AppUser) onSave;
  const _UserFormSheet({required this.user, required this.onSave});
  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late String _role;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _usernameCtrl = TextEditingController(text: u?.username ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _role = u?.role ?? 'kasir';
  }

  @override
  void dispose() { _nameCtrl.dispose(); _usernameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  void _save() {
    if (_nameCtrl.text.isEmpty || _usernameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua field wajib diisi')));
      return;
    }
    widget.onSave(AppUser(
      id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      role: _role,
      createdAt: widget.user?.createdAt ?? DateTime.now().toIso8601String().substring(0, 10),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.user == null ? 'Tambah User Baru' : 'Edit User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          _buildField('Nama Lengkap *', _nameCtrl, 'cth. Budi Santoso'),
          _buildField('Username *', _usernameCtrl, 'cth. budi'),
          _buildField('Email *', _emailCtrl, 'budi@pos.com', type: TextInputType.emailAddress),
          const SizedBox(height: 4),
          const Text('Role *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _roleBtn('kasir', 'Kasir', const Color(0xFF2563EB))),
            const SizedBox(width: 10),
            Expanded(child: _roleBtn('admin', 'Admin', const Color(0xFF7C3AED))),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(widget.user == null ? 'Tambah User' : 'Simpan Perubahan', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          )),
        ]),
      ),
    );
  }

  Widget _roleBtn(String value, String label, Color activeColor) {
    final active = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: active ? activeColor : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: active ? Colors.white : const Color(0xFF374151)))),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl, keyboardType: type,
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true, fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ]),
    );
  }
}
