import 'package:elder_medicine_reminder/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ElderMedicineApp());

    expect(find.text('تذكير الدواء'), findsOneWidget);
  });
}