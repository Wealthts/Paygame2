import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/service/game_service.dart';
import 'package:mobile/service/package_service.dart';
import 'package:mobile/view/admin/package_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('Admin package page displays packages from service', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PackageService>.value(value: FakePackageService()),
          Provider<GameService>.value(value: FakeGameService()),
        ],
        child: const MaterialApp(home: PackageView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Package Management'), findsOneWidget);
    expect(find.text('Packages (1)'), findsOneWidget);
    expect(find.text('500 Diamonds'), findsOneWidget);
    expect(find.text('฿159.00'), findsOneWidget);
  });

  testWidgets('Admin package page opens add package form', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PackageService>.value(value: FakePackageService()),
          Provider<GameService>.value(value: FakeGameService()),
        ],
        child: const MaterialApp(home: PackageView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Package'));
    await tester.pumpAndSettle();

    expect(find.text('Package Name'), findsOneWidget);
    expect(find.text('Price (Baht)'), findsOneWidget);
    expect(find.text('Create Package'), findsOneWidget);
  });
}
