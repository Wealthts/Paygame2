import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/package_model.dart';

void main() {
  test('PackageModel parses API package values safely', () {
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
    expect(package.price, 159.5);
    expect(package.isActive, isTrue);
    expect(package.requiresServer, isFalse);
    expect(package.toJson()['game_id'], 4);
  });
}
