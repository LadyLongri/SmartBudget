import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/widgets/feature_state_banner.dart';

void main() {
  testWidgets('renders state label, message and retry button', (
    WidgetTester tester,
  ) async {
    int retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeatureStateBanner(
            stateLabel: 'Erreur API',
            message: 'Impossible de charger',
            icon: Icons.error_outline_rounded,
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('feature_state_label')), findsOneWidget);
    expect(find.text('Erreur API'), findsOneWidget);
    expect(find.text('Impossible de charger'), findsOneWidget);
    expect(find.byKey(const Key('feature_state_retry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('feature_state_retry')));
    await tester.pump();

    expect(retries, 1);
  });
}
