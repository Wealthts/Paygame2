import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/game_model.dart';

void main() {
  test('GameModel parses game fields and boolean flags from API JSON', () {
    final game = GameModel.fromJson({
      'game_id': '12',
      'game_name': 'Arena Test',
      'category': 'MOBA',
      'uid_pattern': 'numeric',
      'requires_server': 1,
      'image_url': 'https://example.com/game.png',
      'is_active': '1',
    });

    expect(game.gameId, 12);
    expect(game.gameName, 'Arena Test');
    expect(game.category, 'MOBA');
    expect(game.requiresServer, isTrue);
    expect(game.isActive, isTrue);
    expect(game.toJson()['requires_server'], 1);
  });
}
