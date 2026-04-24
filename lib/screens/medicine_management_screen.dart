import 'package:flutter/material.dart';

import '../data/app_store.dart';

class MedicineManagementScreen extends StatelessWidget {
  const MedicineManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الأدوية'),
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: AppStore.medicines.length,
          itemBuilder: (context, index) {
            final medicine = AppStore.medicines[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(
                  Icons.medication,
                  size: 40,
                ),
                title: Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${medicine.dosage}\nمن الساعة ${medicine.startHour} إلى ${medicine.endHour}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}