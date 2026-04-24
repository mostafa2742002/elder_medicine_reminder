import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../repositories/history_repository.dart';
import '../repositories/medicine_repository.dart';
import '../services/medicine_tracking_service.dart';
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
  final historyRepository = HistoryRepository();

  late final MedicineTrackingService medicineTrackingService;

  List<Medicine> medicines = [];

  @override
  void initState() {
    super.initState();

    medicineTrackingService = MedicineTrackingService(
      medicineRepository: medicineRepository,
      historyRepository: historyRepository,
    );

    loadMedicines();
  }

  Future<void> loadMedicines() async {
    await medicineTrackingService.markExpiredMedicinesAsMissed();

    if (!mounted) {
      return;
    }

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
      await loadMedicines();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حفظ الدواء بنجاح',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }

  Future<void> confirmDeleteMedicine(Medicine medicine) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف الدواء',
              textAlign: TextAlign.right,
            ),
            content: Text(
              'هل تريد حذف "${medicine.name}"؟',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 20),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                icon: const Icon(Icons.delete),
                label: const Text(
                  'حذف',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete == true) {
      await deleteMedicine(medicine);
    }
  }

  Future<void> deleteMedicine(Medicine medicine) async {
    await medicineRepository.deleteById(medicine.id);
    await loadMedicines();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حذف ${medicine.name}',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة الأدوية',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
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
            ? const _EmptyMedicinesMessage()
            : RefreshIndicator(
                onRefresh: loadMedicines,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = medicines[index];

                    return _MedicineCard(
                      medicine: medicine,
                      onDelete: () {
                        confirmDeleteMedicine(medicine);
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _EmptyMedicinesMessage extends StatelessWidget {
  const _EmptyMedicinesMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medication,
                  size: 100,
                  color: Colors.green,
                ),
                SizedBox(height: 22),
                Text(
                  'لا توجد أدوية حتى الآن',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'اضغط على زر "إضافة دواء" لإضافة أول دواء.',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onDelete;

  const _MedicineCard({
    required this.medicine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = TimeFormatter.formatHour12(medicine.startHour);
    final endTime = TimeFormatter.formatHour12(medicine.endHour);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.medication,
              size: 70,
              color: Colors.green,
            ),

            const SizedBox(height: 12),

            Text(
              medicine.name,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              medicine.dosage,
              style: const TextStyle(
                fontSize: 23,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'من $startTime إلى $endTime',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete),
              label: const Text(
                'حذف الدواء',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}