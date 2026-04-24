import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../repositories/history_repository.dart';
import '../repositories/medicine_repository.dart';
import '../utils/time_formatter.dart';
import '../services/medicine_tracking_service.dart';

class NowScreen extends StatefulWidget {
  const NowScreen({super.key});

  @override
  State<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends State<NowScreen> {
  final medicineRepository = MedicineRepository();
  final historyRepository = HistoryRepository();
  late final MedicineTrackingService medicineTrackingService;

  List<Medicine> activeMedicines = [];
  bool hasMedicineNow = false;

  @override
  void initState() {
    super.initState();

    medicineTrackingService = MedicineTrackingService(
      medicineRepository: medicineRepository,
      historyRepository: historyRepository,
    );

    loadActiveMedicines();
  }

  Future<void> loadActiveMedicines() async {
    await medicineTrackingService.markExpiredMedicinesAsMissed();

    final now = DateTime.now();
    final medicinesInCurrentRange = medicineRepository.findActiveMedicines(now);

    setState(() {
      hasMedicineNow = medicinesInCurrentRange.isNotEmpty;

      activeMedicines = medicinesInCurrentRange.where((medicine) {
        return !historyRepository.isMedicineHandledToday(medicine.id);
      }).toList();
    });
  } 
  
  Future<void> markMedicineAsTaken(Medicine medicine) async {
  await historyRepository.markMedicineAsTaken(medicine);
  await loadActiveMedicines();
  }

  @override
  Widget build(BuildContext context) {
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