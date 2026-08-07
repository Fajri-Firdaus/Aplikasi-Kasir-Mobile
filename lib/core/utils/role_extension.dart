import '../../features/users/data/app_user.dart';

extension UserRoleX on AppUser? {
  /// Check if the user has Admin privileges.
  bool get isAdmin => this?.role.toLowerCase() == 'admin';

  /// Check if the user is a Cashier / Kasir.
  bool get isCashier => !isAdmin;
}
