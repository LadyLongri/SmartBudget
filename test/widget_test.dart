import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/main.dart';

void main() {
  testWidgets('renders welcome after splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const SmartBudgetApp(splashDelay: Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(find.text('SB'), findsWidgets);
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text("Entrer dans l'application"), findsOneWidget);
  });
}
