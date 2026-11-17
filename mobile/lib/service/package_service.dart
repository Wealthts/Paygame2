import 'package:mobile/model/package_model.dart';
import 'package:mobile/service/api_service.dart';

class PackageService {
  final ApiService api;

  PackageService(this.api);

  static const String _endpoint = '/api/admin/packages';

  // ========================================
  // Get All Packages
  // ========================================
  Future<List<PackageModel>> getAllPackages() async {
    final response = await api.get(_endpoint);

    if (response is! Map || response['packages'] is! List) {
      throw const FormatException('Invalid packages response from server');
    }

    final rawPackages = response['packages'] as List;

    return rawPackages.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid package data');
      }

      return PackageModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  // ========================================
  // Create Package
  // ========================================
  Future<void> createPackage(Map<String, dynamic> data) async {
    await api.post(_endpoint, body: data);
  }

  // ========================================
  // Update Package
  // ========================================
  Future<void> updatePackage(int packageId, Map<String, dynamic> data) async {
    await api.put('$_endpoint/$packageId', body: data);
  }

  // ========================================
  // Update Package Status
  // ========================================
  Future<void> updatePackageStatus(int packageId, bool isActive) async {
    await api.patch(
      '$_endpoint/$packageId/status',
      body: {'is_active': isActive ? 1 : 0},
    );
  }
}
