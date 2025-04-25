import 'package:flutter_test/flutter_test.dart';
import 'package:lavapp/main.dart';

void main() {
  testWidgets('App should display the Ticket List screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Ticket List'), findsOneWidget);
  });
}
