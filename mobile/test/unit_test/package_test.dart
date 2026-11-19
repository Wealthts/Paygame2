import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/controller/package_controller.dart';
import 'package:mobile/model/package_model.dart';

import '../support/fake_services.dart';


void main() {
  test('PackageModel parses package values from API JSON', () {
    final package = PackageModel.fromJson({
      'package_id': '2',
      'game_id': '4',
      'package_name': '500 Diamonds',
      'game_name': 'Game B',
      'price': '159.50',
      'is_active': 1,
      'requires_server': '0',
    });

    expect(package.packageId, 2);
    expect(package.gameId, 4);
    expect(package.packageName, '500 Diamonds');
    expect(package.price, 159.5);
    expect(package.isActive, isTrue);
    expect(package.requiresServer, isFalse);
    expect(package.toJson()['game_id'], 4);
  });

  group('PackageController', () {
    late FakePackageService packageService;
    late FakeGameService gameService;
    late PackageController controller;

    setUp(() {
      packageService = FakePackageService();
      gameService = FakeGameService();
      controller = PackageController(packageService, gameService);
    });

    test('loadData should get packages and games', () async {
      await controller.loadData();
      expect(controller.packages.length, 1);
      expect(controller.packages.first.packageName, '500 Diamonds');
      expect(controller.games.length, 1);
      expect(controller.isLoading, isFalse);
    });

    test('createPackage should add a new package', () async {
      final result = await controller.createPackage({
        'game_id': 1,
        'package_name': '1000 Diamonds',
        'price': 299.0,
        'is_active': 1,
      });

      expect(result, isTrue);
      expect(controller.packages.length, 2);
      expect(controller.packages.last.packageName, '1000 Diamonds');
      expect(controller.packages.last.price, 299.0);
    });

    test('updatePackageStatus should change package status', () async {
      await controller.loadData();
      final result = await controller.updatePackageStatus(2, false);

      expect(result, isTrue);
      expect(controller.packages.first.isActive, isFalse);
    });
  });
}
