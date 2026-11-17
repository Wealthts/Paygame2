import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/user_model.dart';

void main() {
  group('UserModel', () {
    test('parses a customer record and serializes API keys', () {
      final user = UserModel.fromJson({
        'user_id': '21',
        'username': 'gamer21',
        'email': 'gamer@example.com',
        'display_name': 'Gamer',
        'role': 'user',
      });

      expect(user.userId, 21);
      expect(user.isAdmin, isFalse);
      expect(user.toJson()['display_name'], 'Gamer');
    });

    test('recognizes admin role', () {
      final user = UserModel.fromJson({
        'user_id': 1,
        'username': 'admin',
        'role': 'admin',
      });
      expect(user.isAdmin, isTrue);
    });

    test('throws for an invalid user id', () {
      expect(
        () => UserModel.fromJson({'username': 'missing-id'}),
        throwsFormatException,
      );
    });
  });
}
