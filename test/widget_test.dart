import 'package:elder_medicine_reminder/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ElderMedicineApp());

    expect(find.text('الآن'), findsOneWidget);
    expect(find.text('سجل الدواء'), findsOneWidget);
    expect(find.text('إدارة الأدوية'), findsOneWidget);
  });
}