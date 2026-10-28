import 'package:flutter_test/flutter_test.dart';
import 'package:samu_localizador/main.dart';

void main() {
  testWidgets('Teste basico de carregamento', (WidgetTester tester) async {
    await tester.pumpWidget(const AppSamu());
    expect(find.byType(AppSamu), findsOneWidget);
  });
}
