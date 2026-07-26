import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/repository_interface.dart';
import '../../../core/data/local_database_service.dart';
import 'app_user.dart';

final userRepositoryProvider = Provider<UserLocalRepository>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return UserLocalRepository(dbService);
});

class UserLocalRepository implements RepositoryInterface<AppUser> {
  final LocalDatabaseService _dbService;

  UserLocalRepository(this._dbService);

  String _hash(String password) => base64Encode(utf8.encode(password));

  AppUser _mapRowToUser(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'].toString(),
      name: row['full_name']?.toString() ?? '',
      username: row['username'] as String,
      email: row['email']?.toString() ?? '',
      role: row['role'] as String,
      isActive: (row['is_active'] as int? ?? 1) == 1,
      createdAt: row['created_at']?.toString() ?? '',
      adminId: row['admin_id']?.toString(),
      storeId: row['store_id']?.toString(),
    );
  }

  @override
  Future<List<AppUser>> getAll() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'full_name ASC',
    );
    return maps.map(_mapRowToUser).toList();
  }

  Future<List<AppUser>> getAllForStore(String? storeId) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'store_id = ? AND is_active = 1',
      whereArgs: [activeStoreId],
      orderBy: 'full_name ASC',
    );
    return maps.map(_mapRowToUser).toList();
  }

  @override
  Future<AppUser?> getById(String id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapRowToUser(maps.first);
  }

  @override
  Future<AppUser> create(AppUser item) async {
    final db = await _dbService.database;
    final hashedPassword = _hash(item.password ?? '123456');

    final userId = item.id.isNotEmpty ? item.id : DateTime.now().millisecondsSinceEpoch.toString();
    final storeId = (item.storeId != null && item.storeId!.isNotEmpty) ? item.storeId! : 'store-uuid-001';

    await db.insert('users', {
      'id': userId,
      'full_name': item.name,
      'email': item.email,
      'username': item.username,
      'password': hashedPassword,
      'role': item.role,
      'admin_id': item.adminId,
      'store_id': storeId,
      'is_active': item.isActive ? 1 : 0,
    });

    return item.copyWith(id: userId, storeId: storeId);
  }

  @override
  Future<AppUser> update(String id, AppUser item) async {
    final db = await _dbService.database;

    final Map<String, dynamic> values = {
      'full_name': item.name,
      'email': item.email,
      'username': item.username,
      'role': item.role,
      'admin_id': item.adminId,
      'store_id': item.storeId,
      'is_active': item.isActive ? 1 : 0,
    };

    if (item.password != null && item.password!.isNotEmpty) {
      values['password'] = _hash(item.password!);
    }

    await db.update(
      'users',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );

    return item;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbService.database;
    // Soft Delete
    await db.update(
      'users',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<AppUser?> authenticate(String usernameOrEmail, String password) async {
    final db = await _dbService.database;
    final hashedPassword = _hash(password);

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND password = ?',
      whereArgs: [usernameOrEmail.trim(), usernameOrEmail.trim(), hashedPassword],
    );

    if (maps.isEmpty) return null;
    return _mapRowToUser(maps.first);
  }

  Future<AppUser?> getByUsername(String username) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
    );

    if (maps.isEmpty) return null;
    return _mapRowToUser(maps.first);
  }

  Future<AppUser?> getByEmail(String email) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim()],
    );

    if (maps.isEmpty) return null;
    return _mapRowToUser(maps.first);
  }
}
