import 'package:flutter_test/flutter_test.dart';
import 'package:permis_connect/main.dart';

void main() {
  testWidgets('PermisConnect app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PermisConnectApp());
    expect(find.byType(PermisConnectApp), findsOneWidget);
  });
}
