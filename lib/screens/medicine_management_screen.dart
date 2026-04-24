import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'add_medicine_screen.dart';

class MedicineManagementScreen extends StatefulWidget {
  const MedicineManagementScreen({super.key});

  @override
  State<MedicineManagementScreen> createState() =>
      _MedicineManagementScreenState();
}

class _MedicineManagementScreenState extends State<MedicineManagementScreen> {
  
  String formatHour12(int hour24) {
  final period = hour24 < 12 ? 'صباحًا' : 'مساءً';

  var hour12 = hour24 % 12;

  if (hour12 == 0) {
    hour12 = 12;
  }

  return '$hour12 $period';
  }

  Future<void> openAddMedicineScreen() async {
    final medicineWasAdded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicineScreen(),
      ),
    );

    if (medicineWasAdded == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicines = AppStore.medicines;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الأدوية'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAddMedicineScreen,
          icon: const Icon(Icons.add),
          label: const Text(
            'إضافة دواء',
            style: TextStyle(fontSize: 18),
          ),
        ),
        body: medicines.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد أدوية حتى الآن',
                  style: TextStyle(fontSize: 26),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final medicine = medicines[index];

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
                        '${medicine.dosage}\nمن الساعة ${formatHour12(medicine.startHour)} إلى ${formatHour12(medicine.endHour)}',
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