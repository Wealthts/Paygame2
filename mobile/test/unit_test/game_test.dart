import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/controller/game_controller.dart';
import 'package:mobile/model/game_model.dart';

import '../support/fake_services.dart';

void main() {
  test('GameModel parses game fields from API JSON', () {
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

  group('GameController', () {
    late FakeGameService gameService;
    late GameController controller;

    setUp(() {
      gameService = FakeGameService();
      controller = GameController(gameService);
    });

    test('loadGames should get all games', () async {
      await controller.loadGames();
      expect(controller.games.length, 1);
      expect(controller.games.first.gameName, 'Arena Test');
      expect(controller.isLoading, isFalse);
    });

    test('createGame should add a new game', () async {
      final result = await controller.createGame({
        'game_name': 'New Game',
        'category': 'RPG',
        'uid_pattern': 'numeric',
        'requires_server': 0,
        'image_url': '',
        'is_active': 1,
      });

      expect(result, isTrue);
      expect(controller.games.length, 2);
      expect(controller.games.last.gameName, 'New Game');
    });

    test('updateGameStatus should change game status', () async {
      await controller.loadGames();
      final result = await controller.updateGameStatus(1, false);

      expect(result, isTrue);
      expect(controller.games.first.isActive, isFalse);
    });
  });
}
