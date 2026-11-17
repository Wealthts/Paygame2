import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/validator.dart';

void main() {
  group('AppValidator authentication', () {
    test('accepts a valid username', () {
      expect(AppValidator.username('player_01'), isNull);
    });

    test('rejects username with spaces and short username', () {
      expect(AppValidator.username('player one'), isNotNull);
      expect(AppValidator.username('ab'), isNotNull);
    });

    test('validates email syntax', () {
      expect(AppValidator.email('player@example.com'), isNull);
      expect(AppValidator.email('player@'), isNotNull);
    });

    test('enforces password length', () {
      expect(AppValidator.password('12345678'), isNull);
      expect(AppValidator.password('1234567'), isNotNull);
    });

    test('checks password confirmation', () {
      expect(
        AppValidator.confirmPassword(
          'same-password',
          passwordValue: 'same-password',
        ),
        isNull,
      );
      expect(
        AppValidator.confirmPassword(
          'different',
          passwordValue: 'same-password',
        ),
        isNotNull,
      );
    });
  });
}
