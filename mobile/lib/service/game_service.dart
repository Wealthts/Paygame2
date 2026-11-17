import 'package:mobile/model/game_model.dart';
import 'package:mobile/service/api_service.dart';

class GameService {
  final ApiService api;

  GameService(this.api);

  static const String _endpoint = '/api/admin/games';

  // ========================================
  // Get All Games
  // ========================================
  Future<List<GameModel>> getAllGames() async {
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

  // ========================================
  // Create Game
  // ========================================
  Future<void> createGame(Map<String, dynamic> data) async {
    await api.post(_endpoint, body: data);
  }

  // ========================================
  // Update Game
  // ========================================
  Future<void> updateGame(int gameId, Map<String, dynamic> data) async {
    await api.put('$_endpoint/$gameId', body: data);
  }

  // ========================================
  // Update Game Status
  // ========================================
  Future<void> updateGameStatus(int gameId, bool isActive) async {
    await api.patch(
      '$_endpoint/$gameId/status',
      body: {'is_active': isActive ? 1 : 0},
    );
  }
}
