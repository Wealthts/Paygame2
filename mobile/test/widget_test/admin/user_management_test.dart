import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/admin/user_admin_model.dart';
import 'package:mobile/model/admin/user_details_model.dart';
import 'package:mobile/service/admin/user_management_service.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/view/admin/user_management_view.dart';

class MockUserManagementService extends Mock
    implements UserManagementService {}

const alice = AdminUserModel(
  userId: 1,
  username: 'alice',
  email: 'alice@example.com',
  displayName: 'Alice',
  role: 'user',
  isActive: true,
  createdAt: '2026-11-10T22:59:11.000Z',
);

const bob = AdminUserModel(
  userId: 2,
  username: 'bob',
  email: 'bob@example.com',
  displayName: 'Bob',
  role: 'user',
  isActive: false,
  createdAt: '2026-11-14 09:56:41',
);

const root = AdminUserModel(
  userId: 3,
  username: 'root',
  email: 'root@example.com',
  displayName: 'Root',
  role: 'admin',
  isActive: true,
  createdAt: '2026-11-01 08:00:00',
);

UserDetailsModel makeDetails(int userId) => UserDetailsModel.fromJson({
  'user': {
    'user_id': userId,
    'username': 'alice',
    'email': 'alice@example.com',
    'display_name': 'Alice',
    'role': 'user',
    'is_active': 1,
    'created_at': '2026-11-10 22:59:11',
  },
  'summary': <String, dynamic>{},
});

/// Runs a widget test on a tall screen (so the whole lazy ListView is built)
/// and always disposes the widget tree at the end, which cancels timers and
/// SnackBars that would otherwise be reported as still pending.
void testView(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await body(tester);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> pumpView(
  WidgetTester tester,
  UserManagementService service,
) async {
  await tester.pumpWidget(
    Provider<UserManagementService>.value(
      value: service,
      child: const MaterialApp(home: UserManagementView()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> tapChip(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ChoiceChip, label));
  await tester.pump();
}

void main() {
  late MockUserManagementService service;

  setUp(() {
    service = MockUserManagementService();
  });

  void stubUsers(List<AdminUserModel> users) {
    when(() => service.getAllUsers()).thenAnswer((_) async => users);
  }

  group('loading and display', () {
    testView('shows a progress indicator while users are loading', (
      tester,
    ) async {
      final completer = Completer<List<AdminUserModel>>();
      when(() => service.getAllUsers()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        Provider<UserManagementService>.value(
          value: service,
          child: const MaterialApp(home: UserManagementView()),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Alice'), findsNothing);

      completer.complete([alice]);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
    });

    testView('shows summary counters for total, active and inactive', (
      tester,
    ) async {
      stubUsers([alice, bob, root]);
      await pumpView(tester, service);

      expect(find.text('สมาชิกทั้งหมด'), findsOneWidget);
      expect(find.text('ใช้งานอยู่'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // total
      expect(find.text('2'), findsOneWidget); // active
      expect(find.text('1'), findsOneWidget); // inactive
      expect(find.text('3 / 3 บัญชี'), findsOneWidget);
    });

    testView('shows every user card with profile information', (tester) async {
      stubUsers([alice, bob, root]);
      await pumpView(tester, service);

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('@alice'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.text('User ID: 1'), findsOneWidget);
      expect(find.text('ประเภท: สมาชิก'), findsNWidgets(2));
      expect(find.text('ประเภท: ผู้ดูแลระบบ'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Root'), findsOneWidget);
    });

    testView('formats the registration date without T and milliseconds', (
      tester,
    ) async {
      stubUsers([alice]);
      await pumpView(tester, service);

      expect(find.text('สมัครเมื่อ: 2026-11-10 22:59:11'), findsOneWidget);
    });

    testView('shows a dash when the registration date is missing', (
      tester,
    ) async {
      stubUsers([
        const AdminUserModel(
          userId: 9,
          username: 'nodate',
          email: 'n@example.com',
          displayName: 'No Date',
          role: 'user',
          isActive: true,
          createdAt: '',
        ),
      ]);
      await pumpView(tester, service);

      expect(find.text('สมัครเมื่อ: -'), findsOneWidget);
    });

    testView('shows account status text for active and inactive users', (
      tester,
    ) async {
      stubUsers([alice, bob, root]);
      await pumpView(tester, service);

      expect(find.text('บัญชีกำลังใช้งาน'), findsNWidgets(2));
      expect(find.text('บัญชีถูกปิดใช้งาน'), findsOneWidget);
    });

    testView('shows an empty state when there are no members', (tester) async {
      stubUsers([]);
      await pumpView(tester, service);

      expect(find.text('ยังไม่มีสมาชิกในระบบ'), findsOneWidget);
      expect(find.text('0 / 0 บัญชี'), findsOneWidget);
    });

    testView('shows the error with a retry button, then recovers', (
      tester,
    ) async {
      var calls = 0;
      when(() => service.getAllUsers()).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          throw const ApiException(statusCode: 500, message: 'Server error');
        }
        return [alice];
      });

      await pumpView(tester, service);

      expect(find.text('Server error'), findsOneWidget);
      expect(find.text('ลองอีกครั้ง'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);

      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();

      expect(find.text('Server error'), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
    });
  });

  group('search', () {
    setUp(() => stubUsers([alice, bob, root]));

    testView('filters by username', (tester) async {
      await pumpView(tester, service);
      await search(tester, 'bob');

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Root'), findsNothing);
      expect(find.text('1 / 3 บัญชี'), findsOneWidget);
    });

    testView('is case-insensitive', (tester) async {
      await pumpView(tester, service);
      await search(tester, 'ALICE');

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
    });

    testView('filters by email', (tester) async {
      await pumpView(tester, service);
      await search(tester, 'root@example');

      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
    });

    testView('filters by role label', (tester) async {
      await pumpView(tester, service);
      await search(tester, 'ผู้ดูแล');

      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsNothing);
    });

    testView('shows a message when nothing matches', (tester) async {
      await pumpView(tester, service);
      await search(tester, 'no-such-user');

      expect(find.text('ไม่พบสมาชิกที่ตรงกับเงื่อนไข'), findsOneWidget);
      expect(find.text('0 / 3 บัญชี'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
    });

    testView('clear button resets the search text', (tester) async {
      await pumpView(tester, service);
      await search(tester, 'bob');
      expect(find.text('Alice'), findsNothing);

      await tester.tap(find.byTooltip('ล้างคำค้นหา'));
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('3 / 3 บัญชี'), findsOneWidget);
    });
  });

  group('filters', () {
    setUp(() => stubUsers([alice, bob, root]));

    testView('status filter shows only active accounts', (tester) async {
      await pumpView(tester, service);
      await tapChip(tester, 'กำลังใช้งาน');

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      expect(find.text('2 / 3 บัญชี'), findsOneWidget);
    });

    testView('status filter shows only inactive accounts', (tester) async {
      await pumpView(tester, service);
      await tapChip(tester, 'ปิดใช้งาน');

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Root'), findsNothing);
      expect(find.text('1 / 3 บัญชี'), findsOneWidget);
    });

    testView('role filter shows only admins', (tester) async {
      await pumpView(tester, service);
      await tapChip(tester, 'ผู้ดูแลระบบ');

      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsNothing);
    });

    testView('role filter shows only members', (tester) async {
      await pumpView(tester, service);
      await tapChip(tester, 'สมาชิก');

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Root'), findsNothing);
    });

    testView('status and role filters combine', (tester) async {
      await pumpView(tester, service);
      await tapChip(tester, 'กำลังใช้งาน');
      await tapChip(tester, 'สมาชิก');

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      expect(find.text('Root'), findsNothing);
      expect(find.text('1 / 3 บัญชี'), findsOneWidget);
    });

    testView('reset button clears search, status and role filters', (
      tester,
    ) async {
      await pumpView(tester, service);
      await search(tester, 'alice');
      await tapChip(tester, 'ปิดใช้งาน');
      expect(find.text('ไม่พบสมาชิกที่ตรงกับเงื่อนไข'), findsOneWidget);

      await tester.tap(find.text('ล้างตัวกรองทั้งหมด'));
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Root'), findsOneWidget);
      expect(find.text('3 / 3 บัญชี'), findsOneWidget);
    });
  });

  group('changing account status', () {
    late List<AdminUserModel> current;

    setUp(() {
      current = [alice, bob, root];
      when(() => service.getAllUsers()).thenAnswer((_) async => current);
    });

    Switch switchAt(WidgetTester tester, int index) =>
        tester.widget<Switch>(find.byType(Switch).at(index));

    testView('switches reflect each account status', (tester) async {
      await pumpView(tester, service);

      expect(switchAt(tester, 0).value, isTrue); // Alice
      expect(switchAt(tester, 1).value, isFalse); // Bob
      expect(switchAt(tester, 2).value, isTrue); // Root
    });

    testView('admin account switch is disabled', (tester) async {
      await pumpView(tester, service);

      expect(switchAt(tester, 0).onChanged, isNotNull);
      expect(switchAt(tester, 1).onChanged, isNotNull);
      expect(switchAt(tester, 2).onChanged, isNull);
    });

    testView('enabling a member asks for confirmation and updates', (
      tester,
    ) async {
      when(
        () => service.updateUserStatus(userId: 2, isActive: true),
      ).thenAnswer((_) async {
        current = [alice, bob.copyActive(true), root];
      });

      await pumpView(tester, service);
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();

      expect(find.text('เปิดใช้งานบัญชีสมาชิก'), findsOneWidget);
      expect(find.textContaining('Bob (@bob)'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'เปิดใช้งาน'));
      await tester.pumpAndSettle();

      verify(
        () => service.updateUserStatus(userId: 2, isActive: true),
      ).called(1);
      expect(find.text('เปิดใช้งานบัญชีเรียบร้อยแล้ว'), findsOneWidget);
      expect(switchAt(tester, 1).value, isTrue);
      expect(find.text('บัญชีถูกปิดใช้งาน'), findsNothing);
    });

    testView('disabling a member asks for confirmation and updates', (
      tester,
    ) async {
      when(
        () => service.updateUserStatus(userId: 1, isActive: false),
      ).thenAnswer((_) async {
        current = [alice.copyActive(false), bob, root];
      });

      await pumpView(tester, service);
      await tester.tap(find.byType(Switch).at(0));
      await tester.pumpAndSettle();

      expect(find.text('ปิดใช้งานบัญชีสมาชิก'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'ปิดใช้งาน'));
      await tester.pumpAndSettle();

      verify(
        () => service.updateUserStatus(userId: 1, isActive: false),
      ).called(1);
      expect(find.text('ปิดใช้งานบัญชีเรียบร้อยแล้ว'), findsOneWidget);
      expect(find.text('บัญชีถูกปิดใช้งาน'), findsNWidgets(2));
    });

    testView('cancelling the dialog does not call the API', (tester) async {
      await pumpView(tester, service);
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();

      verifyNever(
        () => service.updateUserStatus(
          userId: any(named: 'userId'),
          isActive: any(named: 'isActive'),
        ),
      );
      expect(switchAt(tester, 1).value, isFalse);
    });

    testView('shows an error message when the update fails', (tester) async {
      when(
        () => service.updateUserStatus(userId: 2, isActive: true),
      ).thenThrow(
        const ApiException(statusCode: 400, message: 'Cannot update'),
      );

      await pumpView(tester, service);
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'เปิดใช้งาน'));
      await tester.pumpAndSettle();

      expect(
        find.text('เปลี่ยนสถานะบัญชีไม่สำเร็จ: Cannot update'),
        findsOneWidget,
      );
      expect(switchAt(tester, 1).value, isFalse);
    });

    testView('disables the switch of a user while it is being updated', (
      tester,
    ) async {
      final completer = Completer<void>();
      when(
        () => service.updateUserStatus(userId: 2, isActive: true),
      ).thenAnswer((_) => completer.future);

      await pumpView(tester, service);
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'เปิดใช้งาน'));
      await tester.pump();

      expect(switchAt(tester, 1).onChanged, isNull); // Bob is updating
      expect(switchAt(tester, 0).onChanged, isNotNull); // Alice is not

      completer.complete();
      await tester.pumpAndSettle();

      expect(switchAt(tester, 1).onChanged, isNotNull);
    });
  });

  group('navigation', () {
    testView('opens the user details page for the selected user', (
      tester,
    ) async {
      stubUsers([alice]);
      when(
        () => service.getUserDetails(1),
      ).thenAnswer((_) async => makeDetails(1));

      await pumpView(tester, service);
      await tester.tap(find.text('ดูรายละเอียดและประวัติ'));
      await tester.pumpAndSettle();

      expect(find.text('รายละเอียดสมาชิก'), findsOneWidget);
      verify(() => service.getUserDetails(1)).called(1);
    });
  });
}

extension on AdminUserModel {
  AdminUserModel copyActive(bool isActive) => AdminUserModel(
    userId: userId,
    username: username,
    email: email,
    displayName: displayName,
    role: role,
    isActive: isActive,
    createdAt: createdAt,
  );
}