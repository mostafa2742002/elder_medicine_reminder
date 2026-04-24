import 'package:flutter/material.dart';

import '../data/fake_history.dart';
import '../models/medicine_history.dart';
import '../models/medicine_status.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String getStatusText(MedicineStatus status) {
    switch (status) {
      case MedicineStatus.pending:
        return 'في الانتظار ⏳';
      case MedicineStatus.taken:
        return 'تم أخذه ✅';
      case MedicineStatus.missed:
        return 'لم يتم أخذه ❌';
    }
  }

  IconData getStatusIcon(MedicineStatus status) {
    switch (status) {
      case MedicineStatus.pending:
        return Icons.hourglass_bottom;
      case MedicineStatus.taken:
        return Icons.check_circle;
      case MedicineStatus.missed:
        return Icons.cancel;
    }
  }

  String getTakenTimeText(MedicineHistory history) {
    if (history.takenAt == null) {
      return '';
    }

    final hour = history.takenAt!.hour.toString().padLeft(2, '0');
    final minute = history.takenAt!.minute.toString().padLeft(2, '0');

    return 'الساعة $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الدواء'),
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fakeHistory.length,
          itemBuilder: (context, index) {
            final history = fakeHistory[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Icon(
                  getStatusIcon(history.status),
                  size: 42,
                ),
                title: Text(
                  history.medicineName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${getStatusText(history.status)}\n${getTakenTimeText(history)}',
                  style: const TextStyle(fontSize: 19),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}