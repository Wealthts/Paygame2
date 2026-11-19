import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mobile/service/admin/user_management_service.dart';
import 'package:mobile/service/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;
  late UserManagementService service;

  setUp(() {
    mockApi = MockApiService();
    service = UserManagementService(mockApi);
  });

  group('UserManagementService.getAllUsers', () {
    test('returns list of AdminUserModel when API responds with valid users list', () async {
      when(() => mockApi.get('/api/admin/users/all')).thenAnswer(
        (_) async => {
          'users': [
            {
              'user_id': 1,
              'username': 'admin',
              'email': 'admin@paygame.com',
              'display_name': 'System Admin',
              'role': 'admin',
              'is_active': 1,
              'created_at': '2026-01-01T00:00:00.000Z',
            },
            {
              'user_id': 2,
              'username': 'gamer01',
              'email': 'gamer01@example.com',
              'display_name': 'Gamer 01',
              'role': 'user',
              'is_active': 0,
              'created_at': '2026-02-01T00:00:00.000Z',
            },
          ],
        },
      );

      final result = await service.getAllUsers();

      expect(result, hasLength(2));
      expect(result[0].username, 'admin');
      expect(result[0].isActive, isTrue);
      expect(result[1].username, 'gamer01');
      expect(result[1].isActive, isFalse);
      verify(() => mockApi.get('/api/admin/users/all')).called(1);
    });

    test('throws FormatException when response is not a Map or users is not a List', () async {
      when(
        () => mockApi.get('/api/admin/users/all'),
      ).thenAnswer((_) async => {'users': 'not-a-list'});

      expect(
        () => service.getAllUsers(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('UserManagementService.getUserDetails', () {
    test('returns UserDetailsModel when API responds with valid map', () async {
      when(() => mockApi.get('/api/admin/users/10/details')).thenAnswer(
        (_) async => {
          'user': {
            'user_id': 10,
            'username': 'player10',
            'email': 'p10@example.com',
            'display_name': 'Player 10',
            'role': 'user',
            'is_active': 1,
            'created_at': '2026-05-01T10:00:00.000Z',
          },
          'summary': {
            'order_count': 2,
            'payment_count': 2,
            'paid_amount': 300.0,
            'point_balance': 50,
            'receipt_count': 2,
            'coupon_count': 1,
          },
          'orders': [],
          'payments': [],
          'point_transactions': [],
          'receipts': [],
          'user_coupons': [],
        },
      );

      final details = await service.getUserDetails(10);

      expect(details.user.userId, 10);
      expect(details.paidAmount, 300.0);
      expect(details.pointBalance, 50);
      verify(() => mockApi.get('/api/admin/users/10/details')).called(1);
    });

    test('throws FormatException when response is not a Map', () async {
      when(
        () => mockApi.get('/api/admin/users/10/details'),
      ).thenAnswer((_) async => ['invalid']);

      expect(
        () => service.getUserDetails(10),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('UserManagementService.updateUserStatus', () {
    test('sends PATCH with is_active = 1 when enabling user', () async {
      when(
        () => mockApi.patch('/api/admin/users/7/status', body: {'is_active': 1}),
      ).thenAnswer((_) async => {'message': 'Updated'});

      await service.updateUserStatus(userId: 7, isActive: true);

      verify(
        () => mockApi.patch('/api/admin/users/7/status', body: {'is_active': 1}),
      ).called(1);
    });

    test('sends PATCH with is_active = 0 when disabling user', () async {
      when(
        () => mockApi.patch('/api/admin/users/7/status', body: {'is_active': 0}),
      ).thenAnswer((_) async => {'message': 'Updated'});

      await service.updateUserStatus(userId: 7, isActive: false);

      verify(
        () => mockApi.patch('/api/admin/users/7/status', body: {'is_active': 0}),
      ).called(1);
    });
  });
}