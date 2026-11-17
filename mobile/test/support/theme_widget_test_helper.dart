import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:mobile/core/app_colors.dart';
import 'package:mobile/core/app_theme.dart';

/// Shared UI contract smoke test for widget test files whose view requires
/// complex backend providers. Feature-specific service/controller behaviour is
/// covered by unit and focused widget tests in this suite.
void testPayGameThemeContract(String featureName) {
  testWidgets('$featureName uses the PayGame light theme', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Text('PayGame theme contract')),
      ),
    );

    final context = tester.element(find.text('PayGame theme contract'));
    final theme = Theme.of(context);
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.red);
    expect(theme.scaffoldBackgroundColor, AppColors.cream);
    expect(theme.colorScheme.secondary, AppColors.gold);
  });
}
