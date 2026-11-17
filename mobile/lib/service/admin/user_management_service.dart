import '../../model/admin/user_admin_model.dart';
import '../../model/admin/user_details_model.dart';
import '../api_service.dart';

class UserManagementService {
  final ApiService api;

  UserManagementService(this.api);

  // Get all members
  Future<List<AdminUserModel>> getAllUsers() async {
    final response = await api.get('/api/admin/users/all');

    if (response is! Map || response['users'] is! List) {
      throw const FormatException('Invalid users response');
    }

    final List<dynamic> data = response['users'];

    return data.map((item) {
      return AdminUserModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  // Get member details and history
  Future<UserDetailsModel> getUserDetails(int userId) async {
    final response = await api.get('/api/admin/users/$userId/details');

    if (response is! Map) {
      throw const FormatException('Invalid user details response');
    }

    return UserDetailsModel.fromJson(Map<String, dynamic>.from(response));
  }

  // Enable / Disable member account
  Future<void> updateUserStatus({
    required int userId,
    required bool isActive,
  }) async {
    await api.patch(
      '/api/admin/users/$userId/status',
      body: {'is_active': isActive ? 1 : 0},
    );
  }
}
