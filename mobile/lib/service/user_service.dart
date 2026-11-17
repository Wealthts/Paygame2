import 'package:mobile/core/api_constant.dart';
import 'package:mobile/model/user_model.dart';
import 'package:mobile/service/api_service.dart';

/// Customer profile access. Administrator user-management actions remain in
/// UserManagementService so customer requests cannot invoke admin endpoints.
class UserService {
  final ApiService _api;

  UserService(this._api);

  Future<UserModel> getMyProfile() async {
    final response = await _api.get('${ApiConstant.users}/profile');
    if (response is! Map || response['user'] is! Map) {
      throw const FormatException('รูปแบบข้อมูลโปรไฟล์ไม่ถูกต้อง');
    }
    return UserModel.fromJson(
      Map<String, dynamic>.from(response['user'] as Map),
    );
  }
}
