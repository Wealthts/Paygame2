import 'package:mobile/model/point_model.dart';
import 'package:mobile/service/api_service.dart';

class PointService {
  final ApiService _apiService;

  PointService(this._apiService);

  static const String _endpoint = '/api/points';

  Future<List<PointModel>> getAllTransactions() async {
    final response = await _apiService.get('$_endpoint/all');

    if (response is! Map) {
      throw const FormatException('Invalid point history format');
    }

    final data = Map<String, dynamic>.from(response);
    final transactions = data['transactions'];

    if (transactions is! List) {
      throw const FormatException('Point history not found');
    }

    return transactions.map((item) {
      return PointModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  // ========================================
  // Get My Points (Customer)
  // ========================================
  Future<int> getMyPoints() async {
    final response = await _apiService.get('$_endpoint/my-points');

    if (response is! Map || response['total_points'] == null) {
      throw const FormatException('Invalid points balance format');
    }

    final totalPoints = int.tryParse(response['total_points'].toString());

    if (totalPoints == null) {
      throw const FormatException('Could not read points balance');
    }

    return totalPoints;
  }

  // ========================================
  // Get My Point History (Customer)
  // ========================================
  Future<List<PointModel>> getMyPointHistory() async {
    final response = await _apiService.get('$_endpoint/history');

    if (response is! Map || response['history'] is! List) {
      throw const FormatException('Invalid point history format');
    }

    final history = response['history'] as List;

    return history.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid point history data');
      }

      return PointModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<void> addPoints({
    required int userId,
    required int points,
    required String eventKey,
  }) async {
    await _apiService.post(
      _endpoint,
      body: {
        'user_id': userId,
        'event_key': eventKey,
        'type': 'Earn',
        'points_delta': points,
      },
    );
  }
}
