import 'package:flutter_test/flutter_test.dart';
import 'package:entra_app/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const EntraApp());
    expect(find.byType(EntraApp), findsOneWidget);
  });
}
