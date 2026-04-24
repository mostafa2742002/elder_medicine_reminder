import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../repositories/medicine_repository.dart';
import '../utils/time_formatter.dart';
import 'add_medicine_screen.dart';

class MedicineManagementScreen extends StatefulWidget {
  const MedicineManagementScreen({super.key});

  @override
  State<MedicineManagementScreen> createState() =>
      _MedicineManagementScreenState();
}

class _MedicineManagementScreenState extends State<MedicineManagementScreen> {
  final medicineRepository = MedicineRepository();

  List<Medicine> medicines = [];

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

  void loadMedicines() {
    setState(() {
      medicines = medicineRepository.findAll();
    });
  }

  Future<void> openAddMedicineScreen() async {
    final medicineWasAdded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicineScreen(),
      ),
    );

    if (medicineWasAdded == true) {
      loadMedicines();
    }
  }

  Future<void> deleteMedicine(Medicine medicine) async {
    await medicineRepository.deleteById(medicine.id);
    loadMedicines();
  }

  @override
  Widget build(BuildContext context) {
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
                        '${medicine.dosage}\nمن الساعة ${TimeFormatter.formatHour12(medicine.startHour)} إلى ${TimeFormatter.formatHour12(medicine.endHour)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          deleteMedicine(medicine);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}