import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/view/customer/point_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('points page shows current balance and point history', (tester) async {
    await tester.pumpWidget(
      Provider<PointService>(
        create: (_) => FakePointService(),
        child: const MaterialApp(home: CustomerPointView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1,250'), findsOneWidget);
    expect(find.text('ประวัติแต้มสะสม'), findsOneWidget);
    expect(find.text('+25'), findsNWidgets(2));
  });
}