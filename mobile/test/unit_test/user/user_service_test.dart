import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mobile/core/api_constant.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/user_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;
  late UserService userService;

  setUp(() {
    mockApi = MockApiService();
    userService = UserService(mockApi);
  });

  group('UserService.getMyProfile', () {
    test('returns UserModel when API responds with valid user map', () async {
      when(() => mockApi.get('${ApiConstant.users}/profile')).thenAnswer(
        (_) async => {
          'user': {
            'user_id': 10,
            'username': 'test_player',
            'email': 'test@example.com',
            'display_name': 'Test Player',
            'role': 'user',
          },
        },
      );

      final result = await userService.getMyProfile();

      expect(result.userId, 10);
      expect(result.username, 'test_player');
      expect(result.email, 'test@example.com');
      expect(result.displayName, 'Test Player');
      expect(result.role, 'user');
      expect(result.isAdmin, isFalse);
      verify(() => mockApi.get('${ApiConstant.users}/profile')).called(1);
    });

    test('throws FormatException when response is not a Map', () async {
      when(
        () => mockApi.get('${ApiConstant.users}/profile'),
      ).thenAnswer((_) async => 'invalid-response');

      expect(
        () => userService.getMyProfile(),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when response["user"] is missing or not a Map', () async {
      when(
        () => mockApi.get('${ApiConstant.users}/profile'),
      ).thenAnswer((_) async => {'user': null});

      expect(
        () => userService.getMyProfile(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rethrows ApiException when API request fails', () async {
      when(() => mockApi.get('${ApiConstant.users}/profile')).thenThrow(
        const ApiException(statusCode: 401, message: 'กรุณาเข้าสู่ระบบก่อนใช้งาน'),
      );

      expect(
        () => userService.getMyProfile(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'กรุณาเข้าสู่ระบบก่อนใช้งาน'),
        ),
      );
    });
  });
}