import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/main.dart';

void main() {
  testWidgets('renders CRUD auth actions', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBudgetApp());

    expect(find.text('SmartBudget CRUD'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Tester /health'), findsOneWidget);
    expect(find.text('Tester /me'), findsOneWidget);
  });
}
