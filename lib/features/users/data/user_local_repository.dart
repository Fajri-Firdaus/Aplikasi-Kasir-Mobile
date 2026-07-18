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
      isActive: true, // In simple mapping, or use a column if present
      createdAt: row['created_at']?.toString() ?? '',
      adminId: row['admin_id']?.toString(),
    );
  }

  @override
  Future<List<AppUser>> getAll() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'full_name ASC',
    );
    return maps.map(_mapRowToUser).toList();
  }

  @override
  Future<AppUser?> getById(String id) async {
    final db = await _dbService.database;
    final intId = int.tryParse(id);
    if (intId == null) return null;

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [intId],
    );

    if (maps.isEmpty) return null;
    return _mapRowToUser(maps.first);
  }

  @override
  Future<AppUser> create(AppUser item) async {
    final db = await _dbService.database;
    final hashedPassword = _hash(item.password ?? '123456');

    final id = await db.insert('users', {
      'full_name': item.name,
      'email': item.email,
      'username': item.username,
      'password': hashedPassword,
      'role': item.role,
      'admin_id': item.adminId != null ? int.tryParse(item.adminId!) : null,
    });

    return item.copyWith(id: id.toString());
  }

  @override
  Future<AppUser> update(String id, AppUser item) async {
    final db = await _dbService.database;
    final intId = int.tryParse(id);
    if (intId == null) throw Exception('Invalid User ID');

    final Map<String, dynamic> values = {
      'full_name': item.name,
      'email': item.email,
      'username': item.username,
      'role': item.role,
      'admin_id': item.adminId != null ? int.tryParse(item.adminId!) : null,
    };

    if (item.password != null && item.password!.isNotEmpty) {
      values['password'] = _hash(item.password!);
    }

    await db.update(
      'users',
      values,
      where: 'id = ?',
      whereArgs: [intId],
    );

    return item;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbService.database;
    final intId = int.tryParse(id);
    if (intId == null) return;

    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [intId],
    );
  }

  Future<AppUser?> authenticate(String username, String password) async {
    final db = await _dbService.database;
    final hashedPassword = _hash(password);

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
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
}
