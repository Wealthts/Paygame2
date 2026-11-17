import 'package:mobile/model/game_model.dart';
import 'package:mobile/service/api_service.dart';

class CustomerGameService {
  final ApiService api;

  CustomerGameService(this.api);

  static const String _endpoint = '/api/games';

  // ========================================
  // Get Active Games
  // ========================================
  Future<List<GameModel>> getActiveGames() async {
    final response = await api.get(_endpoint);

    if (response is! Map || response['games'] is! List) {
      throw const FormatException('Invalid games response from server');
    }

    final rawGames = response['games'] as List;

    return rawGames.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid game data');
      }

      return GameModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }
}
