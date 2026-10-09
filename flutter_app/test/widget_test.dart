import 'package:flutter_test/flutter_test.dart';
import 'package:mybazaar_app/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyBazaarApp());
    expect(find.text('MyBazaar'), findsOneWidget);
  });
}
