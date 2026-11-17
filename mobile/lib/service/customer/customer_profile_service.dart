import 'package:mobile/model/user_model.dart';
import 'package:mobile/service/api_service.dart';

class CustomerProfileService {
  final ApiService api;

  CustomerProfileService(this.api);

  // ========================================
  // Get My Profile
  // ========================================
  Future<UserModel> getMyProfile() async {
    final response = await api.get('/api/users/profile');

    if (response is! Map || response['user'] is! Map) {
      throw const FormatException('รูปแบบข้อมูลโปรไฟล์ไม่ถูกต้อง');
    }

    return UserModel.fromJson(
      Map<String, dynamic>.from(response['user'] as Map),
    );
  }
}
