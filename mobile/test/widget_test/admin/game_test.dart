import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/service/game_service.dart';
import 'package:mobile/view/admin/game_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('Admin game page displays games from service', (tester) async {
    final gameService = FakeGameService();

    await tester.pumpWidget(
      Provider<GameService>.value(
        value: gameService,
        child: const MaterialApp(home: GameView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Game Management'), findsOneWidget);
    expect(find.text('Games (1)'), findsOneWidget);
    expect(find.text('Arena Test'), findsOneWidget);
    expect(find.text('Category: MOBA'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('Admin game page opens add game form', (tester) async {
    await tester.pumpWidget(
      Provider<GameService>.value(
        value: FakeGameService(),
        child: const MaterialApp(home: GameView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Game'));
    await tester.pumpAndSettle();

    expect(find.text('Game Name'), findsOneWidget);
    expect(find.text('Create Game'), findsOneWidget);
  });
}
