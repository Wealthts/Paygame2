import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mobile/controller/admin/user_management_controller.dart';
import 'package:mobile/model/admin/user_admin_model.dart';
import 'package:mobile/service/admin/user_management_service.dart';
import 'package:mobile/service/api_service.dart';

class MockUserManagementService extends Mock implements UserManagementService {}

void main() {
  late MockUserManagementService mockService;
  late UserManagementController controller;

  final sampleUsers = [
    const AdminUserModel(
      userId: 1,
      username: 'admin',
      email: 'admin@example.com',
      displayName: 'Admin',
      role: 'admin',
      isActive: true,
      createdAt: '2026-01-01',
    ),
    const AdminUserModel(
      userId: 2,
      username: 'member_active',
      email: 'active@example.com',
      displayName: 'Active Member',
      role: 'user',
      isActive: true,
      createdAt: '2026-01-02',
    ),
    const AdminUserModel(
      userId: 3,
      username: 'member_inactive',
      email: 'inactive@example.com',
      displayName: 'Inactive Member',
      role: 'user',
      isActive: false,
      createdAt: '2026-01-03',
    ),
  ];

  setUp(() {
    mockService = MockUserManagementService();
    controller = UserManagementController(mockService);
  });

  group('UserManagementController', () {
    test('initial state and summary getters are empty', () {
      expect(controller.users, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.totalUsers, 0);
      expect(controller.activeUsers, 0);
      expect(controller.inactiveUsers, 0);
    });

    test('loadUsers populates users and updates summary counts', () async {
      when(() => mockService.getAllUsers()).thenAnswer((_) async => sampleUsers);

      final loadingStates = <bool>[];
      controller.addListener(() {
        loadingStates.add(controller.isLoading);
      });

      await controller.loadUsers();

      expect(controller.users, hasLength(3));
      expect(controller.totalUsers, 3);
      expect(controller.activeUsers, 2);
      expect(controller.inactiveUsers, 1);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
      expect(loadingStates, [true, false]);
      verify(() => mockService.getAllUsers()).called(1);
    });

    test('loadUsers with showLoading: false does not toggle isLoading to true', () async {
      when(() => mockService.getAllUsers()).thenAnswer((_) async => sampleUsers);

      final loadingStates = <bool>[];
      controller.addListener(() {
        loadingStates.add(controller.isLoading);
      });

      await controller.loadUsers(showLoading: false);

      expect(loadingStates, [false]);
      expect(controller.users, hasLength(3));
    });

    test('loadUsers sets errorMessage when service throws', () async {
      when(() => mockService.getAllUsers()).thenThrow(
        const ApiException(statusCode: 500, message: 'Failed to load users'),
      );

      await controller.loadUsers();

      expect(controller.users, isEmpty);
      expect(controller.errorMessage, 'Failed to load users');
      expect(controller.isLoading, isFalse);
    });

    test('updateUserStatus updates status, reloads users silently, and clears updatingUserIds', () async {
      when(
        () => mockService.updateUserStatus(userId: 2, isActive: false),
      ).thenAnswer((_) async {});
      when(() => mockService.getAllUsers()).thenAnswer((_) async => sampleUsers);

      await controller.updateUserStatus(userId: 2, isActive: false);

      expect(controller.isUpdating(2), isFalse);
      expect(controller.updatingUserIds, isEmpty);
      expect(controller.errorMessage, isNull);
      verify(() => mockService.updateUserStatus(userId: 2, isActive: false)).called(1);
      verify(() => mockService.getAllUsers()).called(1);
    });

    test('updateUserStatus ignores duplicate concurrent calls for the same userId', () async {
      final completer = Completer<void>();
      when(
        () => mockService.updateUserStatus(userId: 2, isActive: false),
      ).thenAnswer((_) => completer.future);
      when(() => mockService.getAllUsers()).thenAnswer((_) async => sampleUsers);

      final firstCall = controller.updateUserStatus(userId: 2, isActive: false);
      expect(controller.isUpdating(2), isTrue);

      // เรียกซ้ำขณะ userId: 2 กำลังอัปเดตอยู่ ต้องถูกข้าม
      await controller.updateUserStatus(userId: 2, isActive: false);

      completer.complete();
      await firstCall;

      expect(controller.isUpdating(2), isFalse);
      verify(() => mockService.updateUserStatus(userId: 2, isActive: false)).called(1);
    });

    test('updateUserStatus sets errorMessage, clears updating state, and rethrows on failure', () async {
      when(
        () => mockService.updateUserStatus(userId: 3, isActive: true),
      ).thenThrow(
        const ApiException(statusCode: 403, message: 'Forbidden'),
      );

      await expectLater(
        controller.updateUserStatus(userId: 3, isActive: true),
        throwsA(isA<ApiException>()),
      );

      expect(controller.errorMessage, 'Forbidden');
      expect(controller.isUpdating(3), isFalse);
      verifyNever(() => mockService.getAllUsers());
    });
  });
}