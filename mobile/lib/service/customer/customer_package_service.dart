import 'package:mobile/model/package_model.dart';
import 'package:mobile/service/api_service.dart';

class CustomerPackageService {
  final ApiService api;

  CustomerPackageService(this.api);

  static const String _endpoint = '/api/packages';

  // ========================================
  // Get Packages By Game
  // ========================================
  Future<List<PackageModel>> getPackagesByGame(int gameId) async {
    if (gameId <= 0) {
      throw ArgumentError('Invalid game ID');
    }

    final response = await api.get('$_endpoint?game_id=$gameId');

    // Backend คืนค่าเป็น Array โดยตรง
    if (response is! List) {
      throw const FormatException('Invalid packages response from server');
    }

    return response.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid package data');
      }

      return PackageModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }
}
