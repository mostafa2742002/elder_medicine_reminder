import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/medicine.dart';
import '../utils/time_formatter.dart';

class NowScreen extends StatefulWidget {
  const NowScreen({super.key});

  @override
  State<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends State<NowScreen> {
  

  List<Medicine> getActiveMedicines() {
    final currentHour = DateTime.now().hour;

    return AppStore.medicines.where((medicine) {
      final isInsideTimeRange =
          currentHour >= medicine.startHour && currentHour < medicine.endHour;

      final isNotTakenYet = !AppStore.isMedicineTaken(medicine.id);

      return isInsideTimeRange && isNotTakenYet;
    }).toList();
  }

  bool hasAnyMedicineInCurrentTimeRange() {
  final currentHour = DateTime.now().hour;

  return AppStore.medicines.any((medicine) {
    return currentHour >= medicine.startHour && currentHour < medicine.endHour;
  });
  }

  void markMedicineAsTaken(Medicine medicine) {
  setState(() {
    AppStore.markMedicineAsTaken(medicine);
  });
  }

  @override
  Widget build(BuildContext context) {
    final activeMedicines = getActiveMedicines();
    final hasMedicineNow = hasAnyMedicineInCurrentTimeRange();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('أدوية الآن'),
          centerTitle: true,
        ),
        body: activeMedicines.isEmpty
          ? _NoMedicineMessage(
              message: hasMedicineNow
                  ? 'تم أخذ كل أدوية هذه الفترة ✅'
                  : 'لا يوجد دواء في الوقت الحالي',
            )
          : _CurrentMedicineCard(
              medicine: activeMedicines.first,
              remainingCount: activeMedicines.length,
              onTaken: markMedicineAsTaken,
            ),
      ),
    );
  }
}

class _NoMedicineMessage extends StatelessWidget {
  final String message;

  const _NoMedicineMessage({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: const TextStyle(fontSize: 30),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CurrentMedicineCard extends StatelessWidget {
  final Medicine medicine;
  final int remainingCount;
  final void Function(Medicine medicine) onTaken;

  const _CurrentMedicineCard({
    required this.medicine,
    required this.remainingCount,
    required this.onTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'عدد الأدوية المتبقية: $remainingCount',
                  style: const TextStyle(
                    fontSize: 22,
                  ),
                ),

                const SizedBox(height: 16),

                const Icon(
                  Icons.medication,
                  size: 110,
                ),

                const SizedBox(height: 24),

                const Text(
                  'حان وقت الدواء',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  medicine.dosage,
                  style: const TextStyle(fontSize: 26),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'من ${TimeFormatter.formatHour12(medicine.startHour)} إلى ${TimeFormatter.formatHour12(medicine.endHour)}',
                  style: const TextStyle(fontSize: 22),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () {
                      onTaken(medicine);
                    },
                    child: const Text(
                      'أخذت الدواء ✅',
                      style: TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}