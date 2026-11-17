import 'package:material_ui/material_ui.dart';

import '../../model/admin/user_admin_model.dart';
import '../../service/admin/user_management_service.dart';

class UserManagementController extends ChangeNotifier {
  final UserManagementService userService;

  UserManagementController(this.userService);

  List<AdminUserModel> users = [];

  bool isLoading = false;
  String? errorMessage;

  final Set<int> updatingUserIds = {};

  int get totalUsers => users.length;

  int get activeUsers => users.where((user) => user.isActive).length;

  int get inactiveUsers => users.where((user) => !user.isActive).length;

  bool isUpdating(int userId) => updatingUserIds.contains(userId);

  Future<void> loadUsers({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }

    errorMessage = null;

    try {
      users = await userService.getAllUsers();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserStatus({
    required int userId,
    required bool isActive,
  }) async {
    if (updatingUserIds.contains(userId)) return;

    updatingUserIds.add(userId);
    errorMessage = null;
    notifyListeners();

    try {
      await userService.updateUserStatus(userId: userId, isActive: isActive);

      await loadUsers(showLoading: false);
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      updatingUserIds.remove(userId);
      notifyListeners();
    }
  }
}
