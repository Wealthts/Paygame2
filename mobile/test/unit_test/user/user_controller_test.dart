import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mobile/controller/user_controller.dart';
import 'package:mobile/model/user_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/user_service.dart';

class MockUserService extends Mock implements UserService {}

void main() {
  late MockUserService mockService;
  late UserController controller;

  final sampleUser = UserModel(
    userId: 10,
    username: 'test_player',
    email: 'test@example.com',
    displayName: 'Test Player',
    role: 'user',
  );

  setUp(() {
    mockService = MockUserService();
    controller = UserController(mockService);
  });

  group('UserController', () {
    test('has expected initial state', () {
      expect(controller.profile, isNull);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('loadMyProfile loads user successfully and notifies listeners', () async {
      when(() => mockService.getMyProfile()).thenAnswer((_) async => sampleUser);

      final loadingStates = <bool>[];
      controller.addListener(() {
        loadingStates.add(controller.isLoading);
      });

      final success = await controller.loadMyProfile();

      expect(success, isTrue);
      expect(controller.profile, equals(sampleUser));
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
      expect(loadingStates, [true, false]);
      verify(() => mockService.getMyProfile()).called(1);
    });

    test('loadMyProfile sets errorMessage and returns false on failure', () async {
      when(() => mockService.getMyProfile()).thenThrow(
        const ApiException(statusCode: 500, message: 'Server error'),
      );

      final success = await controller.loadMyProfile();

      expect(success, isFalse);
      expect(controller.profile, isNull);
      expect(controller.errorMessage, 'Server error');
      expect(controller.isLoading, isFalse);
    });

    test('loadMyProfile ignores concurrent calls while already loading', () async {
      final completer = Completer<UserModel>();
      when(() => mockService.getMyProfile()).thenAnswer((_) => completer.future);

      final firstCall = controller.loadMyProfile();
      expect(controller.isLoading, isTrue);

      final secondResult = await controller.loadMyProfile();
      expect(secondResult, isFalse);

      completer.complete(sampleUser);
      final firstResult = await firstCall;

      expect(firstResult, isTrue);
      expect(controller.profile, equals(sampleUser));
      verify(() => mockService.getMyProfile()).called(1);
    });

    test('clear resets profile and errorMessage and notifies listeners', () async {
      when(() => mockService.getMyProfile()).thenAnswer((_) async => sampleUser);
      await controller.loadMyProfile();

      var notified = 0;
      controller.addListener(() => notified++);

      controller.clear();

      expect(controller.profile, isNull);
      expect(controller.errorMessage, isNull);
      expect(notified, 1);
    });
  });
}