import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/medicine.dart';

class NowScreen extends StatefulWidget {
  const NowScreen({super.key});

  @override
  State<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends State<NowScreen> {
  final Set<String> takenMedicineIds = {};

  List<Medicine> getActiveMedicines() {
    final currentHour = DateTime.now().hour;

    return AppStore.medicines.where((medicine) {
      final isInsideTimeRange =
          currentHour >= medicine.startHour && currentHour < medicine.endHour;

      final isNotTakenYet = !takenMedicineIds.contains(medicine.id);

      return isInsideTimeRange && isNotTakenYet;
    }).toList();
  }

  void markMedicineAsTaken(Medicine medicine) {
    setState(() {
      takenMedicineIds.add(medicine.id);
      AppStore.markMedicineAsTaken(medicine);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeMedicines = getActiveMedicines();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('أدوية الآن'),
          centerTitle: true,
        ),
        body: activeMedicines.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا يوجد دواء في الوقت الحالي',
                    style: TextStyle(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeMedicines.length,
                itemBuilder: (context, index) {
                  final medicine = activeMedicines[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.medication,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            medicine.name,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            medicine.dosage,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 70,
                            child: ElevatedButton(
                              onPressed: () {
                                markMedicineAsTaken(medicine);
                              },
                              child: const Text(
                                'أخذت الدواء ✅',
                                style: TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}